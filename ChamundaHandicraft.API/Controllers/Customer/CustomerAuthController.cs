using ChamundaHandicraft.API.Services.Email;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Customers.Domain.IServices;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.API.Controllers.Customer;

/// <summary>
/// Storefront Customer authentication controller.
/// Downstream target of APIGateway routes: /Shop/Auth/* -> /api/customer/auth/*
/// </summary>
[ApiController]
[Route("api/customer/auth")]
public class CustomerAuthController : ControllerBase
{
    private readonly ICustomerAuthService _authService;
    private readonly IEmailService _emailService;
    private readonly ILogger<CustomerAuthController> _logger;

    public CustomerAuthController(
        ICustomerAuthService authService,
        IEmailService emailService,
        ILogger<CustomerAuthController> logger)
    {
        _authService = authService;
        _emailService = emailService;
        _logger = logger;
    }

    /// <summary>
    /// Registers a new customer account.
    /// Route: POST /api/customer/auth/register
    /// </summary>
    [HttpPost("register")]
    [AllowAnonymous]
    public async Task<ActionResult<ResponseViewModel<CustomerAuthResponse>>> Register([FromBody] CustomerRegisterRequest request)
    {
        _logger.LogInformation("Processing customer registration for {Email}", request.Email);
        var response = await _authService.RegisterAsync(request);

        if (response.IsSuccess && response.Data != null)
        {
            _ = Task.Run(async () =>
            {
                try
                {
                    await _emailService.SendCustomerWelcomeEmailAsync(
                        response.Data.Email,
                        response.Data.FullName,
                        response.Data.RewardPoints > 0 ? response.Data.RewardPoints : 50);

                    _logger.LogInformation("Successfully dispatched onboarding welcome email to {Email}", response.Data.Email);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to dispatch onboarding welcome email to {Email}", response.Data.Email);
                }
            });
        }

        return StatusCode((int)response.StatusCode, response);
    }

    /// <summary>
    /// Authenticates a customer by email/phone and password.
    /// Route: POST /api/customer/auth/login
    /// </summary>
    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<ActionResult<ResponseViewModel<CustomerAuthResponse>>> Login([FromBody] CustomerLoginRequest request)
    {
        var ip = HttpContext.Connection.RemoteIpAddress?.ToString();
        var userAgent = Request.Headers.UserAgent.ToString();

        _logger.LogInformation("Processing customer login for {Identifier}", request.Identifier);
        var response = await _authService.LoginAsync(request, ip, userAgent);
        return StatusCode((int)response.StatusCode, response);
    }

    /// <summary>
    /// Requests a password reset link for the given email/phone.
    /// Route: POST /api/customer/auth/forgot-password
    /// </summary>
    [HttpPost("forgot-password")]
    [HttpPost("forgotpassword")]
    [AllowAnonymous]
    public async Task<ActionResult<ResponseViewModel<bool>>> ForgotPassword([FromBody] CustomerForgotPasswordRequest request)
    {
        _logger.LogInformation("Processing customer forgot-password for {Identifier}", request.Identifier);
        var response = await _authService.ForgotPasswordAsync(request);

        if (response.IsSuccess && response.Data != null && response.Data.ResetInitiated && !string.IsNullOrWhiteSpace(response.Data.RawToken) && !string.IsNullOrWhiteSpace(response.Data.Email))
        {
            _ = Task.Run(async () =>
            {
                try
                {
                    await _emailService.SendCustomerPasswordResetEmailAsync(
                        response.Data.Email,
                        response.Data.FullName ?? "Customer",
                        response.Data.RawToken);

                    _logger.LogInformation("Successfully dispatched password reset email to {Email}", response.Data.Email);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to dispatch password reset email to {Email}", response.Data.Email);
                }
            });
        }

        return Ok(ResponseViewModel<bool>.Success(true, "If an account exists for that address, a password reset link has been sent."));
    }

    /// <summary>
    /// Resets customer password using security token.
    /// Route: POST /api/customer/auth/reset-password
    /// </summary>
    [HttpPost("reset-password")]
    [HttpPost("resetpassword")]
    [AllowAnonymous]
    public async Task<ActionResult<ResponseViewModel<bool>>> ResetPassword([FromBody] CustomerResetPasswordRequest request)
    {
        _logger.LogInformation("Processing customer reset-password");
        var response = await _authService.ResetPasswordAsync(request);
        return StatusCode((int)response.StatusCode, response);
    }

    /// <summary>
    /// Sends an OTP to phone or email.
    /// Route: POST /api/customer/auth/send-otp
    /// </summary>
    [HttpPost("send-otp")]
    [HttpPost("sendotp")]
    [AllowAnonymous]
    public async Task<ActionResult<ResponseViewModel<bool>>> SendOtp([FromBody] CustomerOtpSendRequest request)
    {
        _logger.LogInformation("Processing customer OTP dispatch for {Target}", request.Target);
        var response = await _authService.SendOtpAsync(request);
        return StatusCode((int)response.StatusCode, response);
    }

    /// <summary>
    /// Verifies mobile number for customer.
    /// Route: POST /api/customer/auth/verify-mobile
    /// </summary>
    [HttpPost("verify-mobile")]
    [HttpPost("verifymobile")]
    [AllowAnonymous]
    public async Task<ActionResult<ResponseViewModel<bool>>> VerifyMobile([FromBody] CustomerVerifyMobileRequest request)
    {
        int customerId = GetCurrentCustomerId();
        _logger.LogInformation("Processing customer mobile verification for Customer #{CustomerId}, Phone: {Mobile}", customerId, request.Mobile);
        var response = await _authService.VerifyMobileAsync(customerId, request);
        return StatusCode((int)response.StatusCode, response);
    }

    private int GetCurrentCustomerId()
    {
        var idClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst("CustomerId")?.Value
            ?? User.FindFirst("sub")?.Value;

        return int.TryParse(idClaim, out int id) ? id : 0;
    }
}
