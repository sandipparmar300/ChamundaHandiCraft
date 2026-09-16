using System.Data;
using Categories.Domain.IServices;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Dapper;
using Microsoft.Data.SqlClient;

namespace Categories.Infrastructure.Repositories;

public class MenuRepository : IMenuRepository
{
    private readonly string _connectionString;

    public MenuRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<PagedResult<MenuGridItem>> GetGridAsync(DataTableRequest request, string? location = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@SearchText", request.Search);
        parameters.Add("@Location", location);
        parameters.Add("@SortColumn", string.IsNullOrWhiteSpace(request.SortBy) ? "SortOrder" : request.SortBy);
        parameters.Add("@SortOrder", request.SortDescending ? "DESC" : "ASC");
        parameters.Add("@PageSize", request.PageSize <= 0 ? 25 : request.PageSize);
        parameters.Add("@PageIndex", request.Page <= 0 ? 1 : request.Page);
        parameters.Add("@TotalRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@TotalFilteredRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);

        var items = (await connection.QueryAsync<MenuGridItem>(
            "dbo.usp_Menu_GridList",
            parameters,
            commandType: CommandType.StoredProcedure)).AsList();

        int total = parameters.Get<int>("@TotalRecords");
        int totalFiltered = parameters.Get<int>("@TotalFilteredRecords");

        return new PagedResult<MenuGridItem>
        {
            Items = items,
            TotalCount = totalFiltered,
            Page = request.Page <= 0 ? 1 : request.Page,
            PageSize = request.PageSize <= 0 ? 25 : request.PageSize
        };
    }

    public async Task<MenuGridItem?> GetByIdAsync(int id, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<MenuGridItem>(
            "dbo.usp_Menu_GetById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> SaveAsync(MenuGridItem request, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Id", request.Id);
        parameters.Add("@ParentId", request.ParentId);
        parameters.Add("@Title", request.Title);
        parameters.Add("@Location", request.Location);
        parameters.Add("@Url", request.Url);
        parameters.Add("@LinkType", request.LinkType);
        parameters.Add("@LinkEntityId", request.LinkEntityId);
        parameters.Add("@IconName", request.IconName);
        parameters.Add("@Badge", request.Badge);
        parameters.Add("@Description", request.Description);
        parameters.Add("@SortOrder", request.SortOrder);
        parameters.Add("@OpensInNewTab", request.OpensInNewTab);
        parameters.Add("@IsActive", request.IsActive);
        parameters.Add("@AdminUserId", adminUserId);

        return await connection.ExecuteScalarAsync<int>(
            "dbo.usp_Menu_Save",
            parameters,
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "dbo.usp_Menu_Delete",
            new { Id = id, AdminUserId = adminUserId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "dbo.usp_Menu_UpdateStatus",
            new { Id = request.Id, IsActive = (request.Status == 1), AdminUserId = adminUserId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<List<IdNamePair>> GetLookupAsync(string? location = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return (await connection.QueryAsync<IdNamePair>(
            "dbo.usp_Menu_Lookup",
            new { Location = location },
            commandType: CommandType.StoredProcedure)).AsList();
    }
}
