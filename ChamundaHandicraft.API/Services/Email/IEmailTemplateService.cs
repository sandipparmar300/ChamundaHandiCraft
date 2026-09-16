namespace ChamundaHandicraft.API.Services.Email;

/// <summary>
/// Service contract for loading, parsing, and rendering external email templates with token substitution.
/// Eliminates hardcoded HTML strings from C# codebase.
/// </summary>
public interface IEmailTemplateService
{
    /// <summary>
    /// Renders an external HTML email template with dynamic token substitutions.
    /// Checks database template repository first, falling back to physical HTML template files on disk.
    /// </summary>
    /// <param name="templateName">The logical template identifier (e.g. "AdminPasswordReset").</param>
    /// <param name="tokens">Key-value pairs of dynamic tokens to substitute in the template.</param>
    /// <returns>A tuple containing the resolved Subject and the rendered BodyHtml.</returns>
    Task<(string Subject, string BodyHtml)> RenderTemplateAsync(string templateName, IDictionary<string, string>? tokens = null);
}
