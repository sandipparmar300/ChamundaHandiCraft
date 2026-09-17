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

    Task<ChamundaHandicraft.Helper.ViewModel.Common.PagedResult<ChamundaHandicraft.Helper.ViewModel.Admin.AdminUserGridItem>> GetGridAsync(
        ChamundaHandicraft.Helper.ViewModel.Common.DataTableRequest request, CancellationToken ct = default);

    Task<ChamundaHandicraft.Helper.ViewModel.Admin.AdminUserSaveRequest?> GetByIdAsync(int id, CancellationToken ct = default);

    Task<int> SaveAsync(ChamundaHandicraft.Helper.ViewModel.Admin.AdminUserSaveRequest request, int? adminUserId = null, CancellationToken ct = default);

    Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);

    Task<bool> UpdateStatusAsync(int id, bool isActive, int? adminUserId = null, CancellationToken ct = default);

    Task<bool> ChangePasswordAsync(int id, string passwordHash, int? adminUserId = null, CancellationToken ct = default);
}
