using System.Buffers.Binary;
using System.Security.Cryptography;

namespace Identity.Application.Services;

/// <summary>
/// Implements PBKDF2-HMAC-SHA256 password hashing.
/// Supports both ASP.NET Core Identity v3 binary envelope (AQAAAA...) and custom delimited format.
/// </summary>
public class PasswordHasher : IPasswordHasher
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

        // Standard ASP.NET Core Identity v3 format:
        // byte 0: 0x01
        // bytes 1-4: PRF (1 = HMACSHA256) (big endian)
        // bytes 5-8: Iterations (100,000) (big endian)
        // bytes 9-12: Salt size (16) (big endian)
        // bytes 13-28: Salt
        // bytes 29-60: Subkey
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

        // 1. Try custom delimited format: iterations.saltBase64.hashBase64
        if (hashedPassword.Contains('.'))
        {
            var parts = hashedPassword.Split('.');
            if (parts.Length == 3 && int.TryParse(parts[0], out int iters))
            {
                try
                {
                    byte[] salt = Convert.FromBase64String(parts[1]);
                    byte[] expectedSubkey = Convert.FromBase64String(parts[2]);

                    byte[] actualSubkey = Rfc2898DeriveBytes.Pbkdf2(
                        providedPassword,
                        salt,
                        iters,
                        HashAlgorithmName.SHA256,
                        expectedSubkey.Length);

                    return CryptographicOperations.FixedTimeEquals(expectedSubkey, actualSubkey);
                }
                catch
                {
                    return false;
                }
            }
        }

        // 2. Standard ASP.NET Core Identity v3 binary envelope
        try
        {
            byte[] decoded = Convert.FromBase64String(hashedPassword);
            if (decoded.Length < 1 + 4 + 4 + 4 + SaltSize + SubkeySize)
            {
                return false;
            }

            if (decoded[0] != 0x01)
            {
                return false;
            }

            uint prf = BinaryPrimitives.ReadUInt32BigEndian(decoded.AsSpan(1, 4));
            if (prf != 1) // HMACSHA256
            {
                return false;
            }

            uint iterCount = BinaryPrimitives.ReadUInt32BigEndian(decoded.AsSpan(5, 4));
            uint saltLength = BinaryPrimitives.ReadUInt32BigEndian(decoded.AsSpan(9, 4));

            if (saltLength != SaltSize || decoded.Length != 1 + 4 + 4 + 4 + saltLength + SubkeySize)
            {
                return false;
            }

            byte[] salt = new byte[saltLength];
            Buffer.BlockCopy(decoded, 13, salt, 0, (int)saltLength);

            byte[] expectedSubkey = new byte[SubkeySize];
            Buffer.BlockCopy(decoded, 13 + (int)saltLength, expectedSubkey, 0, SubkeySize);

            byte[] actualSubkey = Rfc2898DeriveBytes.Pbkdf2(
                providedPassword,
                salt,
                (int)iterCount,
                HashAlgorithmName.SHA256,
                SubkeySize);

            return CryptographicOperations.FixedTimeEquals(expectedSubkey, actualSubkey);
        }
        catch
        {
            return false;
        }
    }
}
