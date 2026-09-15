<#
.SYNOPSIS
    Applies the Chamunda Handicraft database scripts in dependency order.

.DESCRIPTION
    Walks 01-Schema, 02-StoredProcedures, 05-Views, 03-Seed and 04-Patches in that
    order, running every .sql file it finds through sqlcmd.

    Safe to re-run. Two independent mechanisms guarantee that:

      1. Every script is itself idempotent - tables are guarded by
         IF OBJECT_ID(...) IS NULL, procedures use CREATE OR ALTER, and seed data
         uses MERGE / NOT EXISTS.
      2. dbo.SchemaHistory records the SHA-256 of each applied file. A file whose
         checksum is unchanged is skipped; a file that has CHANGED since it was
         applied is reported, and re-run only for the folders where that is safe
         (procedures, views, seed) - never for 01-Schema, which is append-only
         once it has reached a shared environment.

    Nothing is ever dropped. This script cannot delete data.

    NOTE: this file is deliberately ASCII-only. Windows PowerShell 5.1 reads
    BOM-less files as ANSI, which corrupts non-ASCII punctuation and breaks
    parsing.

.PARAMETER ServerInstance
    SQL Server instance. Defaults to the instance in the API's appsettings.json.

.PARAMETER Database
    Target database name. Created if it does not exist.

.PARAMETER Force
    Re-run scripts whose checksum has changed, including 01-Schema. Use only
    against a scratch or development database.

.EXAMPLE
    .\Apply-Database.ps1
    .\Apply-Database.ps1 -ServerInstance "localhost\MSSQLSERVER02" -Database ChamundaHandicraft_Validate -Force
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string] $ServerInstance = 'localhost\MSSQLSERVER01',
    [string] $Database       = 'ChamundaHandicraft',
    [switch] $Force
)

$ErrorActionPreference = 'Stop'
$scriptRoot = $PSScriptRoot

# Dependency order. 01-Schema must precede everything; seed needs the procedures
# and the tables; patches are forward-only fixes applied last.
$folders = @(
    '01-Schema',
    '02-StoredProcedures',
    '05-Views',
    '03-Seed',
    '04-Patches'
)

function Invoke-Sql {
    param(
        [Parameter(Mandatory)] [string] $Query,
        [string] $TargetDb = 'master'
    )
    $out = & sqlcmd -S $ServerInstance -E -C -d $TargetDb -b -h -1 -W -Q $Query
    if ($LASTEXITCODE -ne 0) {
        throw "sqlcmd failed against [$TargetDb]: $($out -join [Environment]::NewLine)"
    }
    return $out
}

