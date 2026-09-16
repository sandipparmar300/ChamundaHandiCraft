using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Identity.Domain.Entities;

namespace Identity.Application.Services;

/// <summary>
/// Orchestrates admin login, lockout policy, session tracking, and password reset flows.
/// </summary>
public interface IAdminAuthService
{
    Task<ResponseViewModel<AdminLoginResponse>> LoginAsync(
        AdminLoginRequest request,
        string? ipAddress,
        string? userAgent);

    Task<ResponseViewModel<string>> ForgotPasswordAsync(
        ForgotPasswordRequest request,
        string? ipAddress,
        string? userAgent);

    Task<ResponseViewModel<ValidatedPasswordReset>> ValidateResetTokenAsync(string token);

    Task<ResponseViewModel<bool>> ResetPasswordAsync(
        ResetPasswordRequest request,
        string? ipAddress);

    Task<ResponseViewModel<bool>> LogoutAsync(
        string? refreshToken,
        string? reason);

    Task<ResponseViewModel<AdminLoginResponse>> RefreshTokenAsync(
        string refreshToken,
        string? ipAddress,
        string? userAgent);
}
