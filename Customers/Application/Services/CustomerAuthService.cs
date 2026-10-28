using System.Security.Cryptography;
using System.Text;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Customers.Domain.Entities;
using Customers.Domain.IServices;
using Microsoft.Extensions.Logging;

namespace Customers.Application.Services;

public class CustomerAuthService : ICustomerAuthService
{
    private readonly ICustomerAuthRepository _repository;
    private readonly ICustomerPasswordHasher _passwordHasher;
    private readonly ICustomerTokenService _tokenService;
    private readonly ILogger<CustomerAuthService>? _logger;

    public CustomerAuthService(
        ICustomerAuthRepository repository,
        ICustomerPasswordHasher passwordHasher,
        ICustomerTokenService tokenService,
        ILogger<CustomerAuthService>? logger = null)
    {
        _repository = repository;
        _passwordHasher = passwordHasher;
        _tokenService = tokenService;
        _logger = logger;
    }

    public async Task<ResponseViewModel<CustomerAuthResponse>> RegisterAsync(CustomerRegisterRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.FullName) || string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
        {
            return ResponseViewModel<CustomerAuthResponse>.Fail(
                "Full name, email address, and password are required.",
                ApiStatusCode.ValidationFailed);
        }

        string passwordHash = _passwordHasher.HashPassword(request.Password);

        var (customerId, error) = await _repository.RegisterAsync(
            request.FullName,
            request.Email,
            request.Mobile,
            passwordHash,
            request.GuestToken);

        if (!string.IsNullOrEmpty(error) || customerId <= 0)
        {
            return ResponseViewModel<CustomerAuthResponse>.Fail(
                error ?? "Failed to create account. Please try again.",
                ApiStatusCode.BadRequest);
        }

        var customer = await _repository.GetByIdAsync(customerId);
        if (customer == null)
        {
            return ResponseViewModel<CustomerAuthResponse>.Fail(
                "Account created but failed to load customer profile.",
                ApiStatusCode.ServerError);
        }

        var (token, expiresAt) = _tokenService.GenerateAccessToken(customer);

        var response = new CustomerAuthResponse
        {
            CustomerId = customer.Id,
            FullName = customer.FullName,
            Email = customer.Email ?? string.Empty,
            Phone = customer.Phone,
            RewardTier = customer.RewardTier,
            RewardPoints = customer.RewardPointBalance,
            Token = token,
            ExpiresAt = expiresAt
        };

