using Customers.Domain.Entities;

namespace Customers.Domain.IServices;

public interface ICustomerProfileRepository
{
    Task<Customer?> GetProfileAsync(int customerId);
    Task<(bool Success, string? ErrorMessage)> UpdateProfileAsync(int customerId, string fullName, string? phone, string? gender, DateTime? dateOfBirth, string? gstin);
    Task<(bool Success, string? ErrorMessage)> ChangePasswordAsync(int customerId, string newPasswordHash, bool signOutOthers);
}
