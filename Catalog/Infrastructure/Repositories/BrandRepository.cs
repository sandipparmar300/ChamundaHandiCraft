using System.Data;
using Catalog.Domain.IServices;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Dapper;
using Microsoft.Data.SqlClient;

namespace Catalog.Infrastructure.Repositories;

public class BrandRepository : IBrandRepository
{
    private readonly string _connectionString;

    public BrandRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<PagedResult<BrandGridItem>> GetGridAsync(DataTableRequest request, CancellationToken ct = default)
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

        var items = (await connection.QueryAsync<BrandGridItem>(
            "dbo.usp_Brand_GridList",
            parameters,
            commandType: CommandType.StoredProcedure)).AsList();

        int total = parameters.Get<int>("@TotalRecords");
        int totalFiltered = parameters.Get<int>("@TotalFilteredRecords");

        return new PagedResult<BrandGridItem>
        {
            Items = items,
            TotalCount = totalFiltered,
            Page = request.Page <= 0 ? 1 : request.Page,
            PageSize = request.PageSize <= 0 ? 25 : request.PageSize
        };
    }

    public async Task<BrandSaveRequest?> GetByIdAsync(int id, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<BrandSaveRequest>(
            "dbo.usp_Brand_GetById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> SaveAsync(BrandSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "dbo.usp_Brand_Save",
            new
            {
                request.Id,
                request.BrandName,
                request.Slug,
                request.LogoUrl,
                request.Description,
                request.IsFeatured,
                request.SortOrder,
                request.IsActive,
                AdminUserId = adminUserId
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "dbo.usp_Brand_Delete",
            new { Id = id, AdminUserId = adminUserId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateStatusAsync(int id, bool isActive, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "dbo.usp_Brand_UpdateStatus",
            new { Id = id, IsActive = isActive, AdminUserId = adminUserId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<List<IdNamePair>> GetLookupAsync(CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return (await connection.QueryAsync<IdNamePair>(
            "dbo.usp_Brand_GetLookup",
            commandType: CommandType.StoredProcedure)).AsList();
    }
}
