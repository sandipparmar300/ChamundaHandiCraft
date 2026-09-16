using Identity.Domain.Entities;

namespace Identity.Domain.IServices;

/// <summary>
/// Repository contract for password reset tokens and execution.
/// </summary>
public interface IPasswordResetRepository
{
    Task<long> CreateResetTokenAsync(
        int adminUserId,
        string token,
        DateTime expiresAt,
        string? ipAddress,
        string? userAgent);

    Task<ValidatedPasswordReset?> ValidateResetTokenAsync(string token);

    Task<(bool Success, string Message)> ResetPasswordAsync(
        string token,
        string newPasswordHash,
        string? ipAddress);
}
