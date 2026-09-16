using Identity.Domain.Entities;

namespace Identity.Domain.IServices;

/// <summary>
/// Repository contract for managing active Admin refresh tokens and sessions.
/// </summary>
public interface IAdminSessionRepository
{
    Task<long> CreateSessionAsync(
        int adminUserId,
        string refreshTokenHash,
        DateTime expiresAt,
        string? ipAddress,
        string? userAgent);

    Task<bool> RevokeSessionAsync(string refreshTokenHash, string? reason);

    Task<AdminSession?> GetSessionByHashAsync(string refreshTokenHash);
}
