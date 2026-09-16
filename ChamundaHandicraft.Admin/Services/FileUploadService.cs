using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using System.Text.RegularExpressions;

namespace ChamundaHandicraft.Admin.Services;

public interface IFileUploadService
{
    Task<string?> SaveFileAsync(IFormFile? file, string folder, CancellationToken ct = default);
    Task<List<string>> SaveFilesAsync(IEnumerable<IFormFile>? files, string folder, CancellationToken ct = default);
}

public class FileUploadService : IFileUploadService
{
    private readonly IWebHostEnvironment _env;
    private static readonly HashSet<string> AllowedExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".jpg", ".jpeg", ".png", ".webp", ".gif", ".svg", ".bmp"
    };

    public FileUploadService(IWebHostEnvironment env)
    {
        _env = env;
    }

    public async Task<string?> SaveFileAsync(IFormFile? file, string folder, CancellationToken ct = default)
    {
        if (file == null || file.Length == 0) return null;

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!AllowedExtensions.Contains(ext))
        {
            ext = ".jpg";
        }

        folder = folder.Trim().Trim('/').Trim('\\').ToLowerInvariant();
        var rawName = Path.GetFileNameWithoutExtension(file.FileName);
        var cleanName = Regex.Replace(rawName, @"[^a-zA-Z0-9_\-]", "-").Trim('-');
        if (string.IsNullOrWhiteSpace(cleanName))
        {
            cleanName = "file";
        }

        var guidPart = Guid.NewGuid().ToString("N")[..6];
        var uniqueFileName = $"{cleanName}_{DateTime.UtcNow:yyyyMMddHHmmss}_{guidPart}{ext}";

        // 1. Save to Admin wwwroot/uploads/{folder}
        var adminWwwroot = _env.WebRootPath ?? Path.Combine(_env.ContentRootPath, "wwwroot");
        var adminTargetDir = Path.Combine(adminWwwroot, "uploads", folder);
        Directory.CreateDirectory(adminTargetDir);

        var adminFilePath = Path.Combine(adminTargetDir, uniqueFileName);
        await using (var stream = new FileStream(adminFilePath, FileMode.Create))
        {
            await file.CopyToAsync(stream, ct);
        }

        // 2. Mirror copy to Customer and API wwwroot if directories exist in the solution
        try
        {
            var solutionDir = Path.GetFullPath(Path.Combine(_env.ContentRootPath, ".."));

            var customerTargetDir = Path.Combine(solutionDir, "ChamundaHandicraft.Customer", "wwwroot", "uploads", folder);
            if (Directory.Exists(Path.Combine(solutionDir, "ChamundaHandicraft.Customer", "wwwroot")))
            {
                Directory.CreateDirectory(customerTargetDir);
                File.Copy(adminFilePath, Path.Combine(customerTargetDir, uniqueFileName), overwrite: true);
            }

            var apiTargetDir = Path.Combine(solutionDir, "ChamundaHandicraft.API", "wwwroot", "uploads", folder);
            if (Directory.Exists(Path.Combine(solutionDir, "ChamundaHandicraft.API", "wwwroot")))
            {
                Directory.CreateDirectory(apiTargetDir);
                File.Copy(adminFilePath, Path.Combine(apiTargetDir, uniqueFileName), overwrite: true);
            }
        }
        catch
        {
            // Non-critical mirror fallback
        }

        return $"/uploads/{folder}/{uniqueFileName}";
    }

    public async Task<List<string>> SaveFilesAsync(IEnumerable<IFormFile>? files, string folder, CancellationToken ct = default)
    {
        var urls = new List<string>();
        if (files == null) return urls;

        foreach (var file in files)
        {
            var url = await SaveFileAsync(file, folder, ct);
            if (!string.IsNullOrEmpty(url))
            {
                urls.Add(url);
            }
        }

        return urls;
    }
}
