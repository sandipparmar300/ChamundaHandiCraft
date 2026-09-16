namespace Identity.Application.Services;

/// <summary>
/// Cryptographic password hashing and verification contract.
/// </summary>
public interface IPasswordHasher
{
    string HashPassword(string password);
    bool VerifyPassword(string hashedPassword, string providedPassword);
}
