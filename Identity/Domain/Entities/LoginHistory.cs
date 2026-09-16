namespace Identity.Domain.Entities;

/// <summary>
/// Audit record of an admin login attempt. Maps 1:1 to dbo.LoginHistories.
/// </summary>
public class LoginHistory
{
    public long Id { get; set; }
    public int? AdminUserId { get; set; }
    public string? AttemptedEmail { get; set; }
    public bool IsSuccess { get; set; }
    public string? FailureReason { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public DateTime AttemptedAt { get; set; }
}
