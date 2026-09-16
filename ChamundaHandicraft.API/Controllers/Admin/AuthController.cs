using System.Security.Claims;
using ChamundaHandicraft.API.Services.Email;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Identity.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.API.Controllers.Admin;

/// <summary>
/// Admin Portal authentication controller.
/// Downstream target of APIGateway route: /Admin/Auth/* -> /api/admin/auth/*
/// </summary>
[ApiController]
[Route("api/admin/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAdminAuthService _authService;
    private readonly IEmailService _emailService;
    private readonly ILogger<AuthController> _logger;

    public AuthController(
        IAdminAuthService authService,
        IEmailService emailService,
        ILogger<AuthController> logger)
    {
        _authService = authService;
        _emailService = emailService;
        _logger = logger;
    }

    /// <summary>
    /// Authenticates admin credentials and returns JWT bearer token and role/permissions.
    /// Route: POST /api/admin/auth/login
    /// </summary>
    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<ActionResult<ResponseViewModel<AdminLoginResponse>>> Login([FromBody] AdminLoginRequest request)
    {
        var ip = HttpContext.Connection.RemoteIpAddress?.ToString();
        var userAgent = Request.Headers.UserAgent.ToString();

        var response = await _authService.LoginAsync(request, ip, userAgent);

        return StatusCode((int)response.StatusCode, response);
    }

    /// <summary>
    /// Generates a reset token and sends an email with the password reset link.
    /// Route: POST /api/admin/auth/forgotpassword OR /api/admin/auth/forgot-password
    /// </summary>
    [HttpPost("forgotpassword")]
    [HttpPost("forgot-password")]
    [AllowAnonymous]
    public async Task<ActionResult<ResponseViewModel<bool>>> ForgotPassword([FromBody] ForgotPasswordRequest request)
    {
        var ip = HttpContext.Connection.RemoteIpAddress?.ToString();
        var userAgent = Request.Headers.UserAgent.ToString();

        var tokenResponse = await _authService.ForgotPasswordAsync(request, ip, userAgent);

        // If a valid reset token was generated, dispatch the reset email
        if (tokenResponse.IsSuccess && !string.IsNullOrWhiteSpace(tokenResponse.Data))
        {
            var token = tokenResponse.Data;
            var recipientEmail = request.Email.Trim();
            var recipientName = recipientEmail.Split('@')[0];

            await _emailService.SendPasswordResetEmailAsync(recipientEmail, recipientName, token);
        }

        // Always return generic success message to prevent user enumeration
        return Ok(ResponseViewModel<bool>.Success(
            true,
            "If an account exists with this email, a password reset link has been sent."));
    }

    /// <summary>
    /// Validates a password reset token before showing the reset form.
    /// Route: GET /api/admin/auth/validateresettoken OR /api/admin/auth/validate-reset-token
    /// </summary>
    [HttpGet("validateresettoken")]
    [HttpGet("validate-reset-token")]
    [AllowAnonymous]
    public async Task<ActionResult<ResponseViewModel<bool>>> ValidateResetToken([FromQuery] string token)
    {
        var result = await _authService.ValidateResetTokenAsync(token);
        return StatusCode((int)result.StatusCode, ResponseViewModel<bool>.Success(result.IsSuccess, result.Message));
    }

    /// <summary>
    /// Applies new password using a validated reset token.
    /// Route: POST /api/admin/auth/resetpassword OR /api/admin/auth/reset-password
    /// </summary>
    [HttpPost("resetpassword")]
    [HttpPost("reset-password")]
    [AllowAnonymous]
    public async Task<ActionResult<ResponseViewModel<bool>>> ResetPassword([FromBody] ResetPasswordRequest request)
    {
        var ip = HttpContext.Connection.RemoteIpAddress?.ToString();
        var response = await _authService.ResetPasswordAsync(request, ip);

        return StatusCode((int)response.StatusCode, response);
    }

    /// <summary>
    /// Revokes the current admin session.
    /// Route: POST /api/admin/auth/logout
    /// </summary>
    [HttpPost("logout")]
    public async Task<ActionResult<ResponseViewModel<bool>>> Logout([FromBody] AdminRefreshTokenRequest? request)
    {
        var response = await _authService.LogoutAsync(request?.RefreshToken, "Operator sign-out");
        return Ok(response);
    }

    /// <summary>
    /// Exchanges an unexpired refresh token for a fresh access token.
    /// Route: POST /api/admin/auth/refreshtoken OR /api/admin/auth/refresh-token
    /// </summary>
    [HttpPost("refreshtoken")]
    [HttpPost("refresh-token")]
    [AllowAnonymous]
    public async Task<ActionResult<ResponseViewModel<AdminLoginResponse>>> RefreshToken([FromBody] AdminRefreshTokenRequest request)
    {
        var ip = HttpContext.Connection.RemoteIpAddress?.ToString();
        var userAgent = Request.Headers.UserAgent.ToString();

        var response = await _authService.RefreshTokenAsync(request.RefreshToken, ip, userAgent);
        return StatusCode((int)response.StatusCode, response);
    }

    /// <summary>
    /// Returns the active operator's granted permission keys.
    /// Route: GET /api/admin/auth/permissionkeys OR /api/admin/auth/permission-keys
    /// </summary>
    [HttpGet("permissionkeys")]
    [HttpGet("permission-keys")]
    [Authorize]
    public ActionResult<ResponseViewModel<List<string>>> PermissionKeys()
    {
        var permissions = User.Claims
            .Where(c => c.Type == "permission")
            .Select(c => c.Value)
            .Distinct()
            .ToList();

        return Ok(ResponseViewModel<List<string>>.Success(permissions));
    }
}
