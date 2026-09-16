using System.Security.Cryptography;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Identity.Domain.Entities;
using Identity.Domain.IServices;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Identity.Application.Services;

/// <summary>
/// Implements administrative authentication, lockout security, and credential recovery.
/// </summary>
public class AdminAuthService : IAdminAuthService
{
    private readonly IAdminUserRepository _userRepository;
    private readonly IAdminSessionRepository _sessionRepository;
    private readonly IPasswordResetRepository _passwordResetRepository;
    private readonly IPasswordHasher _passwordHasher;
    private readonly ITokenService _tokenService;
    private readonly IConfiguration _configuration;
    private readonly ILogger<AdminAuthService> _logger;

    public AdminAuthService(
        IAdminUserRepository userRepository,
        IAdminSessionRepository sessionRepository,
        IPasswordResetRepository passwordResetRepository,
        IPasswordHasher passwordHasher,
        ITokenService tokenService,
        IConfiguration configuration,
        ILogger<AdminAuthService> logger)
    {
        _userRepository = userRepository;
        _sessionRepository = sessionRepository;
        _passwordResetRepository = passwordResetRepository;
        _passwordHasher = passwordHasher;
        _tokenService = tokenService;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<ResponseViewModel<AdminLoginResponse>> LoginAsync(
        AdminLoginRequest request,
        string? ipAddress,
        string? userAgent)
    {
        if (request is null || string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
        {
            return ResponseViewModel<AdminLoginResponse>.Fail(
                MessageConstant.InvalidCredentials,
                ApiStatusCode.BadRequest);
        }

        var maxFailedAttempts = int.TryParse(_configuration["Security:MaxFailedLoginAttempts"], out int max) ? max : 5;
        var lockoutMinutes = int.TryParse(_configuration["Security:LockoutMinutes"], out int lockMin) ? lockMin : 15;

        // 1. Fetch user by email or mobile phone
        var (user, roles, permissions) = await _userRepository.GetByIdentifierAsync(request.Email.Trim());

        if (user is null)
        {
            await _userRepository.RecordLoginAttemptAsync(
                null,
                request.Email.Trim(),
                false,
                "Unknown identifier",
                ipAddress,
                userAgent,
                maxFailedAttempts,
                lockoutMinutes);

            return ResponseViewModel<AdminLoginResponse>.Fail(
                MessageConstant.InvalidCredentials,
                ApiStatusCode.Unauthorized);
        }

        // 2. Check active & non-deleted status
        if (!user.IsActive || user.IsDeleted)
        {
            await _userRepository.RecordLoginAttemptAsync(
                user.Id,
                user.Email,
                false,
                "Account inactive or deleted",
                ipAddress,
                userAgent,
                maxFailedAttempts,
                lockoutMinutes);

            return ResponseViewModel<AdminLoginResponse>.Fail(
                "Your account is inactive. Please contact the administrator.",
                ApiStatusCode.Forbidden);
        }

        // 3. Check lockout
        if (user.LockedOutUntil.HasValue && user.LockedOutUntil.Value > DateTime.UtcNow)
        {
            var remaining = Math.Ceiling((user.LockedOutUntil.Value - DateTime.UtcNow).TotalMinutes);
            return ResponseViewModel<AdminLoginResponse>.Fail(
                $"Account is temporarily locked due to failed attempts. Try again in {remaining} minute(s).",
                ApiStatusCode.Forbidden);
        }

        // 4. Verify password
        bool passwordValid = _passwordHasher.VerifyPassword(user.PasswordHash, request.Password);

        if (!passwordValid)
        {
            await _userRepository.RecordLoginAttemptAsync(
                user.Id,
                user.Email,
                false,
                "Password verification failed",
                ipAddress,
                userAgent,
                maxFailedAttempts,
                lockoutMinutes);

            // Re-fetch to check if this failure locked the account
            if (user.FailedLoginCount + 1 >= maxFailedAttempts)
            {
                return ResponseViewModel<AdminLoginResponse>.Fail(
                    MessageConstant.AccountLocked,
                    ApiStatusCode.Forbidden);
            }

            return ResponseViewModel<AdminLoginResponse>.Fail(
                MessageConstant.InvalidCredentials,
                ApiStatusCode.Unauthorized);
        }

        // 5. Successful login
        await _userRepository.RecordLoginAttemptAsync(
            user.Id,
            user.Email,
            true,
            null,
            ipAddress,
            userAgent,
            maxFailedAttempts,
            lockoutMinutes);

        // 6. Generate access token and refresh token
        var (accessToken, accessExpires) = _tokenService.GenerateAccessToken(user, roles, permissions);
        var (refreshToken, refreshHash, refreshExpires) = _tokenService.GenerateRefreshToken();

        // 7. Persist session
        await _sessionRepository.CreateSessionAsync(
            user.Id,
            refreshHash,
            refreshExpires,
            ipAddress,
            userAgent);

        var primaryRole = roles.FirstOrDefault(r => r.IsPrimary)?.RoleName 
            ?? roles.FirstOrDefault()?.RoleName 
            ?? "Admin";

        var responseData = new AdminLoginResponse
        {
            UserId = user.Id,
            FullName = user.FullName,
            Email = user.Email,
            Phone = user.Phone,
            RoleName = primaryRole,
            PhotoUrl = user.PhotoUrl,
            AccessToken = accessToken,
            RefreshToken = refreshToken,
            AccessTokenExpiresAt = accessExpires,
            MustChangePassword = user.MustChangePassword,
            Permissions = permissions
        };

        return ResponseViewModel<AdminLoginResponse>.Success(
            responseData,
            "Signed in successfully.");
    }

    public async Task<ResponseViewModel<string>> ForgotPasswordAsync(
        ForgotPasswordRequest request,
        string? ipAddress,
        string? userAgent)
    {
        if (request is null || string.IsNullOrWhiteSpace(request.Email))
        {
            return ResponseViewModel<string>.Fail(
                "Please provide a valid email address.",
                ApiStatusCode.BadRequest);
        }

        var (user, _, _) = await _userRepository.GetByIdentifierAsync(request.Email.Trim());

        // For security, always return success even if user not found (prevents account harvesting)
        if (user is null || !user.IsActive || user.IsDeleted)
        {
            _logger.LogInformation("Password reset requested for unknown/inactive email {Email}", request.Email);
            return ResponseViewModel<string>.Success(
                string.Empty,
                "If an account exists with this email, a password reset link has been sent.");
        }

        // Generate cryptographically secure URL-safe token
        byte[] tokenBytes = new byte[32];
        RandomNumberGenerator.Fill(tokenBytes);
        string resetToken = Convert.ToHexString(tokenBytes).ToLowerInvariant();

        // Reset tokens expire in 2 hours
        DateTime expiresAt = DateTime.UtcNow.AddHours(2);

        await _passwordResetRepository.CreateResetTokenAsync(
            user.Id,
            resetToken,
            expiresAt,
            ipAddress,
            userAgent);

        return ResponseViewModel<string>.Success(
            resetToken,
            "Password reset link has been generated.");
    }

    public async Task<ResponseViewModel<ValidatedPasswordReset>> ValidateResetTokenAsync(string token)
    {
        if (string.IsNullOrWhiteSpace(token))
        {
            return ResponseViewModel<ValidatedPasswordReset>.Fail(
                "Token is required.",
                ApiStatusCode.BadRequest);
        }

        var record = await _passwordResetRepository.ValidateResetTokenAsync(token.Trim());

        if (record is null)
        {
            return ResponseViewModel<ValidatedPasswordReset>.Fail(
                MessageConstant.ResetLinkExpired,
                ApiStatusCode.BadRequest);
        }

        return ResponseViewModel<ValidatedPasswordReset>.Success(record);
    }

    public async Task<ResponseViewModel<bool>> ResetPasswordAsync(
        ResetPasswordRequest request,
        string? ipAddress)
    {
        if (request is null || string.IsNullOrWhiteSpace(request.Token) || string.IsNullOrWhiteSpace(request.NewPassword))
        {
            return ResponseViewModel<bool>.Fail(
                "Token and new password are required.",
                ApiStatusCode.BadRequest);
        }

        if (request.NewPassword != request.ConfirmPassword)
        {
            return ResponseViewModel<bool>.Fail(
                "Passwords do not match.",
                ApiStatusCode.BadRequest);
        }

        var validated = await _passwordResetRepository.ValidateResetTokenAsync(request.Token.Trim());
        if (validated is null)
        {
            return ResponseViewModel<bool>.Fail(
                MessageConstant.ResetLinkExpired,
                ApiStatusCode.BadRequest);
        }

        // Hash new password using standard format
        string newHash = _passwordHasher.HashPassword(request.NewPassword);

        var (success, message) = await _passwordResetRepository.ResetPasswordAsync(
            request.Token.Trim(),
            newHash,
            ipAddress);

        return success
            ? ResponseViewModel<bool>.Success(true, "Your password has been reset. You can now sign in.")
            : ResponseViewModel<bool>.Fail(message, ApiStatusCode.BadRequest);
    }

    public async Task<ResponseViewModel<bool>> LogoutAsync(string? refreshToken, string? reason)
    {
        if (!string.IsNullOrWhiteSpace(refreshToken))
        {
            string hash = _tokenService.ComputeSha256Hash(refreshToken.Trim());
            await _sessionRepository.RevokeSessionAsync(hash, reason ?? "Operator sign-out");
        }

        return ResponseViewModel<bool>.Success(true, "Signed out successfully.");
    }

    public async Task<ResponseViewModel<AdminLoginResponse>> RefreshTokenAsync(
        string refreshToken,
        string? ipAddress,
        string? userAgent)
    {
        if (string.IsNullOrWhiteSpace(refreshToken))
        {
            return ResponseViewModel<AdminLoginResponse>.Fail(
                "Refresh token is required.",
                ApiStatusCode.BadRequest);
        }

        string hash = _tokenService.ComputeSha256Hash(refreshToken.Trim());
        var session = await _sessionRepository.GetSessionByHashAsync(hash);

        if (session is null)
        {
            return ResponseViewModel<AdminLoginResponse>.Fail(
                "Invalid or expired refresh token.",
                ApiStatusCode.Unauthorized);
        }

        // Revoke old session handle
        await _sessionRepository.RevokeSessionAsync(hash, "Rotated via refresh-token");

        // Fetch user and permissions
        var (user, roles, permissions) = await _userRepository.GetByIdentifierAsync(session.AdminUserId.ToString());
        if (user is null || !user.IsActive || user.IsDeleted)
        {
            return ResponseViewModel<AdminLoginResponse>.Fail(
                "User account is no longer active.",
                ApiStatusCode.Unauthorized);
        }

        // Issue new tokens
        var (newAccessToken, accessExpires) = _tokenService.GenerateAccessToken(user, roles, permissions);
        var (newRefreshToken, newRefreshHash, refreshExpires) = _tokenService.GenerateRefreshToken();

        await _sessionRepository.CreateSessionAsync(
            user.Id,
            newRefreshHash,
            refreshExpires,
            ipAddress,
            userAgent);

        var primaryRole = roles.FirstOrDefault(r => r.IsPrimary)?.RoleName
            ?? roles.FirstOrDefault()?.RoleName
            ?? "Admin";

        var response = new AdminLoginResponse
        {
            UserId = user.Id,
            FullName = user.FullName,
            Email = user.Email,
            Phone = user.Phone,
            RoleName = primaryRole,
            PhotoUrl = user.PhotoUrl,
            AccessToken = newAccessToken,
            RefreshToken = newRefreshToken,
            AccessTokenExpiresAt = accessExpires,
            MustChangePassword = user.MustChangePassword,
            Permissions = permissions
        };

        return ResponseViewModel<AdminLoginResponse>.Success(response);
    }
}
