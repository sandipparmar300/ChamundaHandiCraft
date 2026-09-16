using System.Data;
using Dapper;
using Identity.Domain.Entities;
using Identity.Domain.IServices;
using Microsoft.Data.SqlClient;

namespace Identity.Infrastructure.Repositories;

/// <summary>
/// Dapper implementation of IAdminUserRepository calling stored procedures.
/// </summary>
public class AdminUserRepository : IAdminUserRepository
{
    private readonly string _connectionString;

    public AdminUserRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<(AdminUser? User, List<UserRoleItem> Roles, List<string> Permissions)> GetByIdentifierAsync(string identifier)
    {
        using var connection = CreateConnection();
        using var multi = await connection.QueryMultipleAsync(
            "dbo.usp_AdminUser_GetByIdentifier",
            new { Identifier = identifier },
            commandType: CommandType.StoredProcedure);

        var user = await multi.ReadFirstOrDefaultAsync<AdminUser>();
        if (user is null)
        {
            return (null, new List<UserRoleItem>(), new List<string>());
        }

        var roles = (await multi.ReadAsync<UserRoleItem>()).AsList();
        var permissions = (await multi.ReadAsync<string>()).AsList();

        return (user, roles, permissions);
    }

    public async Task RecordLoginAttemptAsync(
        int? adminUserId,
        string? attemptedEmail,
        bool isSuccess,
        string? failureReason,
        string? ipAddress,
        string? userAgent,
        int maxFailedAttempts = 5,
        int lockoutMinutes = 15)
    {
        using var connection = CreateConnection();
        await connection.ExecuteAsync(
            "dbo.usp_AdminUser_RecordLoginAttempt",
            new
            {
                AdminUserId = adminUserId,
                AttemptedEmail = attemptedEmail,
                IsSuccess = isSuccess,
                FailureReason = failureReason,
                IpAddress = ipAddress,
                UserAgent = userAgent,
                MaxFailedAttempts = maxFailedAttempts,
                LockoutMinutes = lockoutMinutes
            },
            commandType: CommandType.StoredProcedure);
    }
}
