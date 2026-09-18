using System.Data;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Dapper;
using Inventory.Domain.IServices;
using Microsoft.Data.SqlClient;

namespace Inventory.Infrastructure.Repositories;

public class StockAdjustmentRepository : IStockAdjustmentRepository
{
    private readonly string _connectionString;

    public StockAdjustmentRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<PagedResult<StockAdjustmentGridItem>> GetGridAsync(DataTableRequest request, int? warehouseId = null, int? reasonCodeId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@SearchText", request.Search);
        parameters.Add("@WarehouseId", warehouseId);
        parameters.Add("@ReasonCodeId", reasonCodeId);
        parameters.Add("@SortColumn", string.IsNullOrWhiteSpace(request.SortBy) ? "AdjustedOn" : request.SortBy);
        parameters.Add("@SortOrder", request.SortDescending ? "DESC" : "DESC"); // Default recent first
        parameters.Add("@PageSize", request.PageSize <= 0 ? 25 : request.PageSize);
        parameters.Add("@PageIndex", request.Page <= 0 ? 1 : request.Page);
        parameters.Add("@TotalRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@TotalFilteredRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);

        var items = (await connection.QueryAsync<StockAdjustmentGridItem>(
            "dbo.usp_StockAdjustment_GridList",
            parameters,
            commandType: CommandType.StoredProcedure)).AsList();

        var totalRecords = parameters.Get<int>("@TotalRecords");
        var totalFiltered = parameters.Get<int>("@TotalFilteredRecords");

        return new PagedResult<StockAdjustmentGridItem>(items, totalFiltered, request.Page <= 0 ? 1 : request.Page, request.PageSize <= 0 ? 25 : request.PageSize);
    }

    public async Task<StockAdjustmentDetailViewModel?> GetByIdAsync(int id, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var data = await connection.QueryFirstOrDefaultAsync<dynamic>(
            "dbo.usp_StockAdjustment_GetById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);

        if (data == null) return null;

        return new StockAdjustmentDetailViewModel
        {
            Id = data.Id,
            AdjustmentNumber = data.AdjustmentNumber,
            WarehouseId = data.WarehouseId,
            WarehouseName = data.WarehouseName,
            ProductId = data.ProductId,
            VariantId = (int?)data.VariantId,
            ProductName = data.ProductName,
            Sku = data.Sku,
            ReasonCodeId = (int?)data.ReasonCodeId,
            Reason = data.Reason,
            QuantityBefore = data.QuantityBefore,
            QuantityChange = data.QuantityChange,
            QuantityAfter = data.QuantityAfter,
            Note = data.Note,
            AdjustedOn = data.AdjustedOn ?? DateTime.UtcNow,
            CreatedByName = data.CreatedByName
        };
    }

    public async Task<int> SaveAsync(StockAdjustmentSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Id", request.Id);
        parameters.Add("@ProductId", request.ProductId);
        parameters.Add("@VariantId", request.VariantId);
        parameters.Add("@WarehouseId", request.WarehouseId);
        parameters.Add("@QuantityChange", request.QuantityChange);
        parameters.Add("@ReasonCodeId", request.ReasonCodeId ?? 44); // 44: Manual correction default
        parameters.Add("@Note", request.Note);
        parameters.Add("@LoggedInUserId", adminUserId);
        parameters.Add("@NewId", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await connection.ExecuteAsync("dbo.usp_StockAdjustment_Save", parameters, commandType: CommandType.StoredProcedure);

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

        await connection.ExecuteAsync("dbo.usp_StockAdjustment_Delete", parameters, commandType: CommandType.StoredProcedure);

        var errorMessage = parameters.Get<string?>("@ErrorMessage");
        if (!string.IsNullOrWhiteSpace(errorMessage))
        {
            throw new InvalidOperationException(errorMessage);
        }

        return true;
    }
}
