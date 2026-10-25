using System.ComponentModel.DataAnnotations;

namespace ChamundaHandicraft.Helper.ViewModel.Customer;

/// <summary>
/// Customer registration request model with validations.
/// </summary>
public class CustomerRegisterRequest
{
    [Required(ErrorMessage = "Full name is required.")]
    [StringLength(100, MinimumLength = 2, ErrorMessage = "Full name must be between 2 and 100 characters.")]
    [Display(Name = "Full Name")]
    public string FullName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Email address is required.")]
    [EmailAddress(ErrorMessage = "Please enter a valid email address.")]
    [StringLength(256)]
    [Display(Name = "Email Address")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Mobile number is required.")]
    [RegularExpression(@"^[0-9\s]{10,14}$", ErrorMessage = "Please enter a valid 10-digit mobile number.")]
    [Display(Name = "Mobile Number")]
    public string Mobile { get; set; } = string.Empty;

    [Required(ErrorMessage = "Password is required.")]
    [StringLength(100, MinimumLength = 8, ErrorMessage = "Password must be at least 8 characters long.")]
    [DataType(DataType.Password)]
    [Display(Name = "Password")]
    public string Password { get; set; } = string.Empty;

    public bool MarketingConsent { get; set; }

    public string? GuestToken { get; set; }

    public string? ReturnUrl { get; set; }
}

/// <summary>
/// Customer login request model.
/// </summary>
public class CustomerLoginRequest
{
    [Required(ErrorMessage = "Email or mobile number is required.")]
    [Display(Name = "Email or Mobile")]
    public string Identifier { get; set; } = string.Empty;

    [Required(ErrorMessage = "Password is required.")]
    [DataType(DataType.Password)]
    [Display(Name = "Password")]
    public string Password { get; set; } = string.Empty;

    public bool RememberMe { get; set; }

    public string? ReturnUrl { get; set; }
}

/// <summary>
/// Customer authentication response containing user info and JWT token.
/// </summary>
public class CustomerAuthResponse
{
    public int CustomerId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string RewardTier { get; set; } = "Bronze";
    public int RewardPoints { get; set; }
    public string Token { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
}

/// <summary>
/// Customer forgot password request.
/// </summary>
public class CustomerForgotPasswordRequest
{
    [Required(ErrorMessage = "Email or mobile number is required.")]
    [Display(Name = "Email or Mobile")]
    public string Identifier { get; set; } = string.Empty;
}

/// <summary>
/// Customer forgot password response payload.
/// </summary>
public class CustomerForgotPasswordResponse
{
    public bool ResetInitiated { get; set; }
    public string? RawToken { get; set; }
    public string? Email { get; set; }
    public string? FullName { get; set; }
}

/// <summary>
/// Customer reset password request.
/// </summary>
public class CustomerResetPasswordRequest
{
    [Required(ErrorMessage = "Security token is required.")]
    public string Token { get; set; } = string.Empty;

    [Required(ErrorMessage = "Password is required.")]
    [StringLength(100, MinimumLength = 8, ErrorMessage = "Password must be at least 8 characters.")]
    [DataType(DataType.Password)]
    [Display(Name = "New Password")]
    public string Password { get; set; } = string.Empty;

    [Required(ErrorMessage = "Please confirm your password.")]
    [DataType(DataType.Password)]
    [Compare(nameof(Password), ErrorMessage = "Passwords do not match.")]
    [Display(Name = "Confirm Password")]
    public string ConfirmPassword { get; set; } = string.Empty;

    public bool SignOutOthers { get; set; } = true;
}

/// <summary>
/// Customer OTP send request.
/// </summary>
public class CustomerOtpSendRequest
{
    [Required(ErrorMessage = "Target phone or email is required.")]
    public string Target { get; set; } = string.Empty;

    public string Channel { get; set; } = "sms"; // sms or email
}

/// <summary>
/// Customer OTP verify request.
/// </summary>
public class CustomerOtpVerifyRequest
{
    [Required(ErrorMessage = "Target phone or email is required.")]
    public string Target { get; set; } = string.Empty;

    [Required(ErrorMessage = "6-digit code is required.")]
    [StringLength(6, MinimumLength = 6, ErrorMessage = "Code must be 6 digits.")]
    public string Code { get; set; } = string.Empty;
}

/// <summary>
/// Customer mobile verification request.
/// </summary>
public class CustomerVerifyMobileRequest
{
    [Required(ErrorMessage = "Mobile number is required.")]
    public string Mobile { get; set; } = string.Empty;

    [Required(ErrorMessage = "Verification code is required.")]
    public string Code { get; set; } = string.Empty;
}

