namespace Customers.Domain.Entities;

public class Customer
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? PasswordHash { get; set; }
    public bool EmailVerified { get; set; }
    public bool MobileVerified { get; set; }
    public string? Gender { get; set; }
    public DateTime? DateOfBirth { get; set; }
    public string? AvatarUrl { get; set; }
    public string? Gstin { get; set; }
    public byte Status { get; set; } = 1;
    public string? BlockedReason { get; set; }
    public int OrderCount { get; set; }
    public decimal LifetimeValue { get; set; }
    public DateTime? LastOrderOn { get; set; }
    public int RewardPointBalance { get; set; }
    public string RewardTier { get; set; } = "Bronze";
    public string? GuestToken { get; set; }
    public DateTime RegisteredOn { get; set; }
    public DateTime? LastLoginOn { get; set; }
    public DateTime CreatedAt { get; set; }
    public int? CreatedBy { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }
    public bool IsActive { get; set; } = true;
    public bool IsDeleted { get; set; }
}
