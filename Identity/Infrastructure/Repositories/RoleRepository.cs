using System.Data;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Dapper;
using Identity.Domain.IServices;
using Microsoft.Data.SqlClient;

namespace Identity.Infrastructure.Repositories;

public class RoleRepository : IRoleRepository
{
    private readonly string _connectionString;

    public RoleRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<PagedResult<RoleGridItem>> GetGridAsync(DataTableRequest request, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@SearchText", request.Search);
        parameters.Add("@SortColumn", string.IsNullOrWhiteSpace(request.SortBy) ? "SortOrder" : request.SortBy);
        parameters.Add("@SortOrder", request.SortDescending ? "DESC" : "ASC");
        parameters.Add("@PageSize", request.PageSize <= 0 ? 25 : request.PageSize);
        parameters.Add("@PageIndex", request.Page <= 0 ? 1 : request.Page);
        parameters.Add("@TotalRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@TotalFilteredRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);

        var items = (await connection.QueryAsync<RoleGridItem>(
            "dbo.usp_Role_GridList",
            parameters,
            commandType: CommandType.StoredProcedure)).AsList();

        int total = parameters.Get<int>("@TotalRecords");
        int totalFiltered = parameters.Get<int>("@TotalFilteredRecords");

        return new PagedResult<RoleGridItem>
        {
            Items = items,
            TotalCount = totalFiltered,
            Page = request.Page <= 0 ? 1 : request.Page,
            PageSize = request.PageSize <= 0 ? 25 : request.PageSize
        };
    }

    public async Task<RoleSaveRequest?> GetByIdAsync(int id, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        using var multi = await connection.QueryMultipleAsync(
            "dbo.usp_Role_GetById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);

        var role = await multi.ReadFirstOrDefaultAsync<RoleSaveRequest>();
        if (role != null)
        {
            var permissionIds = (await multi.ReadAsync<int>()).AsList();
            role.PermissionIds = permissionIds;
            role.PermissionCount = permissionIds.Count;
        }

        return role;
    }

    public async Task<int> SaveAsync(RoleSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var permissionCsv = request.PermissionIds != null && request.PermissionIds.Any()
            ? string.Join(",", request.PermissionIds)
            : string.Empty;

        return await connection.ExecuteScalarAsync<int>(
            "dbo.usp_Role_Save",
            new
            {
                request.Id,
                request.RoleName,
                request.RoleKey,
                request.Description,
                request.IsActive,
                PermissionIdsCsv = permissionCsv,
                AdminUserId = adminUserId
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "dbo.usp_Role_Delete",
            new { Id = id, AdminUserId = adminUserId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateStatusAsync(int id, bool isActive, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "dbo.usp_Role_UpdateStatus",
            new { Id = id, IsActive = isActive, AdminUserId = adminUserId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<List<IdNamePair>> GetLookupAsync(CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return (await connection.QueryAsync<IdNamePair>(
            "dbo.usp_Role_GetLookup",
            commandType: CommandType.StoredProcedure)).AsList();
    }
}
