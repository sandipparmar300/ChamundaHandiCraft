namespace Identity.Domain.Entities;

/// <summary>
/// Admin operator account. Maps 1:1 to dbo.AdminUsers.
/// </summary>
public class AdminUser
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string PasswordHash { get; set; } = string.Empty;
    public DateTime? PasswordChangedAt { get; set; }
    public bool MustChangePassword { get; set; }
    public int? PhotoMediaId { get; set; }
    public string? PhotoUrl { get; set; }
    public string Timezone { get; set; } = "Asia/Kolkata";
    public bool TwoFactorEnabled { get; set; }
    public string? TwoFactorSecret { get; set; }
    public int FailedLoginCount { get; set; }
    public DateTime? LockedOutUntil { get; set; }
    public DateTime? LastLoginOn { get; set; }
    public string? LastLoginIp { get; set; }
    public DateTime CreatedAt { get; set; }
    public int? CreatedBy { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }
    public bool IsActive { get; set; } = true;
    public bool IsDeleted { get; set; }
}
