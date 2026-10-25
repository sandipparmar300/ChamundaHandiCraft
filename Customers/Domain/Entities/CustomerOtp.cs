namespace Customers.Domain.Entities;

public class CustomerOtp
{
    public long Id { get; set; }
    public string Destination { get; set; } = string.Empty;
    public byte Channel { get; set; }
    public string Purpose { get; set; } = string.Empty;
    public string CodeHash { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public int AttemptCount { get; set; }
    public DateTime? ConsumedAt { get; set; }
    public DateTime CreatedAt { get; set; }
}
