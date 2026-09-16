using System.Data;
using Catalog.Domain.IServices;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Dapper;
using Microsoft.Data.SqlClient;

namespace Catalog.Infrastructure.Repositories;

public class ArtisanRepository : IArtisanRepository
{
    private readonly string _connectionString;

    public ArtisanRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<PagedResult<ArtisanGridItem>> GetGridAsync(DataTableRequest request, CancellationToken ct = default)
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

        var items = (await connection.QueryAsync<ArtisanGridItem>(
            "dbo.usp_Artisan_GridList",
            parameters,
            commandType: CommandType.StoredProcedure)).AsList();

        int total = parameters.Get<int>("@TotalRecords");
        int totalFiltered = parameters.Get<int>("@TotalFilteredRecords");

        return new PagedResult<ArtisanGridItem>
        {
            Items = items,
            TotalCount = totalFiltered,
            Page = request.Page <= 0 ? 1 : request.Page,
            PageSize = request.PageSize <= 0 ? 25 : request.PageSize
        };
    }

    public async Task<ArtisanSaveRequest?> GetByIdAsync(int id, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<ArtisanSaveRequest>(
            "dbo.usp_Artisan_GetById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> SaveAsync(ArtisanSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "dbo.usp_Artisan_Save",
            new
            {
                request.Id,
                request.Name,
                request.Slug,
                request.Craft,
                request.Cluster,
                request.Story,
                request.PhotoUrl,
                request.CoverUrl,
                request.VideoUrl,
                request.WorkingSinceYear,
                request.PartnerSinceYear,
                request.ApprenticesTrained,
                request.IsGiTagged,
                request.IsActive,
                AdminUserId = adminUserId
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "dbo.usp_Artisan_Delete",
            new { Id = id, AdminUserId = adminUserId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateStatusAsync(int id, bool isActive, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "dbo.usp_Artisan_UpdateStatus",
            new { Id = id, IsActive = isActive, AdminUserId = adminUserId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<List<IdNamePair>> GetLookupAsync(CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return (await connection.QueryAsync<IdNamePair>(
            "dbo.usp_Artisan_GetLookup",
            commandType: CommandType.StoredProcedure)).AsList();
    }
}
