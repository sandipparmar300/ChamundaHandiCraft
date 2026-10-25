using Customers.Domain.Entities;

namespace Customers.Domain.IServices;

public interface ICustomerAuthRepository
{
    Task<(int CustomerId, string? ErrorMessage)> RegisterAsync(string fullName, string email, string? phone, string passwordHash, string? guestToken);
    Task<Customer?> GetByIdentifierAsync(string identifier);
    Task<Customer?> GetByIdAsync(int id);
    Task RecordLoginAsync(int customerId, string? ipAddress, string? userAgent);
    Task<(bool Success, int CustomerId, string? FullName, string? Email, string? ErrorMessage)> SavePasswordResetTokenAsync(string destination, byte channel, string tokenHash, DateTime expiresAt);
    Task<(bool Success, string? ErrorMessage)> ValidateAndResetPasswordAsync(string tokenHash, string newPasswordHash, bool signOutOthers);
    Task SaveOtpAsync(string destination, byte channel, string purpose, string codeHash, DateTime expiresAt);
    Task<(bool Success, string? ErrorMessage)> VerifyMobileOtpAsync(int customerId, string mobile, string codeHash, string? masterHash = null);
}
