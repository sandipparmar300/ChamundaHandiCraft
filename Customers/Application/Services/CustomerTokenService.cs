using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Customers.Domain.Entities;
using Customers.Domain.IServices;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace Customers.Application.Services;

public class CustomerTokenService : ICustomerTokenService
{
    private readonly IConfiguration _configuration;

    public CustomerTokenService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public (string Token, DateTime ExpiresAt) GenerateAccessToken(Customer customer)
    {
        var jwtKey = _configuration["Jwt:JwtKey"] ?? "ChamundaHandicraftSuperSecureLongKey2026!#$";
        var issuer = _configuration["Jwt:JwtIssuer"] ?? "ChamundaHandicraft.API";
        var audience = _configuration["Jwt:JwtAudience"] ?? "ChamundaHandicraft.Clients";
        var days = int.TryParse(_configuration["Jwt:CustomerTokenDays"], out int d) ? d : 30;

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var expiresAt = DateTime.UtcNow.AddDays(days);

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, customer.Id.ToString()),
            new(ClaimTypes.Name, customer.FullName),
            new(ClaimTypes.Role, "Customer"),
            new("tier", customer.RewardTier),
            new("points", customer.RewardPointBalance.ToString())
        };

        if (!string.IsNullOrWhiteSpace(customer.Email))
        {
            claims.Add(new Claim(ClaimTypes.Email, customer.Email));
        }

        if (!string.IsNullOrWhiteSpace(customer.Phone))
        {
            claims.Add(new Claim(ClaimTypes.MobilePhone, customer.Phone));
        }

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = expiresAt,
            Issuer = issuer,
            Audience = audience,
            SigningCredentials = credentials
        };

        var handler = new JwtSecurityTokenHandler();
        var token = handler.CreateToken(tokenDescriptor);

        return (handler.WriteToken(token), expiresAt);
    }
}
