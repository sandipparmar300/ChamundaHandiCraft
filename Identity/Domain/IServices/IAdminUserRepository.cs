using Identity.Domain.Entities;

namespace Identity.Domain.IServices;

/// <summary>
/// Repository contract for AdminUser authentication and audit operations.
/// </summary>
public interface IAdminUserRepository
{
    /// <summary>
    /// Looks up user by email or phone, loading their roles and permissions.
    /// </summary>
    Task<(AdminUser? User, List<UserRoleItem> Roles, List<string> Permissions)> GetByIdentifierAsync(string identifier);

    /// <summary>
    /// Records a login attempt into dbo.LoginHistories and updates lockout status.
    /// </summary>
    Task RecordLoginAttemptAsync(
        int? adminUserId,
        string? attemptedEmail,
        bool isSuccess,
        string? failureReason,
        string? ipAddress,
        string? userAgent,
        int maxFailedAttempts = 5,
        int lockoutMinutes = 15);
}
