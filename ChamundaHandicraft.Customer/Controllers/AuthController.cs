using ChamundaHandicraft.Customer.Services;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Customer;
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
    public AuthController(IStorefrontClient client) : base(client) { }

    [HttpGet("/login")]
    [HttpGet("/signin")]
    public IActionResult Login(string? returnUrl)
    {
        Page("Sign in", "Sign in to Chamunda Handicraft to track orders, keep your wishlist and collect reward points.");
        ViewData["ReturnUrl"] = returnUrl;
        return View();
    }

    [HttpGet("/register")]
    public IActionResult Register(string? returnUrl)
    {
        Page("Create an account", "Create a Chamunda Handicraft account to track orders and earn reward points on every purchase.");
        ViewData["ReturnUrl"] = returnUrl;
        return View();
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
        return View();
    }

    [HttpGet("/reset-password")]
    public IActionResult ResetPassword(string? token)
    {
        Page("Choose a new password");
        ViewData["Token"] = token;
        return View();
    }

    [HttpGet("/verify-email")]
    public IActionResult VerifyEmail()
    {
        Page("Verify your email");
        return View();
    }

    [HttpGet("/verify-mobile")]
    public IActionResult VerifyMobile()
    {
        Page("Verify your mobile number");
        return View();
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
    public IActionResult Logout() => Redirect("/");
}
