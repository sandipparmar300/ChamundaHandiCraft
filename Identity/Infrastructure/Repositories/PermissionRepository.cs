using System.Data;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using Dapper;
using Identity.Domain.IServices;
using Microsoft.Data.SqlClient;

namespace Identity.Infrastructure.Repositories;

public class PermissionRepository : IPermissionRepository
{
    private readonly string _connectionString;

    public PermissionRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<List<PermissionMatrixItem>> GetMatrixAsync(int? roleId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return (await connection.QueryAsync<PermissionMatrixItem>(
            "dbo.usp_Permission_GetMatrix",
            new { RoleId = roleId },
            commandType: CommandType.StoredProcedure)).AsList();
    }

    public async Task<bool> SaveRolePermissionsAsync(int roleId, List<int> permissionIds, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var csv = permissionIds != null && permissionIds.Any()
            ? string.Join(",", permissionIds)
            : string.Empty;

        return await connection.ExecuteScalarAsync<bool>(
            "dbo.usp_Role_SavePermissions",
            new
            {
                RoleId = roleId,
                PermissionIdsCsv = csv,
                AdminUserId = adminUserId
            },
            commandType: CommandType.StoredProcedure);
    }
}
