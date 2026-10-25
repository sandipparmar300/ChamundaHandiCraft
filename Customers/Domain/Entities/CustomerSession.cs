namespace Customers.Domain.Entities;

public class CustomerSession
{
    public long Id { get; set; }
    public int CustomerId { get; set; }
    public string RefreshTokenHash { get; set; } = string.Empty;
    public DateTime IssuedAt { get; set; }
    public DateTime ExpiresAt { get; set; }
    public DateTime? RevokedAt { get; set; }
    public string? DeviceLabel { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
}