function Get-FileChecksum {
    param([Parameter(Mandatory)] [string] $Path)
    return (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

Write-Host ''
Write-Host 'Chamunda Handicraft - database deployment' -ForegroundColor Cyan
Write-Host "  Server   : $ServerInstance"
Write-Host "  Database : $Database"
Write-Host ''

# ---------------------------------------------------------------------------
# 1. Ensure the database exists. Never dropped, never recreated.
# ---------------------------------------------------------------------------
$exists = Invoke-Sql -Query "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.databases WHERE name = N'$Database';"
if (($exists | Select-Object -First 1).Trim() -eq '0') {
    if ($PSCmdlet.ShouldProcess($Database, 'CREATE DATABASE')) {
        Write-Host "  Creating database [$Database] ..." -ForegroundColor Yellow
        Invoke-Sql -Query "CREATE DATABASE [$Database];" | Out-Null
        Write-Host '  Created.' -ForegroundColor Green
    }
}
else {
    Write-Host '  Database exists - applying incrementally.' -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# 2. Bootstrap dbo.SchemaHistory before anything consults it.
# ---------------------------------------------------------------------------
$initPath = Join-Path $scriptRoot '01-Schema\00_Init.sql'
if (Test-Path $initPath) {
    & sqlcmd -S $ServerInstance -E -C -d $Database -b -i $initPath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Failed to apply 00_Init.sql' }
}

# ---------------------------------------------------------------------------
# 3. Load what has already been applied.
# ---------------------------------------------------------------------------
$historyQuery = "SET NOCOUNT ON; SELECT ScriptFolder + '|' + ScriptName + '|' + ChecksumSha256 FROM dbo.SchemaHistory;"
$appliedRows = Invoke-Sql -TargetDb $Database -Query $historyQuery
$applied = @{}
foreach ($row in $appliedRows) {
    if ([string]::IsNullOrWhiteSpace($row)) { continue }
    $parts = $row.Trim() -split '\|'
    if ($parts.Count -eq 3) { $applied["$($parts[0])/$($parts[1])"] = $parts[2] }
}

# ---------------------------------------------------------------------------
# 4. Apply each folder in order.
# ---------------------------------------------------------------------------
$totalRun = 0
$totalSkipped = 0
$changed = @()

foreach ($folder in $folders) {
    $folderPath = Join-Path $scriptRoot $folder
    if (-not (Test-Path $folderPath)) { continue }

    # Recurse: 02-StoredProcedures is one sub-folder per module.
    $files = Get-ChildItem -Path $folderPath -Filter '*.sql' -File -Recurse |
             Sort-Object { $_.FullName.Substring($folderPath.Length) }

    if ($files.Count -eq 0) { continue }
    Write-Host ''
    Write-Host "  $folder" -ForegroundColor Cyan

    foreach ($file in $files) {
        $relative = $file.FullName.Substring($folderPath.Length).TrimStart('\', '/')
        $key      = "$folder/$relative"
        $checksum = Get-FileChecksum -Path $file.FullName

        if ($applied.ContainsKey($key)) {
            if ($applied[$key] -eq $checksum) {
                $totalSkipped++
                Write-Host ("    . {0,-52} already applied" -f $relative) -ForegroundColor DarkGray
                continue
            }

            # Changed since it was applied.
            $rerunnable = $folder -in @('02-StoredProcedures', '05-Views', '03-Seed')
            if (-not ($rerunnable -or $Force)) {
                $changed += $key
                Write-Host ("    ! {0,-52} CHANGED - skipped" -f $relative) -ForegroundColor Red
                Write-Host '      01-Schema is append-only once applied. Add a dated file to 04-Patches instead.' -ForegroundColor Red
                continue
            }
        }

        if (-not $PSCmdlet.ShouldProcess($relative, 'apply')) { continue }

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        & sqlcmd -S $ServerInstance -E -C -d $Database -b -i $file.FullName | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "FAILED: $key" }
        $sw.Stop()

        $safeFolder = $folder.Replace("'", "''")
        $safeName   = $relative.Replace("'", "''")
        $ms         = $sw.ElapsedMilliseconds

        $merge = "SET NOCOUNT ON; " +
                 "MERGE dbo.SchemaHistory AS t " +
                 "USING (SELECT '$safeFolder' AS ScriptFolder, '$safeName' AS ScriptName) AS s " +
                 "ON t.ScriptFolder = s.ScriptFolder AND t.ScriptName = s.ScriptName " +
                 "WHEN MATCHED THEN UPDATE SET ChecksumSha256 = '$checksum', AppliedAt = SYSUTCDATETIME(), DurationMs = $ms " +
                 "WHEN NOT MATCHED THEN INSERT (ScriptFolder, ScriptName, ChecksumSha256, DurationMs) " +
                 "VALUES ('$safeFolder', '$safeName', '$checksum', $ms);"
        Invoke-Sql -TargetDb $Database -Query $merge | Out-Null

        $totalRun++
        Write-Host ("    + {0,-52} {1,6} ms" -f $relative, $ms) -ForegroundColor Green
    }
}

# ---------------------------------------------------------------------------
# 5. Summary.
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host "  Applied: $totalRun    Skipped: $totalSkipped" -ForegroundColor Cyan

if ($changed.Count -gt 0) {
    Write-Host ''
    Write-Host '  WARNING - these applied scripts have been edited:' -ForegroundColor Red
    $changed | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
    Write-Host '  Add a dated script to 04-Patches rather than editing 01-Schema.' -ForegroundColor Red
}

$countQuery = "SET NOCOUNT ON; SELECT " +
    "CAST((SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped = 0) AS VARCHAR(10)) + '|' + " +
    "CAST((SELECT COUNT(*) FROM sys.views WHERE is_ms_shipped = 0) AS VARCHAR(10)) + '|' + " +
    "CAST((SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped = 0) AS VARCHAR(10)) + '|' + " +
    "CAST((SELECT COUNT(*) FROM sys.objects WHERE type IN ('FN','IF','TF') AND is_ms_shipped = 0) AS VARCHAR(10)) + '|' + " +
    "CAST((SELECT COUNT(*) FROM sys.indexes i JOIN sys.tables t ON t.object_id = i.object_id WHERE t.is_ms_shipped = 0 AND i.index_id > 0) AS VARCHAR(10)) + '|' + " +
    "CAST((SELECT COUNT(*) FROM sys.foreign_keys) AS VARCHAR(10)) + '|' + " +
    "CAST((SELECT COUNT(*) FROM sys.check_constraints) AS VARCHAR(10)) + '|' + " +
    "CAST((SELECT COUNT(*) FROM sys.key_constraints WHERE type = 'UQ') AS VARCHAR(10));"

$counts = Invoke-Sql -TargetDb $Database -Query $countQuery
$c = ($counts | Where-Object { $_ -match '\|' } | Select-Object -First 1).Trim() -split '\|'
if ($c.Count -eq 8) {
    Write-Host ''
    Write-Host "  Tables .............. $($c[0])"
    Write-Host "  Views ............... $($c[1])"
    Write-Host "  Stored procedures ... $($c[2])"
    Write-Host "  Functions ........... $($c[3])"
    Write-Host "  Indexes ............. $($c[4])"
    Write-Host "  Foreign keys ........ $($c[5])"
    Write-Host "  Check constraints ... $($c[6])"
    Write-Host "  Unique constraints .. $($c[7])"
}

Write-Host ''
Write-Host '  Done.' -ForegroundColor Green
Write-Host ''
