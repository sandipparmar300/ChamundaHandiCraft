using System.Security.Claims;
using ChamundaHandicraft.Customer.Services;
using ChamundaHandicraft.Helper.ApiService;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Customer.Controllers;

/// <summary>
/// Module 01 · Authentication — docs/ui-ux-storefront/10-Modules-01-02-Auth-Home.md §1.
///
/// Guest checkout is first-class (CX principle 6): nothing in this module is a
/// gate in front of buying. Every screen here is reachable, skippable, and
/// returns the shopper to where they were.
/// </summary>
public class AuthController : StorefrontController
{
    private readonly IApiService _api;
    private readonly ILogger<AuthController> _logger;

    public AuthController(
        IStorefrontClient client,
        IApiService api,
        ILogger<AuthController> logger) : base(client)
    {
        _api = api;
        _logger = logger;
    }

    [HttpGet("/login")]
    [HttpGet("/signin")]
    public IActionResult Login(string? returnUrl)
    {
        if (User.Identity?.IsAuthenticated == true)
        {
            return RedirectToAction("Index", "Account");
        }

        Page("Sign in", "Sign in to Chamunda Handicraft to track orders, keep your wishlist and collect reward points.");
        ViewData["ReturnUrl"] = returnUrl;
        return View(new CustomerLoginRequest { ReturnUrl = returnUrl });
    }

    [HttpPost("/login")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Login(CustomerLoginRequest model)
    {
        Page("Sign in", "Sign in to Chamunda Handicraft to track orders, keep your wishlist and collect reward points.");
        ViewData["ReturnUrl"] = model.ReturnUrl;

        if (!ModelState.IsValid)
        {
            return View(model);
        }

        try
        {
            var response = await _api.PostAsync<CustomerAuthResponse>(
                ApiEndPoint.Auth.Login,
                model,
                HttpContext.RequestAborted);

            if (!response.IsSuccess || response.Data is null)
            {
                ModelState.AddModelError(string.Empty, string.IsNullOrWhiteSpace(response.Message) ? "Invalid credentials. Please try again." : response.Message);
                TempData["ErrorMessage"] = response.Message ?? "Invalid credentials. Please try again.";
                return View(model);
            }

            var auth = response.Data;

            // Build Claims
            var claims = new List<Claim>
            {
                new(ClaimTypes.NameIdentifier, auth.CustomerId.ToString()),
                new(ClaimTypes.Name, auth.FullName),
                new(ClaimTypes.Role, "Customer"),
                new("CustomerId", auth.CustomerId.ToString()),
                new("Tier", auth.RewardTier),
                new("RewardPoints", auth.RewardPoints.ToString()),
                new("CustomerToken", auth.Token ?? string.Empty)
            };

            if (!string.IsNullOrWhiteSpace(auth.Email))
            {
                claims.Add(new Claim(ClaimTypes.Email, auth.Email));
            }

            if (!string.IsNullOrWhiteSpace(auth.Phone))
            {
                claims.Add(new Claim(ClaimTypes.MobilePhone, auth.Phone));
            }

            var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
            var principal = new ClaimsPrincipal(identity);

            var authProps = new AuthenticationProperties
            {
                IsPersistent = model.RememberMe,
                ExpiresUtc = model.RememberMe
                    ? DateTimeOffset.UtcNow.AddDays(30)
                    : DateTimeOffset.UtcNow.AddHours(24)
            };

            await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, principal, authProps);

            // Store token in session
            HttpContext.Session.SetString(SessionKeys.CustomerToken, auth.Token ?? string.Empty);
            HttpContext.Session.SetString(SessionKeys.CustomerId, auth.CustomerId.ToString());
            HttpContext.Session.SetString(SessionKeys.CustomerFirstName, auth.FullName.Split(' ')[0]);

            // Merge anonymous guest cart into customer account if guest cart exists
            if (Request.Cookies.TryGetValue(SessionKeys.GuestTokenCookie, out var guestToken) && !string.IsNullOrWhiteSpace(guestToken))
            {
                try
                {
                    await Client.MergeGuestCartAsync(guestToken);
                }
                catch (Exception mergeEx)
                {
                    _logger.LogWarning(mergeEx, "Failed to merge guest cart {GuestToken} for customer {CustomerId}", guestToken, auth.CustomerId);
                }
            }

            TempData["SuccessMessage"] = $"Welcome back, {auth.FullName.Split(' ')[0]}!";

            if (!string.IsNullOrWhiteSpace(model.ReturnUrl) && Url.IsLocalUrl(model.ReturnUrl))
            {
                return Redirect(model.ReturnUrl);
            }

            return RedirectToAction("Index", "Account");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error logging in {Identifier}", model.Identifier);
            ModelState.AddModelError(string.Empty, "Unable to complete sign-in at this moment. Please try again.");
            TempData["ErrorMessage"] = "Unable to complete sign-in at this moment. Please try again.";
            return View(model);
        }
    }

