using System.Net;
using System.Net.Mail;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace ChamundaHandicraft.API.Services.Email;

/// <summary>
/// SMTP implementation of IEmailService.
/// Completely decoupled from HTML templates: delegates all rendering and token replacement
/// to IEmailTemplateService.
/// </summary>
public class SmtpEmailService : IEmailService
{
    private readonly IConfiguration _configuration;
    private readonly IEmailTemplateService _templateService;
    private readonly ILogger<SmtpEmailService> _logger;

    public SmtpEmailService(
        IConfiguration configuration,
        IEmailTemplateService templateService,
        ILogger<SmtpEmailService> logger)
    {
        _configuration = configuration;
        _templateService = templateService;
        _logger = logger;
    }

    /// <summary>
    /// Specialized helper to dispatch password reset emails using the "AdminPasswordReset" template.
    /// </summary>
    public async Task<bool> SendPasswordResetEmailAsync(string recipientEmail, string recipientName, string resetToken)
    {
        var adminBaseUrl = _configuration["AdminPortalBaseUrl"] ?? "https://localhost:7140";
        var resetUrl = $"{adminBaseUrl.TrimEnd('/')}/Auth/ResetPassword?token={Uri.EscapeDataString(resetToken)}";

        var tokens = new Dictionary<string, string>
        {
            ["RecipientName"] = recipientName,
            ["RecipientEmail"] = recipientEmail,
            ["ResetUrl"] = resetUrl,
            ["ExpirationMinutes"] = "60"
        };

        _logger.LogInformation(
            "[AUTH LINK DISPATCH] Password Reset Link generated for {Email} ({Name}): {Url}",
            recipientEmail, recipientName, resetUrl);

        return await SendEmailWithTemplateAsync(recipientEmail, recipientName, "AdminPasswordReset", tokens);
    }

    /// <summary>
    /// Renders the specified external HTML template and sends the resulting email via SMTP.
    /// </summary>
    public async Task<bool> SendEmailWithTemplateAsync(
        string recipientEmail,
        string recipientName,
        string templateName,
        IDictionary<string, string>? tokens = null)
    {
        var smtpHost = _configuration["Email:SmtpHost"];
        var smtpPort = int.TryParse(_configuration["Email:SmtpPort"], out int port) ? port : 587;
        var userName = _configuration["Email:UserName"];
        var password = _configuration["Email:Password"];
        var fromAddress = _configuration["Email:FromAddress"] ?? "no-reply@chamundahandicraft.com";
        var fromName = _configuration["Email:FromName"] ?? "Chamunda Handicraft";
        var enableSsl = bool.TryParse(_configuration["Email:EnableSsl"], out bool ssl) ? ssl : true;

        // Render template from external HTML file / DB repository
        string subject;
        string bodyHtml;
        try
        {
            (subject, bodyHtml) = await _templateService.RenderTemplateAsync(templateName, tokens);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to render email template '{TemplateName}' for {Email}", templateName, recipientEmail);
            return false;
        }

        // Development fallback if SMTP server is unconfigured
        if (string.IsNullOrWhiteSpace(smtpHost) || string.IsNullOrWhiteSpace(userName))
        {
            _logger.LogWarning(
                "[DEV MODE] SMTP not configured. Email to {Email} with template '{TemplateName}' skipped live send.",
                recipientEmail, templateName);
            return true;
        }

        try
        {
            using var message = new MailMessage
            {
                From = new MailAddress(fromAddress, fromName),
                Subject = subject,
                Body = bodyHtml,
                IsBodyHtml = true
            };
            message.To.Add(new MailAddress(recipientEmail, recipientName));

            using var client = new SmtpClient(smtpHost, smtpPort)
            {
                EnableSsl = enableSsl,
                UseDefaultCredentials = false,
                Credentials = new NetworkCredential(userName, password),
                DeliveryMethod = SmtpDeliveryMethod.Network,
                Timeout = 20000
            };

            await client.SendMailAsync(message);
            _logger.LogInformation("Email with template '{TemplateName}' successfully sent via SMTP to {Email}", templateName, recipientEmail);
            return true;
        }
        catch (SmtpException smtpEx)
        {
            _logger.LogError(smtpEx, "SMTP error sending email '{TemplateName}' to {Email}.", templateName, recipientEmail);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send email '{TemplateName}' to {Email}.", templateName, recipientEmail);
            return true;
        }
    }
}
