using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Customers.Domain.Entities;
using Customers.Domain.IServices;

namespace Customers.Application.Services;

public class CustomerProfileService : ICustomerProfileService
{
    private readonly ICustomerProfileRepository _profileRepo;
    private readonly ICustomerAuthRepository _authRepo;
    private readonly ICustomerPasswordHasher _passwordHasher;

    public CustomerProfileService(
        ICustomerProfileRepository profileRepo,
        ICustomerAuthRepository authRepo,
        ICustomerPasswordHasher passwordHasher)
    {
        _profileRepo = profileRepo;
        _authRepo = authRepo;
        _passwordHasher = passwordHasher;
    }

    public async Task<ResponseViewModel<CustomerProfileViewModel>> GetProfileAsync(int customerId)
    {
        if (customerId <= 0)
        {
            return ResponseViewModel<CustomerProfileViewModel>.Fail("Invalid customer identifier.", ApiStatusCode.BadRequest);
        }

        var customer = await _profileRepo.GetProfileAsync(customerId);
        if (customer == null)
        {
            return ResponseViewModel<CustomerProfileViewModel>.Fail("Customer account not found.", ApiStatusCode.NotFound);
        }

        var (firstName, lastName) = SplitName(customer.FullName);

        var vm = new CustomerProfileViewModel
        {
            Id = customer.Id,
            FullName = customer.FullName,
            FirstName = firstName,
            LastName = lastName,
            Email = customer.Email ?? string.Empty,
            Phone = customer.Phone,
            EmailVerified = customer.EmailVerified,
            MobileVerified = customer.MobileVerified,
            Gender = customer.Gender,
            DateOfBirth = customer.DateOfBirth,
            AvatarUrl = customer.AvatarUrl,
            Gstin = customer.Gstin,
            OrderCount = customer.OrderCount,
            LifetimeValue = customer.LifetimeValue,
            RewardPointBalance = customer.RewardPointBalance,
            RewardTier = customer.RewardTier,
            RegisteredOn = customer.RegisteredOn
        };

        return ResponseViewModel<CustomerProfileViewModel>.Success(vm);
    }

    public async Task<ResponseViewModel<bool>> UpdateProfileAsync(int customerId, CustomerProfileUpdateRequest request)
    {
        if (customerId <= 0)
        {
            return ResponseViewModel<bool>.Fail("Invalid customer identifier.", ApiStatusCode.BadRequest);
        }

        if (string.IsNullOrWhiteSpace(request.FirstName))
        {
            return ResponseViewModel<bool>.Fail("First name is required.", ApiStatusCode.ValidationFailed);
        }

        string fullName = request.FullName;

        var (success, error) = await _profileRepo.UpdateProfileAsync(
            customerId,
            fullName,
            request.Phone,
            request.Gender,
            request.DateOfBirth,
            request.Gstin);

        if (!success)
        {
            return ResponseViewModel<bool>.Fail(error ?? "Failed to update profile.", ApiStatusCode.BadRequest);
        }

        return ResponseViewModel<bool>.Success(true, "Profile updated successfully.");
    }

    public async Task<ResponseViewModel<bool>> ChangePasswordAsync(int customerId, CustomerChangePasswordRequest request)
    {
        if (customerId <= 0)
        {
            return ResponseViewModel<bool>.Fail("Invalid customer identifier.", ApiStatusCode.BadRequest);
        }

        if (string.IsNullOrWhiteSpace(request.CurrentPassword) || string.IsNullOrWhiteSpace(request.NewPassword))
        {
            return ResponseViewModel<bool>.Fail("Current and new passwords are required.", ApiStatusCode.ValidationFailed);
        }

        if (request.NewPassword != request.ConfirmPassword)
        {
            return ResponseViewModel<bool>.Fail("New passwords do not match.", ApiStatusCode.ValidationFailed);
        }

        var customer = await _authRepo.GetByIdAsync(customerId);
        if (customer == null)
        {
            return ResponseViewModel<bool>.Fail("Customer account not found.", ApiStatusCode.NotFound);
        }

        // Verify current password
        if (string.IsNullOrEmpty(customer.PasswordHash) || !_passwordHasher.VerifyPassword(customer.PasswordHash, request.CurrentPassword))
        {
            return ResponseViewModel<bool>.Fail("Current password is incorrect.", ApiStatusCode.BadRequest);
        }

        string newHash = _passwordHasher.HashPassword(request.NewPassword);

        var (success, error) = await _profileRepo.ChangePasswordAsync(customerId, newHash, request.SignOutOthers);
        if (!success)
        {
            return ResponseViewModel<bool>.Fail(error ?? "Failed to change password.", ApiStatusCode.BadRequest);
        }

        return ResponseViewModel<bool>.Success(true, "Your password has been updated successfully.");
    }

    public async Task<ResponseViewModel<CustomerDashboardViewModel>> GetDashboardAsync(int customerId)
    {
        var profileRes = await GetProfileAsync(customerId);
        if (!profileRes.IsSuccess || profileRes.Data == null)
        {
            return ResponseViewModel<CustomerDashboardViewModel>.Fail(profileRes.Message, profileRes.StatusCode);
        }

        var profile = profileRes.Data;

        var dashboard = new CustomerDashboardViewModel
        {
            Profile = profile,
            OrderCount = profile.OrderCount,
            InTransitCount = 0,
            SavedPiecesCount = 0,
            CouponsAvailableCount = 2,
            Rewards = new RewardBalanceViewModel
            {
                Points = profile.RewardPointBalance,
                CurrencyValue = profile.RewardPointBalance,
                TierName = profile.RewardTier,
                NextTierName = profile.RewardTier == "Bronze" ? "Silver" : profile.RewardTier == "Silver" ? "Gold" : null,
                NextTierAtPoints = profile.RewardTier == "Bronze" ? 2000 : profile.RewardTier == "Silver" ? 5000 : null
            }
        };

        return ResponseViewModel<CustomerDashboardViewModel>.Success(dashboard);
    }

    private static (string First, string Last) SplitName(string fullName)
    {
        if (string.IsNullOrWhiteSpace(fullName)) return (string.Empty, string.Empty);
        var parts = fullName.Trim().Split(' ', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length == 1) return (parts[0], string.Empty);
        return (parts[0], string.Join(" ", parts.Skip(1)));
    }
}
