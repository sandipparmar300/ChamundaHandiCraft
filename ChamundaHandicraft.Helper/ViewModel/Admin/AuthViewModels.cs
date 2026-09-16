using System.ComponentModel.DataAnnotations;

namespace ChamundaHandicraft.Helper.ViewModel.Admin;

/// <summary>
/// Payload submitted when signing into the Admin portal.
/// Accepts either an email address or mobile phone number.
/// </summary>
public class AdminLoginRequest
{
    [Required(ErrorMessage = "Please enter your email or phone number")]
    [Display(Name = "Email or Phone")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Please enter your password")]
    [DataType(DataType.Password)]
    public string Password { get; set; } = string.Empty;

    public bool RememberMe { get; set; }
}

/// <summary>
/// Returned upon successful admin authentication.
/// Contains JWT access token, refresh token, user identity and permissions.
/// </summary>
public class AdminLoginResponse
{
    public int UserId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string RoleName { get; set; } = string.Empty;
    public string? PhotoUrl { get; set; }
    public string AccessToken { get; set; } = string.Empty;
    public string RefreshToken { get; set; } = string.Empty;
    public DateTime AccessTokenExpiresAt { get; set; }
    public bool MustChangePassword { get; set; }
    public List<string> Permissions { get; set; } = new();
}

/// <summary>
/// Password reset request by email.
/// </summary>
public class ForgotPasswordRequest
{
    [Required(ErrorMessage = "Please enter your email address")]
    [EmailAddress(ErrorMessage = "Please enter a valid email address")]
    public string Email { get; set; } = string.Empty;
}

/// <summary>
/// Password reset execution payload with token and new password.
/// </summary>
public class ResetPasswordRequest
{
    [Required]
    public string Token { get; set; } = string.Empty;

    [Required(ErrorMessage = "New password is required")]
    [MinLength(8, ErrorMessage = "Password must be at least 8 characters")]
    [DataType(DataType.Password)]
    public string NewPassword { get; set; } = string.Empty;

    [Required(ErrorMessage = "Please confirm your new password")]
    [Compare(nameof(NewPassword), ErrorMessage = "Passwords do not match")]
    [DataType(DataType.Password)]
    public string ConfirmPassword { get; set; } = string.Empty;
}

/// <summary>
/// Refresh token submission payload.
/// </summary>
public class AdminRefreshTokenRequest
{
    [Required]
    public string RefreshToken { get; set; } = string.Empty;
}
