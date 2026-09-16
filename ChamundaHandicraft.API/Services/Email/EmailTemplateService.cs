using System.Data;
using System.Text.RegularExpressions;
using Dapper;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace ChamundaHandicraft.API.Services.Email;

/// <summary>
/// Implementation of IEmailTemplateService.
/// Resolves templates from dbo.NotificationTemplates or physical HTML files on disk,
/// replacing {{Token}} placeholders with dynamic data.
/// </summary>
public class EmailTemplateService : IEmailTemplateService
{
    private readonly IConfiguration _configuration;
    private readonly IWebHostEnvironment _environment;
    private readonly ILogger<EmailTemplateService> _logger;
    private readonly string _connectionString;

    public EmailTemplateService(
        IConfiguration configuration,
        IWebHostEnvironment environment,
        ILogger<EmailTemplateService> logger)
    {
        _configuration = configuration;
        _environment = environment;
        _logger = logger;
        _connectionString = _configuration.GetConnectionString("AppDbConnection")
            ?? _configuration.GetConnectionString("DefaultConnection")
            ?? string.Empty;
    }

    public async Task<(string Subject, string BodyHtml)> RenderTemplateAsync(
        string templateName,
        IDictionary<string, string>? tokens = null)
    {
        string rawSubject = string.Empty;
        string rawBodyHtml = string.Empty;

        // 1. Attempt to resolve from dbo.NotificationTemplates table first (DB-driven)
        if (!string.IsNullOrWhiteSpace(_connectionString))
        {
            try
            {
                using var conn = new SqlConnection(_connectionString);
                var dbTemplate = await conn.QueryFirstOrDefaultAsync<(string? Subject, string? BodyHtml)>(
                    @"SELECT Subject, BodyHtml 
                      FROM dbo.NotificationTemplates 
                      WHERE TemplateCode = @TemplateCode 
                        AND Channel = 0 
                        AND IsActive = 1 
                        AND IsDeleted = 0",
                    new { TemplateCode = templateName });

                if (!string.IsNullOrWhiteSpace(dbTemplate.BodyHtml))
                {
                    rawSubject = dbTemplate.Subject ?? string.Empty;
                    rawBodyHtml = dbTemplate.BodyHtml;
                    _logger.LogDebug("Loaded email template '{TemplateName}' from database.", templateName);
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to query dbo.NotificationTemplates for '{TemplateName}', falling back to physical disk.", templateName);
            }
        }

        // 2. Fall back to physical HTML template file on disk
        if (string.IsNullOrWhiteSpace(rawBodyHtml))
        {
            var templatePath = Path.Combine(_environment.ContentRootPath, "EmailTemplates", $"{templateName}.html");

            if (File.Exists(templatePath))
            {
                rawBodyHtml = await File.ReadAllTextAsync(templatePath);
                _logger.LogDebug("Loaded email template '{TemplateName}' from physical file: {Path}", templateName, templatePath);

                // Extract Subject from <meta name="subject" content="..." /> or <title>...</title>
                var metaSubjectMatch = Regex.Match(rawBodyHtml, @"<meta\s+name=[""']subject[""']\s+content=[""'](.*?)[""']", RegexOptions.IgnoreCase);
                if (metaSubjectMatch.Success)
                {
                    rawSubject = metaSubjectMatch.Groups[1].Value;
                }
                else
                {
                    var titleMatch = Regex.Match(rawBodyHtml, @"<title>(.*?)</title>", RegexOptions.IgnoreCase);
                    if (titleMatch.Success)
                    {
                        rawSubject = titleMatch.Groups[1].Value;
                    }
                }
            }
            else
            {
                _logger.LogError("Email template file not found: {Path}", templatePath);
                throw new FileNotFoundException($"Email template '{templateName}.html' not found on disk at {templatePath}.");
            }
        }

        // 3. Prepare global tokens and merge with caller tokens
        var allTokens = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            ["CurrentYear"] = DateTime.UtcNow.Year.ToString(),
            ["CompanyName"] = _configuration["Email:FromName"] ?? "Chamunda Handicraft",
            ["SupportEmail"] = _configuration["Email:FromAddress"] ?? "sandipparmar300@gmail.com",
            ["AdminPortalUrl"] = _configuration["AdminPortalBaseUrl"] ?? "https://localhost:7140",
            ["StorefrontUrl"] = _configuration["StorefrontBaseUrl"] ?? "https://localhost:7137"
        };

        if (tokens != null)
        {
            foreach (var kvp in tokens)
            {
                allTokens[kvp.Key] = kvp.Value;
            }
        }

        // 4. Token Substitution on both Subject and BodyHtml
        var finalSubject = ReplaceTokens(rawSubject, allTokens);
        var finalBodyHtml = ReplaceTokens(rawBodyHtml, allTokens);

        return (finalSubject, finalBodyHtml);
    }

    private static string ReplaceTokens(string content, IDictionary<string, string> tokens)
    {
        if (string.IsNullOrEmpty(content))
            return string.Empty;

        foreach (var (key, value) in tokens)
        {
            var pattern = @"\{\{\s*" + Regex.Escape(key) + @"\s*\}\}";
            content = Regex.Replace(content, pattern, value ?? string.Empty, RegexOptions.IgnoreCase);
        }

        return content;
    }
}
