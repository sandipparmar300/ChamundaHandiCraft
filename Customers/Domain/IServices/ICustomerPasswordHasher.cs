namespace Customers.Domain.IServices;

public interface ICustomerPasswordHasher
{
    string HashPassword(string password);
    bool VerifyPassword(string hashedPassword, string providedPassword);
}
