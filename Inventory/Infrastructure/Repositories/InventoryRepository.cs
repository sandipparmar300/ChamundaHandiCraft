using System.Data;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Dapper;
using Inventory.Domain.IServices;
using Microsoft.Data.SqlClient;

namespace Inventory.Infrastructure.Repositories;

public class InventoryRepository : IInventoryRepository
{
    private readonly string _connectionString;

    public InventoryRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<PagedResult<StockGridItem>> GetGridAsync(DataTableRequest request, int? warehouseId = null, string? stockStatus = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@SearchText", request.Search);
        parameters.Add("@WarehouseId", warehouseId);
        parameters.Add("@StockStatus", stockStatus);
        parameters.Add("@SortColumn", string.IsNullOrWhiteSpace(request.SortBy) ? "ProductName" : request.SortBy);
        parameters.Add("@SortOrder", request.SortDescending ? "DESC" : "ASC");
        parameters.Add("@PageSize", request.PageSize <= 0 ? 25 : request.PageSize);
        parameters.Add("@PageIndex", request.Page <= 0 ? 1 : request.Page);
        parameters.Add("@TotalRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@TotalFilteredRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);

        var items = (await connection.QueryAsync<dynamic>(
            "dbo.usp_Inventory_GridList",
            parameters,
            commandType: CommandType.StoredProcedure)).Select(d => new StockGridItem
            {
                Id = (long)d.Id,
                ProductId = (int)d.ProductId,
                VariantId = (int?)d.VariantId,
                ProductName = (string)(d.ProductName ?? string.Empty),
                Sku = (string)(d.Sku ?? string.Empty),
                WarehouseName = (string?)d.WarehouseName,
                OnHand = (int)(d.OnHand ?? 0),
                Reserved = (int)(d.Reserved ?? 0),
                LowStockThreshold = (int)(d.LowStockThreshold ?? 5)
            }).AsList();

        var totalRecords = parameters.Get<int>("@TotalRecords");
        var totalFiltered = parameters.Get<int>("@TotalFilteredRecords");

        return new PagedResult<StockGridItem>(items, totalFiltered, request.Page <= 0 ? 1 : request.Page, request.PageSize <= 0 ? 25 : request.PageSize);
    }

    public async Task<StockSaveRequest?> GetByIdAsync(long id, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var data = await connection.QueryFirstOrDefaultAsync<dynamic>(
            "dbo.usp_Inventory_GetById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);

        if (data == null) return null;

        return new StockSaveRequest
        {
            Id = (long)data.Id,
            ProductId = (int)data.ProductId,
            VariantId = (int?)data.VariantId,
            WarehouseId = (int)data.WarehouseId,
            OnHand = (int)data.OnHand,
            LowStockThreshold = (int)(data.LowStockThreshold ?? 5),
            BinLocation = (string?)data.BinLocation
        };
    }

    public async Task<InventoryDetailViewModel?> GetDetailAsync(long id, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var data = await connection.QueryFirstOrDefaultAsync<dynamic>(
            "dbo.usp_Inventory_GetById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);

        if (data == null) return null;

        int prodId = (int)data.ProductId;
        int whId = (int)data.WarehouseId;

        var ledger = await GetLedgerAsync(prodId, whId, 25, ct);

        return new InventoryDetailViewModel
        {
            Id = (long)data.Id,
            ProductId = prodId,
            VariantId = (int?)data.VariantId,
            ProductName = (string)data.ProductName,
            Sku = (string)data.Sku,
            Barcode = (string?)data.Barcode,
            WarehouseId = whId,
            WarehouseName = (string)(data.WarehouseName ?? "—"),
            OnHand = (int)data.OnHand,
            Reserved = (int)data.Reserved,
            Incoming = (int)data.Incoming,
            Available = (int)data.Available,
            LowStockThreshold = (int)(data.LowStockThreshold ?? 5),
            BinLocation = (string?)data.BinLocation,
            LastCountedOn = (DateTime?)data.LastCountedOn,
            CostPrice = (decimal)(data.CostPrice ?? 0m),
            Price = (decimal)(data.Price ?? 0m),
            CreatedOn = (DateTime)(data.CreatedAt ?? DateTime.UtcNow),
            UpdatedOn = (DateTime?)data.UpdatedAt,
            Ledger = ledger
        };
    }

    public async Task<long> SaveAsync(StockSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Id", request.Id);
        parameters.Add("@ProductId", request.ProductId);
        parameters.Add("@VariantId", request.VariantId);
        parameters.Add("@WarehouseId", request.WarehouseId);
        parameters.Add("@OnHand", request.OnHand);
        parameters.Add("@LowStockThreshold", request.LowStockThreshold);
        parameters.Add("@BinLocation", request.BinLocation);
        parameters.Add("@LoggedInUserId", adminUserId);
        parameters.Add("@Note", request.Notes);
        parameters.Add("@NewId", dbType: DbType.Int64, direction: ParameterDirection.Output);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await connection.ExecuteAsync("dbo.usp_Inventory_Save", parameters, commandType: CommandType.StoredProcedure);

        var errorMessage = parameters.Get<string?>("@ErrorMessage");
        if (!string.IsNullOrWhiteSpace(errorMessage))
        {
            throw new InvalidOperationException(errorMessage);
        }

        return parameters.Get<long>("@NewId");
    }

    public async Task<bool> DeleteAsync(long id, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Id", id);
        parameters.Add("@LoggedInUserId", adminUserId);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await connection.ExecuteAsync("dbo.usp_Inventory_Delete", parameters, commandType: CommandType.StoredProcedure);

        var errorMessage = parameters.Get<string?>("@ErrorMessage");
        if (!string.IsNullOrWhiteSpace(errorMessage))
        {
            throw new InvalidOperationException(errorMessage);
        }

        return true;
    }

    public async Task<InventoryKpiSummaryViewModel> GetKpisAsync(CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var data = await connection.QueryFirstOrDefaultAsync<dynamic>(
            "dbo.usp_Inventory_GetKpis",
            commandType: CommandType.StoredProcedure);

        if (data == null) return new InventoryKpiSummaryViewModel();

        return new InventoryKpiSummaryViewModel
        {
            TotalSkus = (int)(data.TotalProducts ?? 0),
            InStockCount = Math.Max(0, (int)(data.TotalProducts ?? 0) - (int)(data.LowStockProducts ?? 0) - (int)(data.OutOfStockProducts ?? 0)),
            LowStockCount = (int)(data.LowStockProducts ?? 0),
            OutOfStockCount = (int)(data.OutOfStockProducts ?? 0),
            TotalOnHandUnits = (int)(data.TotalStockQuantity ?? 0),
            TotalReservedUnits = (int)(data.TotalReservedQuantity ?? 0),
            TotalIncomingUnits = 0,
            TotalValuation = (decimal)(data.TotalInventoryValue ?? 0m)
        };
    }

    public async Task<List<InventoryTransactionViewModel>> GetLedgerAsync(int? productId = null, int? warehouseId = null, int maxRows = 100, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@ProductId", productId);
        parameters.Add("@WarehouseId", warehouseId);
        parameters.Add("@MaxRows", maxRows);

        var items = (await connection.QueryAsync<dynamic>(
            "dbo.usp_Inventory_GetLedger",
            parameters,
            commandType: CommandType.StoredProcedure)).Select(d => new InventoryTransactionViewModel
            {
                Id = (long)d.Id,
                TransactionNumber = $"TXN-{d.Id:D6}",
                TransactionType = (string)(d.TransactionType ?? "Adjustment"),
                QuantityBefore = (int)d.QuantityAfter - (int)d.QuantityChange,
                QuantityChange = (int)d.QuantityChange,
                QuantityAfter = (int)d.QuantityAfter,
                UnitCost = (decimal?)d.UnitCost,
                TotalCost = d.UnitCost != null ? (decimal?)((decimal)d.UnitCost * Math.Abs((int)d.QuantityChange)) : null,
                ReferenceType = (string?)d.ReferenceType,
                ReferenceNumber = (string?)d.ReferenceNumber,
                Notes = (string?)d.Note,
                CreatedOn = (DateTime)(d.CreatedAt ?? DateTime.UtcNow),
                CreatedByName = (string?)d.CreatedByName
            }).AsList();

        return items;
    }
}
