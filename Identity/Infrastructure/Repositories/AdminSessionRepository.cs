using System.Data;
using Dapper;
using Identity.Domain.Entities;
using Identity.Domain.IServices;
using Microsoft.Data.SqlClient;

namespace Identity.Infrastructure.Repositories;

/// <summary>
/// Dapper implementation of IAdminSessionRepository calling stored procedures.
/// </summary>
public class AdminSessionRepository : IAdminSessionRepository
{
    private readonly string _connectionString;

    public AdminSessionRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<long> CreateSessionAsync(
        int adminUserId,
        string refreshTokenHash,
        DateTime expiresAt,
        string? ipAddress,
        string? userAgent)
    {
        using var connection = CreateConnection();
        return await connection.ExecuteScalarAsync<long>(
            "dbo.usp_AdminSession_Create",
            new
            {
                AdminUserId = adminUserId,
                RefreshTokenHash = refreshTokenHash,
                ExpiresAt = expiresAt,
                IpAddress = ipAddress,
                UserAgent = userAgent
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> RevokeSessionAsync(string refreshTokenHash, string? reason)
    {
        using var connection = CreateConnection();
        var affected = await connection.ExecuteAsync(
            "dbo.usp_AdminSession_Revoke",
            new
            {
                RefreshTokenHash = refreshTokenHash,
                RevokedReason = reason
            },
            commandType: CommandType.StoredProcedure);

        return affected > 0;
    }

    public async Task<AdminSession?> GetSessionByHashAsync(string refreshTokenHash)
    {
        using var connection = CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<AdminSession>(
            "dbo.usp_AdminSession_GetByHash",
            new { RefreshTokenHash = refreshTokenHash },
            commandType: CommandType.StoredProcedure);
    }
}
