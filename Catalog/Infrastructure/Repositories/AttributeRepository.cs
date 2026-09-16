using System.Data;
using System.Text.Json;
using Catalog.Domain.IServices;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Dapper;
using Microsoft.Data.SqlClient;

namespace Catalog.Infrastructure.Repositories;

public class AttributeRepository : IAttributeRepository
{
    private readonly string _connectionString;

    public AttributeRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<PagedResult<AttributeGridItem>> GetGridAsync(DataTableRequest request, CancellationToken ct = default)
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

        var items = (await connection.QueryAsync<AttributeGridItem>(
            "dbo.usp_Attribute_GridList",
            parameters,
            commandType: CommandType.StoredProcedure)).AsList();

        int total = parameters.Get<int>("@TotalRecords");
        int totalFiltered = parameters.Get<int>("@TotalFilteredRecords");

        return new PagedResult<AttributeGridItem>
        {
            Items = items,
            TotalCount = totalFiltered,
            Page = request.Page <= 0 ? 1 : request.Page,
            PageSize = request.PageSize <= 0 ? 25 : request.PageSize
        };
    }

    public async Task<AttributeSaveRequest?> GetByIdAsync(int id, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        using var multi = await connection.QueryMultipleAsync(
            "dbo.usp_Attribute_GetById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);

        var attribute = await multi.ReadFirstOrDefaultAsync<AttributeSaveRequest>();
        if (attribute is null) return null;

        var values = (await multi.ReadAsync<AttributeValueSaveRequest>()).AsList();
        attribute.Values = values;
        return attribute;
    }

    public async Task<int> SaveAsync(AttributeSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var valuesJson = request.Values is { Count: > 0 }
            ? JsonSerializer.Serialize(request.Values)
            : null;

        return await connection.ExecuteScalarAsync<int>(
            "dbo.usp_Attribute_Save",
            new
            {
                request.Id,
                request.AttributeName,
                request.AttributeCode,
                request.DisplayType,
                request.IsFilterable,
                request.IsRequired,
                request.IsVariantDefining,
                request.SortOrder,
                request.IsActive,
                ValuesJson = valuesJson,
                AdminUserId = adminUserId
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "dbo.usp_Attribute_Delete",
            new { Id = id, AdminUserId = adminUserId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateStatusAsync(int id, bool isActive, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "dbo.usp_Attribute_UpdateStatus",
            new { Id = id, IsActive = isActive, AdminUserId = adminUserId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<List<IdNamePair>> GetLookupAsync(CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return (await connection.QueryAsync<IdNamePair>(
            "dbo.usp_Attribute_GetLookup",
            commandType: CommandType.StoredProcedure)).AsList();
    }
}
