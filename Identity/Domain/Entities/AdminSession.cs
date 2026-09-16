namespace Identity.Domain.Entities;

/// <summary>
/// Active admin refresh token session. Maps 1:1 to dbo.AdminSessions.
/// </summary>
public class AdminSession
{
    public long Id { get; set; }
    public int AdminUserId { get; set; }
    public string RefreshTokenHash { get; set; } = string.Empty;
    public DateTime IssuedAt { get; set; }
    public DateTime ExpiresAt { get; set; }
    public DateTime? RevokedAt { get; set; }
    public string? RevokedReason { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }

    public bool IsActive => RevokedAt == null && ExpiresAt > DateTime.UtcNow;
}
