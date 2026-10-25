using System.ComponentModel.DataAnnotations;

namespace ChamundaHandicraft.Helper.ViewModel.Customer;

/// <summary>
/// Customer profile details.
/// </summary>
public class CustomerProfileViewModel
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public bool EmailVerified { get; set; }
    public bool MobileVerified { get; set; }
    public string? Gender { get; set; }
    public DateTime? DateOfBirth { get; set; }
    public string? AvatarUrl { get; set; }
    public string? Gstin { get; set; }
    public string? RegisteredBusinessName { get; set; }
    public int OrderCount { get; set; }
    public decimal LifetimeValue { get; set; }
    public int RewardPointBalance { get; set; }
    public string RewardTier { get; set; } = "Bronze";
    public DateTime RegisteredOn { get; set; }

    public string Initials => string.IsNullOrWhiteSpace(FullName)
        ? "C"
        : string.Join("", FullName.Split(' ', StringSplitOptions.RemoveEmptyEntries).Take(2).Select(s => s[0])).ToUpper();
}

/// <summary>
/// Request to update customer personal profile information.
/// </summary>
public class CustomerProfileUpdateRequest
{
    [Required(ErrorMessage = "First name is required.")]
    [StringLength(50, MinimumLength = 1, ErrorMessage = "First name must be between 1 and 50 characters.")]
    [Display(Name = "First Name")]
    public string FirstName { get; set; } = string.Empty;

    [StringLength(50)]
    [Display(Name = "Last Name")]
    public string? LastName { get; set; }

    [RegularExpression(@"^[0-9\s]{10,14}$", ErrorMessage = "Please enter a valid 10-digit mobile number.")]
    [Display(Name = "Mobile Number")]
    public string? Phone { get; set; }

    public string? Gender { get; set; }

    [DataType(DataType.Date)]
    [Display(Name = "Date of Birth")]
    public DateTime? DateOfBirth { get; set; }

    [StringLength(15, ErrorMessage = "GSTIN must be 15 characters.")]
    [Display(Name = "GSTIN")]
    public string? Gstin { get; set; }

    [StringLength(150)]
    [Display(Name = "Registered Business Name")]
    public string? RegisteredBusinessName { get; set; }

    public string FullName => string.IsNullOrWhiteSpace(LastName)
        ? FirstName.Trim()
        : $"{FirstName.Trim()} {LastName.Trim()}";
}

/// <summary>
/// Request for customer password change.
/// </summary>
public class CustomerChangePasswordRequest
{
    [Required(ErrorMessage = "Current password is required.")]
    [DataType(DataType.Password)]
    [Display(Name = "Current Password")]
    public string CurrentPassword { get; set; } = string.Empty;

    [Required(ErrorMessage = "New password is required.")]
    [StringLength(100, MinimumLength = 8, ErrorMessage = "Password must be at least 8 characters.")]
    [DataType(DataType.Password)]
    [Display(Name = "New Password")]
    public string NewPassword { get; set; } = string.Empty;

    [Required(ErrorMessage = "Please confirm your new password.")]
    [DataType(DataType.Password)]
    [Compare(nameof(NewPassword), ErrorMessage = "Passwords do not match.")]
    [Display(Name = "Confirm New Password")]
    public string ConfirmPassword { get; set; } = string.Empty;

    public bool SignOutOthers { get; set; } = true;
}

/// <summary>
/// Overview data for customer dashboard screen.
/// </summary>
public class CustomerDashboardViewModel
{
    public CustomerProfileViewModel Profile { get; set; } = new();
    public int OrderCount { get; set; }
    public int InTransitCount { get; set; }
    public int SavedPiecesCount { get; set; }
    public int CouponsAvailableCount { get; set; }
    public OrderSummaryCardViewModel? ActiveOrder { get; set; }
    public RewardBalanceViewModel Rewards { get; set; } = new();
}
