/* =============================================================================
   00_Init.sql — schema history tracking
   -----------------------------------------------------------------------------
   Applied first by Apply-Database.ps1. Records which script files have already
   run against this database so the runner is safe to re-execute.

   Conventions used by every file in 01-Schema:
     * Table names are plural.  Column names are PascalCase.
     * Surrogate key is always  Id INT IDENTITY(1,1)  PRIMARY KEY.
     * Audit columns on every business table:
           CreatedAt DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
           CreatedBy INT NULL
           UpdatedAt DATETIME2(3) NULL
           UpdatedBy INT NULL
           IsActive  BIT NOT NULL DEFAULT 1
           IsDeleted BIT NOT NULL DEFAULT 0
     * Soft delete only. Nothing is ever removed with DELETE.
     * Money is DECIMAL(18,2). Rates, weights and fractional quantities are
       DECIMAL(18,4). Never FLOAT.
     * Timestamps are UTC DATETIME2(3), converted at the presentation edge.
     * Enum-backed columns are TINYINT/INT holding the numeric value declared in
       ChamundaHandicraft.Helper/Enums/Enum.cs. Never renumber those enums.
   ============================================================================= */

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.SchemaHistory', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SchemaHistory
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        ScriptFolder    VARCHAR(64)     NOT NULL,
        ScriptName      VARCHAR(256)    NOT NULL,
        ChecksumSha256  CHAR(64)        NOT NULL,
        AppliedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_SchemaHistory_AppliedAt DEFAULT (SYSUTCDATETIME()),
        AppliedBy       NVARCHAR(128)   NOT NULL CONSTRAINT DF_SchemaHistory_AppliedBy DEFAULT (SUSER_SNAME()),
        DurationMs      INT             NULL,
        CONSTRAINT PK_SchemaHistory PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_SchemaHistory_Script UNIQUE (ScriptFolder, ScriptName)
    );
END
GO
