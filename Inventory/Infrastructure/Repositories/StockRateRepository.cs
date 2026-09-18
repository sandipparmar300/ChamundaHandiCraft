using System.Data;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Dapper;
using Inventory.Domain.IServices;
using Microsoft.Data.SqlClient;

namespace Inventory.Infrastructure.Repositories;

public class StockRateRepository : IStockRateRepository
{
    private readonly string _connectionString;

    public StockRateRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<PagedResult<StockRateGridItem>> GetGridAsync(DataTableRequest request, int? warehouseId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@SearchText", request.Search);
        parameters.Add("@WarehouseId", warehouseId);
        parameters.Add("@SortColumn", string.IsNullOrWhiteSpace(request.SortBy) ? "ProductName" : request.SortBy);
        parameters.Add("@SortOrder", request.SortDescending ? "DESC" : "ASC");
        parameters.Add("@PageSize", request.PageSize <= 0 ? 25 : request.PageSize);
        parameters.Add("@PageIndex", request.Page <= 0 ? 1 : request.Page);
        parameters.Add("@TotalRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@TotalFilteredRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);

        var items = (await connection.QueryAsync<StockRateGridItem>(
            "dbo.usp_StockRate_GridList",
            parameters,
            commandType: CommandType.StoredProcedure)).AsList();

        var totalRecords = parameters.Get<int>("@TotalRecords");
        var totalFiltered = parameters.Get<int>("@TotalFilteredRecords");

        return new PagedResult<StockRateGridItem>(items, totalFiltered, request.Page <= 0 ? 1 : request.Page, request.PageSize <= 0 ? 25 : request.PageSize);
    }

    public async Task<StockRateDetailViewModel?> GetByIdAsync(int productId, int? variantId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var data = await connection.QueryFirstOrDefaultAsync<dynamic>(
            "dbo.usp_StockRate_GetById",
            new { ProductId = productId, VariantId = variantId },
            commandType: CommandType.StoredProcedure);

        if (data == null) return null;

        return new StockRateDetailViewModel
        {
            ProductId = (int)data.ProductId,
            VariantId = (int?)data.VariantId,
            ProductName = (string)data.ProductName,
            Sku = (string)data.Sku,
            Barcode = (string?)data.Barcode,
            CostPrice = (decimal)(data.CostPrice ?? 0m),
            Price = (decimal)(data.Price ?? 0m),
            Mrp = (decimal)(data.Mrp ?? 0m),
            TotalOnHand = (int)(data.TotalOnHand ?? 0)
        };
    }

    public async Task<bool> SaveAsync(StockRateSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@ProductId", request.ProductId);
        parameters.Add("@VariantId", request.VariantId);
        parameters.Add("@CostPrice", request.CostPrice);
        parameters.Add("@Price", request.Price);
        parameters.Add("@Mrp", request.Mrp);
        parameters.Add("@UserId", adminUserId);

        await connection.ExecuteAsync("dbo.usp_StockRate_Save", parameters, commandType: CommandType.StoredProcedure);
        return true;
    }
}