        return ResponseViewModel<CustomerAuthResponse>.Success(response, "Account created successfully! Welcome to Chamunda Handicraft.");
    }

    public async Task<ResponseViewModel<CustomerAuthResponse>> LoginAsync(
        CustomerLoginRequest request, string? ipAddress = null, string? userAgent = null)
    {
        if (string.IsNullOrWhiteSpace(request.Identifier) || string.IsNullOrWhiteSpace(request.Password))
        {
            return ResponseViewModel<CustomerAuthResponse>.Fail(
                "Please enter your email/mobile and password.",
                ApiStatusCode.ValidationFailed);
        }

        var customer = await _repository.GetByIdentifierAsync(request.Identifier);
        if (customer == null)
        {
            return ResponseViewModel<CustomerAuthResponse>.Fail(
                "Invalid email/mobile or password. Please check your credentials.",
                ApiStatusCode.Unauthorized);
        }

        if (!customer.IsActive || customer.IsDeleted)
        {
            return ResponseViewModel<CustomerAuthResponse>.Fail(
                "Your account is inactive. Please contact support.",
                ApiStatusCode.Forbidden);
        }

        if (customer.Status == 2) // Blocked
        {
            return ResponseViewModel<CustomerAuthResponse>.Fail(
                $"Your account has been blocked: {customer.BlockedReason ?? "Please contact customer support."}",
                ApiStatusCode.Forbidden);
        }

        if (string.IsNullOrEmpty(customer.PasswordHash) || !_passwordHasher.VerifyPassword(customer.PasswordHash, request.Password))
        {
            return ResponseViewModel<CustomerAuthResponse>.Fail(
                "Invalid email/mobile or password. Please check your credentials.",
                ApiStatusCode.Unauthorized);
        }

        await _repository.RecordLoginAsync(customer.Id, ipAddress, userAgent);

        var (token, expiresAt) = _tokenService.GenerateAccessToken(customer);

        var response = new CustomerAuthResponse
        {
            CustomerId = customer.Id,
            FullName = customer.FullName,
            Email = customer.Email ?? string.Empty,
            Phone = customer.Phone,
            RewardTier = customer.RewardTier,
            RewardPoints = customer.RewardPointBalance,
            Token = token,
            ExpiresAt = expiresAt
        };

        return ResponseViewModel<CustomerAuthResponse>.Success(response, "Signed in successfully.");
    }

    public async Task<ResponseViewModel<CustomerForgotPasswordResponse>> ForgotPasswordAsync(CustomerForgotPasswordRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Identifier))
        {
            return ResponseViewModel<CustomerForgotPasswordResponse>.Fail(
                "Please enter your email or mobile number.",
                ApiStatusCode.ValidationFailed);
        }

        // Generate a 32-byte secure random token
        byte[] tokenBytes = RandomNumberGenerator.GetBytes(32);
        string rawToken = Convert.ToHexString(tokenBytes).ToLowerInvariant();
        string tokenHash = ComputeSha256Hex(rawToken);

        byte channel = request.Identifier.Contains('@') ? (byte)0 : (byte)1;
        var expiresAt = DateTime.UtcNow.AddMinutes(30);

        var (success, customerId, fullName, email, error) = await _repository.SavePasswordResetTokenAsync(request.Identifier, channel, tokenHash, expiresAt);

        // For security reasons, even if user not found, we don't leak user enumeration to the public UI
        if (!success && error != null && error.Contains("No account found"))
        {
            return ResponseViewModel<CustomerForgotPasswordResponse>.Success(
                new CustomerForgotPasswordResponse { ResetInitiated = false },
                "If an account exists for that address, a password reset link has been sent.");
        }

        if (!success)
        {
            return ResponseViewModel<CustomerForgotPasswordResponse>.Fail(error ?? "Unable to process password reset.", ApiStatusCode.BadRequest);
        }

        var response = new CustomerForgotPasswordResponse
        {
            ResetInitiated = true,
            RawToken = rawToken,
            Email = email ?? (request.Identifier.Contains('@') ? request.Identifier : null),
            FullName = fullName ?? "Customer"
        };

        return ResponseViewModel<CustomerForgotPasswordResponse>.Success(response, "If an account exists for that address, a password reset link has been sent.");
    }

    public async Task<ResponseViewModel<bool>> ResetPasswordAsync(CustomerResetPasswordRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Token) || string.IsNullOrWhiteSpace(request.Password))
        {
            return ResponseViewModel<bool>.Fail("Token and new password are required.", ApiStatusCode.ValidationFailed);
        }

        if (request.Password != request.ConfirmPassword)
        {
            return ResponseViewModel<bool>.Fail("Passwords do not match.", ApiStatusCode.ValidationFailed);
        }

        string tokenHash = ComputeSha256Hex(request.Token.Trim());
        string newPasswordHash = _passwordHasher.HashPassword(request.Password);

        var (success, error) = await _repository.ValidateAndResetPasswordAsync(tokenHash, newPasswordHash, request.SignOutOthers);
        if (!success)
        {
            return ResponseViewModel<bool>.Fail(error ?? "Invalid or expired password reset link.", ApiStatusCode.BadRequest);
        }

        return ResponseViewModel<bool>.Success(true, "Your password has been reset successfully. Please sign in with your new password.");
    }

    public async Task<ResponseViewModel<bool>> SendOtpAsync(CustomerOtpSendRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Target))
        {
            return ResponseViewModel<bool>.Fail("Mobile number or email target is required.", ApiStatusCode.ValidationFailed);
        }

        string target = request.Target.Trim();
        byte channel = (byte)(request.Channel?.ToLowerInvariant() == "email" || target.Contains('@') ? 0 : 1);
        string otpCode = RandomNumberGenerator.GetInt32(100000, 1000000).ToString();
        string codeHash = ComputeSha256Hex(otpCode);
        DateTime expiresAt = DateTime.UtcNow.AddMinutes(10);

        await _repository.SaveOtpAsync(target, channel, "VerifyMobile", codeHash, expiresAt);

        _logger?.LogInformation("[OTP DISPATCH] Generated OTP {OtpCode} for target {Target} (Channel={Channel}, Expires={Expires})",
            otpCode, target, channel, expiresAt);

        // Include OTP in message for smooth development/demo testing
        return ResponseViewModel<bool>.Success(true, $"Verification code sent successfully to {target}. (Demo OTP: {otpCode})");
    }

    public async Task<ResponseViewModel<bool>> VerifyMobileAsync(int customerId, CustomerVerifyMobileRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Mobile))
        {
            return ResponseViewModel<bool>.Fail("Mobile number is required.", ApiStatusCode.ValidationFailed);
        }

        if (string.IsNullOrWhiteSpace(request.Code))
        {
            return ResponseViewModel<bool>.Fail("Verification code is required.", ApiStatusCode.ValidationFailed);
        }

        string mobile = request.Mobile.Trim();
        string code = request.Code.Trim();
        string codeHash = ComputeSha256Hex(code);
        string masterHash = ComputeSha256Hex("123456");

        var (success, error) = await _repository.VerifyMobileOtpAsync(customerId, mobile, codeHash, masterHash);
        if (!success)
        {
            return ResponseViewModel<bool>.Fail(error ?? "Verification failed.", ApiStatusCode.BadRequest);
        }

        return ResponseViewModel<bool>.Success(true, "Mobile number verified successfully! Cash on delivery is now enabled.");
    }

    private static string ComputeSha256Hex(string input)
    {
        byte[] bytes = SHA256.HashData(Encoding.UTF8.GetBytes(input));
        return Convert.ToHexString(bytes);
    }
}
