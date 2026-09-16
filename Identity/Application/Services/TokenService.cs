using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Identity.Domain.Entities;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace Identity.Application.Services;

/// <summary>
/// Generates JWT access tokens and cryptographically random refresh tokens.
/// </summary>
public class TokenService : ITokenService
{
    private readonly IConfiguration _configuration;

    public TokenService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public (string Token, DateTime ExpiresAt) GenerateAccessToken(
        AdminUser user,
        IEnumerable<UserRoleItem> roles,
        IEnumerable<string> permissions)
    {
        var jwtKey = _configuration["Jwt:JwtKey"] ?? throw new InvalidOperationException("Jwt:JwtKey is not configured.");
        var issuer = _configuration["Jwt:JwtIssuer"] ?? "ChamundaHandicraft.API";
        var audience = _configuration["Jwt:JwtAudience"] ?? "ChamundaHandicraft.Clients";
        var minutes = int.TryParse(_configuration["Jwt:AccessTokenMinutes"], out int m) ? m : 30;

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var expiresAt = DateTime.UtcNow.AddMinutes(minutes);

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(ClaimTypes.Name, user.FullName),
            new(ClaimTypes.Email, user.Email),
            new("timezone", user.Timezone)
        };

        if (!string.IsNullOrWhiteSpace(user.Phone))
        {
            claims.Add(new Claim(ClaimTypes.MobilePhone, user.Phone));
        }

        foreach (var role in roles)
        {
            claims.Add(new Claim(ClaimTypes.Role, role.RoleName));
            claims.Add(new Claim("role_key", role.RoleKey));
        }

        foreach (var permission in permissions)
        {
            claims.Add(new Claim("permission", permission));
        }

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = expiresAt,
            Issuer = issuer,
            Audience = audience,
            SigningCredentials = credentials
        };

        var tokenHandler = new JwtSecurityTokenHandler();
        var token = tokenHandler.CreateToken(tokenDescriptor);
        return (tokenHandler.WriteToken(token), expiresAt);
    }

    public (string RefreshToken, string RefreshTokenHash, DateTime ExpiresAt) GenerateRefreshToken()
    {
        var days = int.TryParse(_configuration["Jwt:RefreshTokenDays"], out int d) ? d : 14;
        var expiresAt = DateTime.UtcNow.AddDays(days);

        byte[] randomBytes = new byte[32];
        RandomNumberGenerator.Fill(randomBytes);
        string token = Convert.ToHexString(randomBytes).ToLowerInvariant();
        string hash = ComputeSha256Hash(token);

        return (token, hash, expiresAt);
    }

    public string ComputeSha256Hash(string input)
    {
        byte[] bytes = SHA256.HashData(Encoding.UTF8.GetBytes(input));
        return Convert.ToHexString(bytes).ToLowerInvariant();
    }
}
