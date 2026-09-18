using System.Data;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Dapper;
using Inventory.Domain.IServices;
using Microsoft.Data.SqlClient;

namespace Inventory.Infrastructure.Repositories;

public class StockTakeRepository : IStockTakeRepository
{
    private readonly string _connectionString;

    public StockTakeRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<PagedResult<StockTakeGridItem>> GetGridAsync(DataTableRequest request, int? warehouseId = null, string? status = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@SearchText", request.Search);
        parameters.Add("@WarehouseId", warehouseId);
        parameters.Add("@Status", status);
        parameters.Add("@SortColumn", string.IsNullOrWhiteSpace(request.SortBy) ? "StartedOn" : request.SortBy);
        parameters.Add("@SortOrder", request.SortDescending ? "DESC" : "ASC");
        parameters.Add("@PageSize", request.PageSize <= 0 ? 25 : request.PageSize);
        parameters.Add("@PageIndex", request.Page <= 0 ? 1 : request.Page);
        parameters.Add("@TotalRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@TotalFilteredRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);

        var items = (await connection.QueryAsync<dynamic>(
            "dbo.usp_StockTake_GridList",
            parameters,
            commandType: CommandType.StoredProcedure)).Select(d => new StockTakeGridItem
            {
                Id = (int)d.Id,
                StockTakeNumber = (string)d.StockTakeNumber,
                WarehouseId = (int)(d.WarehouseId ?? 0),
                WarehouseName = (string)d.WarehouseName,
                StartedOn = (DateTime)d.StartedOn,
                CompletedOn = (DateTime?)d.CompletedOn,
                SkusCounted = (int)d.SkusCounted,
                DiscrepancyCount = (int)d.DiscrepancyCount,
                DiscrepancyValue = (decimal)d.DiscrepancyValue,
                Status = (string)d.Status,
                Note = (string?)d.Note,
                CreatedBy = (string)d.CreatedBy,
                CreatedOn = (DateTime)d.CreatedAt
            }).AsList();

        var totalFiltered = parameters.Get<int>("@TotalFilteredRecords");

        return new PagedResult<StockTakeGridItem>(items, totalFiltered, request.Page <= 0 ? 1 : request.Page, request.PageSize <= 0 ? 25 : request.PageSize);
    }

    public async Task<StockTakeGridItem?> GetByIdAsync(int id, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var data = await connection.QueryFirstOrDefaultAsync<dynamic>(
            "dbo.usp_StockTake_GetById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);

        if (data == null) return null;

        return new StockTakeGridItem
        {
            Id = (int)data.Id,
            StockTakeNumber = (string)data.StockTakeNumber,
            WarehouseId = (int)(data.WarehouseId ?? 0),
            WarehouseName = (string)data.WarehouseName,
            StartedOn = (DateTime)data.StartedOn,
            CompletedOn = (DateTime?)data.CompletedOn,
            SkusCounted = (int)data.SkusCounted,
            DiscrepancyCount = (int)data.DiscrepancyCount,
            DiscrepancyValue = (decimal)data.DiscrepancyValue,
            Status = (string)data.Status,
            Note = (string?)data.Note,
            CreatedBy = (string)data.CreatedBy,
            CreatedOn = (DateTime)data.CreatedAt
        };
    }

    public async Task<int> SaveAsync(StockTakeGridItem request, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Id", request.Id);
        parameters.Add("@StockTakeNumber", request.StockTakeNumber);
        parameters.Add("@WarehouseId", request.WarehouseId > 0 ? request.WarehouseId : (object)DBNull.Value);
        parameters.Add("@StartedOn", request.StartedOn == default ? DateTime.UtcNow : request.StartedOn);
        parameters.Add("@CompletedOn", request.CompletedOn);
        parameters.Add("@Status", request.Status);
        parameters.Add("@SkusCounted", request.SkusCounted);
        parameters.Add("@DiscrepancyCount", request.DiscrepancyCount);
        parameters.Add("@DiscrepancyValue", request.DiscrepancyValue);
        parameters.Add("@Note", request.Note);
        parameters.Add("@LoggedInUserId", adminUserId);
        parameters.Add("@NewId", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await connection.ExecuteAsync("dbo.usp_StockTake_Save", parameters, commandType: CommandType.StoredProcedure);

        var errorMessage = parameters.Get<string?>("@ErrorMessage");
        if (!string.IsNullOrWhiteSpace(errorMessage))
        {
            throw new InvalidOperationException(errorMessage);
        }

        return parameters.Get<int>("@NewId");
    }

    public async Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Id", id);
        parameters.Add("@LoggedInUserId", adminUserId);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await connection.ExecuteAsync("dbo.usp_StockTake_Delete", parameters, commandType: CommandType.StoredProcedure);

        var errorMessage = parameters.Get<string?>("@ErrorMessage");
        if (!string.IsNullOrWhiteSpace(errorMessage))
        {
            throw new InvalidOperationException(errorMessage);
        }

        return true;
    }

    public async Task<bool> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Id", request.Id);
        parameters.Add("@NewStatus", request.Status == 1 ? "In Progress" : (request.Status == 2 ? "Completed" : "Cancelled"));
        parameters.Add("@LoggedInUserId", adminUserId);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await connection.ExecuteAsync("dbo.usp_StockTake_UpdateStatus", parameters, commandType: CommandType.StoredProcedure);

        var errorMessage = parameters.Get<string?>("@ErrorMessage");
        if (!string.IsNullOrWhiteSpace(errorMessage))
        {
            throw new InvalidOperationException(errorMessage);
        }

        return true;
    }
}