    [HttpGet("/register")]
    public IActionResult Register(string? returnUrl)
    {
        if (User.Identity?.IsAuthenticated == true)
        {
            return RedirectToAction("Index", "Account");
        }

        Page("Create an account", "Create a Chamunda Handicraft account to track orders and earn reward points on every purchase.");
        ViewData["ReturnUrl"] = returnUrl;
        return View(new CustomerRegisterRequest { ReturnUrl = returnUrl });
    }

    [HttpPost("/register")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Register(CustomerRegisterRequest model)
    {
        Page("Create an account", "Create a Chamunda Handicraft account to track orders and earn reward points on every purchase.");
        ViewData["ReturnUrl"] = model.ReturnUrl;

        if (!ModelState.IsValid)
        {
            return View(model);
        }

        try
        {
            var response = await _api.PostAsync<CustomerAuthResponse>(
                ApiEndPoint.Auth.Register,
                model,
                HttpContext.RequestAborted);

            if (!response.IsSuccess || response.Data is null)
            {
                ModelState.AddModelError(string.Empty, string.IsNullOrWhiteSpace(response.Message) ? "Registration failed. Please check your details." : response.Message);
                TempData["ErrorMessage"] = response.Message ?? "Registration failed. Please check your details.";
                return View(model);
            }

            var auth = response.Data;

            // Automatically sign customer in
            var claims = new List<Claim>
            {
                new(ClaimTypes.NameIdentifier, auth.CustomerId.ToString()),
                new(ClaimTypes.Name, auth.FullName),
                new(ClaimTypes.Role, "Customer"),
                new("CustomerId", auth.CustomerId.ToString()),
                new("Tier", auth.RewardTier),
                new("RewardPoints", auth.RewardPoints.ToString()),
                new("CustomerToken", auth.Token ?? string.Empty)
            };

            if (!string.IsNullOrWhiteSpace(auth.Email))
            {
                claims.Add(new Claim(ClaimTypes.Email, auth.Email));
            }

            if (!string.IsNullOrWhiteSpace(auth.Phone))
            {
                claims.Add(new Claim(ClaimTypes.MobilePhone, auth.Phone));
            }

            var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
            var principal = new ClaimsPrincipal(identity);

            var authProps = new AuthenticationProperties
            {
                IsPersistent = true,
                ExpiresUtc = DateTimeOffset.UtcNow.AddDays(30)
            };

            await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, principal, authProps);

            HttpContext.Session.SetString(SessionKeys.CustomerToken, auth.Token ?? string.Empty);
            HttpContext.Session.SetString(SessionKeys.CustomerId, auth.CustomerId.ToString());
            HttpContext.Session.SetString(SessionKeys.CustomerFirstName, auth.FullName.Split(' ')[0]);

            // Merge anonymous guest cart into newly registered customer account if guest cart exists
            if (Request.Cookies.TryGetValue(SessionKeys.GuestTokenCookie, out var guestToken) && !string.IsNullOrWhiteSpace(guestToken))
            {
                try
                {
                    await Client.MergeGuestCartAsync(guestToken);
                }
                catch (Exception mergeEx)
                {
                    _logger.LogWarning(mergeEx, "Failed to merge guest cart {GuestToken} for customer {CustomerId}", guestToken, auth.CustomerId);
                }
            }

            TempData["SuccessMessage"] = "Your account has been created successfully! Welcome to Chamunda Handicraft.";

            if (!string.IsNullOrWhiteSpace(model.ReturnUrl) && Url.IsLocalUrl(model.ReturnUrl))
            {
                return Redirect(model.ReturnUrl);
            }

            return RedirectToAction("Index", "Account");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error registering customer {Email}", model.Email);
            ModelState.AddModelError(string.Empty, "Unable to create your account at this moment. Please try again.");
            TempData["ErrorMessage"] = "Unable to create your account at this moment. Please try again.";
            return View(model);
        }
    }

    [HttpGet("/signin/otp")]
    public IActionResult Otp(string? to)
    {
        Page("Enter your code");
        ViewData["SentTo"] = to ?? "+91 98765 43210";
        return View();
    }

    [HttpGet("/forgot-password")]
    public IActionResult ForgotPassword()
    {
        Page("Reset your password");
        return View(new CustomerForgotPasswordRequest());
    }

