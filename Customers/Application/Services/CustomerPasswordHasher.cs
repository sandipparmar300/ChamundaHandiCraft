using System.Buffers.Binary;
using System.Security.Cryptography;
using Customers.Domain.IServices;

namespace Customers.Application.Services;

public class CustomerPasswordHasher : ICustomerPasswordHasher
{
    private const int IterationCount = 100_000;
    private const int SaltSize = 16;
    private const int SubkeySize = 32;

    public string HashPassword(string password)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(password);

        byte[] salt = new byte[SaltSize];
        RandomNumberGenerator.Fill(salt);

        byte[] subkey = Rfc2898DeriveBytes.Pbkdf2(
            password,
            salt,
            IterationCount,
            HashAlgorithmName.SHA256,
            SubkeySize);

        byte[] output = new byte[1 + 4 + 4 + 4 + SaltSize + SubkeySize];
        output[0] = 0x01;
        BinaryPrimitives.WriteUInt32BigEndian(output.AsSpan(1, 4), 1); // HMACSHA256
        BinaryPrimitives.WriteUInt32BigEndian(output.AsSpan(5, 4), (uint)IterationCount);
        BinaryPrimitives.WriteUInt32BigEndian(output.AsSpan(9, 4), (uint)SaltSize);
        Buffer.BlockCopy(salt, 0, output, 13, SaltSize);
        Buffer.BlockCopy(subkey, 0, output, 13 + SaltSize, SubkeySize);

        return Convert.ToBase64String(output);
    }

    public bool VerifyPassword(string hashedPassword, string providedPassword)
    {
        if (string.IsNullOrWhiteSpace(hashedPassword) || string.IsNullOrWhiteSpace(providedPassword))
        {
            return false;
        }

        try
        {
            byte[] decoded = Convert.FromBase64String(hashedPassword);
            if (decoded.Length != 1 + 4 + 4 + 4 + SaltSize + SubkeySize || decoded[0] != 0x01)
            {
                return false;
            }

            int iterations = (int)BinaryPrimitives.ReadUInt32BigEndian(decoded.AsSpan(5, 4));
            int saltLength = (int)BinaryPrimitives.ReadUInt32BigEndian(decoded.AsSpan(9, 4));
            if (saltLength != SaltSize) return false;

            byte[] salt = new byte[SaltSize];
            Buffer.BlockCopy(decoded, 13, salt, 0, SaltSize);

            byte[] expectedSubkey = new byte[SubkeySize];
            Buffer.BlockCopy(decoded, 13 + SaltSize, expectedSubkey, 0, SubkeySize);

            byte[] actualSubkey = Rfc2898DeriveBytes.Pbkdf2(
                providedPassword,
                salt,
                iterations,
                HashAlgorithmName.SHA256,
                SubkeySize);

            return CryptographicOperations.FixedTimeEquals(actualSubkey, expectedSubkey);
        }
        catch
        {
            return false;
        }
    }
}
