namespace ChamundaHandicraft.API.Services.Email;

/// <summary>
/// Email dispatch contract for platform notifications and transactional messages.
/// All emails are rendered from external HTML templates with token substitutions.
/// </summary>
public interface IEmailService
{
    /// <summary>
    /// Sends an email rendered from an external HTML template with token substitutions.
    /// </summary>
    /// <param name="recipientEmail">Destination email address.</param>
    /// <param name="recipientName">Recipient display name.</param>
    /// <param name="templateName">External template name (e.g. "AdminPasswordReset").</param>
    /// <param name="tokens">Key-value dictionary of tokens to substitute.</param>
    Task<bool> SendEmailWithTemplateAsync(
        string recipientEmail,
        string recipientName,
        string templateName,
        IDictionary<string, string>? tokens = null);

    /// <summary>
    /// Specialized helper to send password reset emails using the "AdminPasswordReset" template.
    /// </summary>
    Task<bool> SendPasswordResetEmailAsync(string recipientEmail, string recipientName, string resetToken);
}
