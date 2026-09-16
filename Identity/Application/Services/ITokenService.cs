using System.Security.Claims;
using Identity.Domain.Entities;

namespace Identity.Application.Services;

/// <summary>
/// Token generation contract for access and refresh tokens.
/// </summary>
public interface ITokenService
{
    (string Token, DateTime ExpiresAt) GenerateAccessToken(
        AdminUser user,
        IEnumerable<UserRoleItem> roles,
        IEnumerable<string> permissions);

    (string RefreshToken, string RefreshTokenHash, DateTime ExpiresAt) GenerateRefreshToken();

    string ComputeSha256Hash(string input);
}