    [HttpPost("/forgot-password")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ForgotPassword(CustomerForgotPasswordRequest model)
    {
        Page("Reset your password");

        if (!ModelState.IsValid)
        {
            return View(model);
        }

        try
        {
            var response = await _api.PostAsync<bool>(
                ApiEndPoint.Auth.ForgotPassword,
                model,
                HttpContext.RequestAborted);

            ViewData["ResetSent"] = true;
            TempData["SuccessMessage"] = response.Message ?? "If an account exists for that address, a reset link has been sent.";
            return View(model);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing forgot-password for {Identifier}", model.Identifier);
            ViewData["ResetSent"] = true; // Avoid leaking user presence
            return View(model);
        }
    }

    [HttpGet("/reset-password")]
    public IActionResult ResetPassword(string? token)
    {
        Page("Choose a new password");
        ViewData["Token"] = token;
        return View(new CustomerResetPasswordRequest { Token = token ?? string.Empty });
    }

    [HttpPost("/reset-password")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ResetPassword(CustomerResetPasswordRequest model)
    {
        Page("Choose a new password");
        ViewData["Token"] = model.Token;

        if (!ModelState.IsValid)
        {
            return View(model);
        }

        try
        {
            var response = await _api.PostAsync<bool>(
                ApiEndPoint.Auth.ResetPassword,
                model,
                HttpContext.RequestAborted);

            if (!response.IsSuccess)
            {
                ModelState.AddModelError(string.Empty, response.Message ?? "Invalid or expired password reset link.");
                TempData["ErrorMessage"] = response.Message ?? "Invalid or expired password reset link.";
                return View(model);
            }

            TempData["SuccessMessage"] = "Your password has been changed successfully. Please sign in with your new password.";
            return RedirectToAction(nameof(Login));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing reset-password");
            ModelState.AddModelError(string.Empty, "Failed to reset password. Please try again.");
            TempData["ErrorMessage"] = "Failed to reset password. Please try again.";
            return View(model);
        }
    }

    [HttpGet("/verify-email")]
    public IActionResult VerifyEmail()
    {
        Page("Verify your email");
        return View();
    }

    [HttpGet("/verify-mobile")]
    public async Task<IActionResult> VerifyMobile()
    {
        Page("Verify your mobile number");
        string phone = string.Empty;

        if (User.Identity?.IsAuthenticated == true)
        {
            try
            {
                var profileRes = await _api.GetAsync<CustomerProfileViewModel>(
                    ApiEndPoint.Customer.ShopProfileGet,
                    null,
                    HttpContext.RequestAborted);

                if (profileRes.IsSuccess && profileRes.Data != null)
                {
                    phone = profileRes.Data.Phone ?? string.Empty;
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Could not fetch profile phone for verify-mobile");
            }
        }

        var model = new CustomerVerifyMobileRequest
        {
            Mobile = phone
        };

        return View(model);
    }

    [HttpPost("/verify-mobile")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> VerifyMobile(CustomerVerifyMobileRequest model)
    {
        Page("Verify your mobile number");

        // Combine individual digit inputs if present
        if (string.IsNullOrWhiteSpace(model.Code))
        {
            var combinedCode = $"{Request.Form["digit1"]}{Request.Form["digit2"]}{Request.Form["digit3"]}{Request.Form["digit4"]}{Request.Form["digit5"]}{Request.Form["digit6"]}".Trim();
            if (!string.IsNullOrWhiteSpace(combinedCode))
            {
                model.Code = combinedCode;
            }
        }

        if (string.IsNullOrWhiteSpace(model.Mobile))
        {
            ModelState.AddModelError(nameof(model.Mobile), "Mobile number is required.");
        }

        if (string.IsNullOrWhiteSpace(model.Code) || model.Code.Length != 6)
        {
            ModelState.AddModelError(nameof(model.Code), "Please enter a valid 6-digit verification code.");
        }

        if (!ModelState.IsValid)
        {
            return View(model);
        }

        try
        {
            var response = await _api.PostAsync<bool>(
                ApiEndPoint.Auth.VerifyMobile,
                model,
                HttpContext.RequestAborted);

            if (!response.IsSuccess)
            {
                ModelState.AddModelError(string.Empty, response.Message ?? "Invalid or expired verification code.");
                TempData["ErrorMessage"] = response.Message ?? "Invalid or expired verification code.";
                return View(model);
            }

            TempData["SuccessMessage"] = "Mobile number verified successfully! Cash on delivery is now enabled.";
            return RedirectToAction("Profile", "Account");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error verifying mobile number");
            ModelState.AddModelError(string.Empty, "Unable to verify mobile number at this time. Please try again.");
            TempData["ErrorMessage"] = "Unable to verify mobile number at this time. Please try again.";
            return View(model);
        }
    }

    [HttpPost("/send-mobile-otp")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> SendMobileOtp([FromForm] string mobile)
    {
        if (string.IsNullOrWhiteSpace(mobile))
        {
            return Json(new { success = false, message = "Please enter a valid mobile number." });
        }

        try
        {
            var response = await _api.PostAsync<bool>(
                ApiEndPoint.Auth.SendOtp,
                new CustomerOtpSendRequest { Target = mobile, Channel = "sms" },
                HttpContext.RequestAborted);

            return Json(new { success = response.IsSuccess, message = response.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending mobile OTP");
            return Json(new { success = false, message = "Failed to send code. Please try again." });
        }
    }

    [HttpGet("/complete-profile")]
    public IActionResult CompleteProfile()
    {
        Page("Complete your profile");
        return View();
    }

    [HttpGet("/account-locked")]
    public IActionResult AccountLocked()
    {
        Page("Account temporarily locked");
        return View();
    }

    [HttpGet("/welcome")]
    public IActionResult Welcome()
    {
        ActiveNav("home");
        Page("Welcome to Chamunda Handicraft");
        return View();
    }

    [HttpGet("/logout")]
    public async Task<IActionResult> Logout()
    {
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        HttpContext.Session.Clear();
        TempData["SuccessMessage"] = "You have been signed out safely.";
        return Redirect("/");
    }
}
