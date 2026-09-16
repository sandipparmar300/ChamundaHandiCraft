namespace Identity.Domain.Entities;

/// <summary>
/// Password reset token request. Maps 1:1 to dbo.AdminPasswordResets.
/// </summary>
public class AdminPasswordReset
{
    public long Id { get; set; }
    public int AdminUserId { get; set; }
    public string Token { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public bool IsUsed { get; set; }
    public DateTime? UsedAt { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class ValidatedPasswordReset
{
    public long ResetId { get; set; }
    public int AdminUserId { get; set; }
    public DateTime ExpiresAt { get; set; }
    public bool IsUsed { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public bool IsDeleted { get; set; }
}
