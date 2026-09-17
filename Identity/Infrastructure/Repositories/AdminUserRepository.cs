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

    public async Task<ChamundaHandicraft.Helper.ViewModel.Common.PagedResult<ChamundaHandicraft.Helper.ViewModel.Admin.AdminUserGridItem>> GetGridAsync(
        ChamundaHandicraft.Helper.ViewModel.Common.DataTableRequest request, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@SearchText", request.Search);
        parameters.Add("@SortColumn", string.IsNullOrWhiteSpace(request.SortBy) ? "CreatedAt" : request.SortBy);
        parameters.Add("@SortOrder", request.SortDescending ? "DESC" : "ASC");
        parameters.Add("@PageSize", request.PageSize <= 0 ? 25 : request.PageSize);
        parameters.Add("@PageIndex", request.Page <= 0 ? 1 : request.Page);
        parameters.Add("@TotalRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@TotalFilteredRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);

        var items = (await connection.QueryAsync<ChamundaHandicraft.Helper.ViewModel.Admin.AdminUserGridItem>(
            "dbo.usp_AdminUser_GridList",
            parameters,
            commandType: CommandType.StoredProcedure)).AsList();

        int total = parameters.Get<int>("@TotalRecords");
        int totalFiltered = parameters.Get<int>("@TotalFilteredRecords");

        return new ChamundaHandicraft.Helper.ViewModel.Common.PagedResult<ChamundaHandicraft.Helper.ViewModel.Admin.AdminUserGridItem>
        {
            Items = items,
            TotalCount = totalFiltered,
            Page = request.Page <= 0 ? 1 : request.Page,
            PageSize = request.PageSize <= 0 ? 25 : request.PageSize
        };
    }

    public async Task<ChamundaHandicraft.Helper.ViewModel.Admin.AdminUserSaveRequest?> GetByIdAsync(int id, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var user = await connection.QueryFirstOrDefaultAsync<ChamundaHandicraft.Helper.ViewModel.Admin.AdminUserSaveRequest>(
            "dbo.usp_AdminUser_GetById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);

        if (user != null && !string.IsNullOrWhiteSpace(user.FullName))
        {
            var parts = user.FullName.Split(' ', 2, StringSplitOptions.RemoveEmptyEntries);
            user.FirstName = parts.Length > 0 ? parts[0] : "";
            user.LastName = parts.Length > 1 ? parts[1] : "";
            user.Username = user.Email;
        }

        return user;
    }

    public async Task<int> SaveAsync(ChamundaHandicraft.Helper.ViewModel.Admin.AdminUserSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var fullName = !string.IsNullOrWhiteSpace(request.FullName)
            ? request.FullName.Trim()
            : $"{request.FirstName} {request.LastName}".Trim();

        return await connection.ExecuteScalarAsync<int>(
            "dbo.usp_AdminUser_Save",
            new
            {
                request.Id,
                FullName = fullName,
                request.Email,
                Phone = request.Mobile,
                PasswordHash = request.Password, // Caller passes pre-hashed password if changing
                request.PhotoUrl,
                Timezone = string.IsNullOrWhiteSpace(request.TimeZone) ? "Asia/Kolkata" : request.TimeZone,
                request.RoleId,
                request.IsActive,
                AdminUserId = adminUserId
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "dbo.usp_AdminUser_Delete",
            new { Id = id, AdminUserId = adminUserId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateStatusAsync(int id, bool isActive, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "dbo.usp_AdminUser_UpdateStatus",
            new { Id = id, IsActive = isActive, AdminUserId = adminUserId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> ChangePasswordAsync(int id, string passwordHash, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "dbo.usp_AdminUser_ChangePassword",
            new { Id = id, PasswordHash = passwordHash, AdminUserId = adminUserId },
            commandType: CommandType.StoredProcedure);
    }
}
