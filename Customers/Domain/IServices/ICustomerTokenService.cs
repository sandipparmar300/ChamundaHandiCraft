using Customers.Domain.Entities;

namespace Customers.Domain.IServices;

public interface ICustomerTokenService
{
    (string Token, DateTime ExpiresAt) GenerateAccessToken(Customer customer);
}
