using System.Data;
using Dapper;
using Identity.Domain.Entities;
using Identity.Domain.IServices;
using Microsoft.Data.SqlClient;

namespace Identity.Infrastructure.Repositories;

/// <summary>
/// Dapper implementation of IPasswordResetRepository calling stored procedures.
/// </summary>
public class PasswordResetRepository : IPasswordResetRepository
{
    private readonly string _connectionString;

    public PasswordResetRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<long> CreateResetTokenAsync(
        int adminUserId,
        string token,
        DateTime expiresAt,
        string? ipAddress,
        string? userAgent)
    {
        using var connection = CreateConnection();
        return await connection.ExecuteScalarAsync<long>(
            "dbo.usp_AdminUser_CreatePasswordResetToken",
            new
            {
                AdminUserId = adminUserId,
                Token = token,
                ExpiresAt = expiresAt,
                IpAddress = ipAddress,
                UserAgent = userAgent
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<ValidatedPasswordReset?> ValidateResetTokenAsync(string token)
    {
        using var connection = CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<ValidatedPasswordReset>(
            "dbo.usp_AdminUser_ValidatePasswordResetToken",
            new { Token = token },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<(bool Success, string Message)> ResetPasswordAsync(
        string token,
        string newPasswordHash,
        string? ipAddress)
    {
        using var connection = CreateConnection();
        var result = await connection.QueryFirstOrDefaultAsync<ResetResult>(
            "dbo.usp_AdminUser_ResetPassword",
            new
            {
                Token = token,
                NewPasswordHash = newPasswordHash,
                IpAddress = ipAddress
            },
            commandType: CommandType.StoredProcedure);

        return result is not null && result.Success
            ? (true, result.Message)
            : (false, result?.Message ?? "Failed to reset password.");
    }

    private class ResetResult
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
    }
}
