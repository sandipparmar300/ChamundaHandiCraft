using System.Security.Claims;
using ChamundaHandicraft.Helper.ApiService;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// Handles Admin Portal authentication (Login, Forgot Password, Reset Password, Logout).
/// Strictly calls ChamundaHandicraft.API through APIGateway via IApiService.
/// </summary>
public class AuthController : Controller
{
    private readonly IApiService _apiService;
    private readonly ILogger<AuthController> _logger;

    public AuthController(IApiService apiService, ILogger<AuthController> logger)
    {
        _apiService = apiService;
        _logger = logger;
    }

    /// <summary>
    /// Displays the Admin login view.
    /// </summary>
    [HttpGet]
    [AllowAnonymous]
    public IActionResult Login(string? returnUrl = null)
    {
        if (User.Identity?.IsAuthenticated == true)
        {
            return RedirectToAction("Index", "Dashboard");
        }

        ViewData["ReturnUrl"] = returnUrl;
        return View(new AdminLoginRequest());
    }

    /// <summary>
    /// Authenticates credentials with ChamundaHandicraft.API via the gateway.
    /// </summary>
    [HttpPost]
    [AllowAnonymous]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Login(AdminLoginRequest model, string? returnUrl = null)
    {
        ViewData["ReturnUrl"] = returnUrl;

        if (!ModelState.IsValid)
        {
            return View(model);
        }

        try
        {
            var response = await _apiService.PostAsync<AdminLoginResponse>(ApiEndPoint.Auth.AdminLogin, model);

            if (!response.IsSuccess || response.Data is null)
            {
                ModelState.AddModelError(string.Empty, !string.IsNullOrWhiteSpace(response.Message)
                    ? response.Message
                    : MessageConstant.InvalidCredentials);
                return View(model);
            }

            var authData = response.Data;

            // 1. Set values in Session for ApiService and UI to consume
            HttpContext.Session.SetString(SessionKeys.AdminToken, authData.AccessToken);
            HttpContext.Session.SetString(SessionKeys.AdminRefreshToken, authData.RefreshToken);
            HttpContext.Session.SetString(SessionKeys.AdminUserId, authData.UserId.ToString());
            HttpContext.Session.SetString(SessionKeys.AdminUserName, authData.FullName);
            HttpContext.Session.SetString(SessionKeys.AdminRole, authData.RoleName);
            HttpContext.Session.SetString(SessionKeys.AdminPermissions, string.Join(",", authData.Permissions));

            // 2. Build ClaimsPrincipal for Cookie Authentication
            var claims = new List<Claim>
            {
                new(ClaimTypes.NameIdentifier, authData.UserId.ToString()),
                new(ClaimTypes.Name, authData.FullName),
                new(ClaimTypes.Email, authData.Email),
                new(ClaimTypes.Role, authData.RoleName),
                new("FullName", authData.FullName),
                new("RoleName", authData.RoleName)
            };

            foreach (var perm in authData.Permissions)
            {
                claims.Add(new Claim("permission", perm));
            }

            var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
            var principal = new ClaimsPrincipal(identity);

            var authProperties = new AuthenticationProperties
            {
                IsPersistent = model.RememberMe,
                ExpiresUtc = model.RememberMe
                    ? DateTimeOffset.UtcNow.AddDays(14)
                    : DateTimeOffset.UtcNow.AddMinutes(30)
            };

            await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, principal, authProperties);

            _logger.LogInformation("Admin user {Email} logged in successfully.", authData.Email);

            if (!string.IsNullOrWhiteSpace(returnUrl) && Url.IsLocalUrl(returnUrl))
            {
                return Redirect(returnUrl);
            }

            return RedirectToAction("Index", "Dashboard");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Login failed unexpectedly for user {Email}", model.Email);
            ModelState.AddModelError(string.Empty, MessageConstant.ServiceUnavailable);
            return View(model);
        }
    }

    /// <summary>
    /// Displays the forgot password view.
    /// </summary>
    [HttpGet]
    [AllowAnonymous]
    public IActionResult ForgotPassword()
    {
        return View(new ForgotPasswordRequest());
    }

    /// <summary>
    /// Submits email to initiate password reset link dispatch.
    /// </summary>
    [HttpPost]
    [AllowAnonymous]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ForgotPassword(ForgotPasswordRequest model)
    {
        if (!ModelState.IsValid)
        {
            return View(model);
        }

        try
        {
            var response = await _apiService.PostAsync<bool>(ApiEndPoint.Auth.AdminForgotPassword, model);

            return RedirectToAction(nameof(ForgotPasswordConfirmation), new { email = model.Email });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Forgot password request failed for {Email}", model.Email);
            ModelState.AddModelError(string.Empty, MessageConstant.ServiceUnavailable);
            return View(model);
        }
    }

    /// <summary>
    /// Displays confirmation view after password reset email dispatch.
    /// </summary>
    [HttpGet]
    [AllowAnonymous]
    public IActionResult ForgotPasswordConfirmation(string? email = null)
    {
        ViewData["Email"] = email;
        return View();
    }

    /// <summary>
    /// Displays the reset password view with token.
    /// </summary>
    [HttpGet]
    [AllowAnonymous]
    public IActionResult ResetPassword(string? token = null)
    {
        if (string.IsNullOrWhiteSpace(token))
        {
            TempData["ErrorMessage"] = "A valid password reset token is required.";
            return RedirectToAction(nameof(Login));
        }

        return View(new ResetPasswordRequest { Token = token });
    }

    /// <summary>
    /// Submits new password for token.
    /// </summary>
    [HttpPost]
    [AllowAnonymous]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ResetPassword(ResetPasswordRequest model)
    {
        if (!ModelState.IsValid)
        {
            return View(model);
        }

        try
        {
            var response = await _apiService.PostAsync<bool>(ApiEndPoint.Auth.AdminResetPassword, model);

            if (!response.IsSuccess)
            {
                ModelState.AddModelError(string.Empty, response.Message ?? "Failed to reset password.");
                return View(model);
            }

            TempData["SuccessMessage"] = "Your password has been reset successfully. Please sign in with your new password.";
            return RedirectToAction(nameof(Login));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Reset password submission failed.");
            ModelState.AddModelError(string.Empty, MessageConstant.ServiceUnavailable);
            return View(model);
        }
    }

    /// <summary>
    /// Signs out the admin user, revoking server session and clearing cookies.
    /// </summary>
    [HttpGet]
    [HttpPost]
    public async Task<IActionResult> Logout()
    {
        var refreshToken = HttpContext.Session.GetString(SessionKeys.AdminRefreshToken);

        try
        {
            if (!string.IsNullOrWhiteSpace(refreshToken))
            {
                await _apiService.PostAsync<bool>(
                    ApiEndPoint.Auth.AdminLogout,
                    new AdminRefreshTokenRequest { RefreshToken = refreshToken });
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Logout API call error; proceeding with local session clearance.");
        }

        HttpContext.Session.Clear();
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);

        TempData["SuccessMessage"] = "You have been signed out.";
        return RedirectToAction(nameof(Login));
    }

    /// <summary>
    /// Access denied fallback view.
    /// </summary>
    [HttpGet]
    [AllowAnonymous]
    public IActionResult AccessDenied()
    {
        return View();
    }
}
