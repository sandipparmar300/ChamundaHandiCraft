using System.Data;
using System.Text.Json;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Dapper;
using Inventory.Domain.IServices;
using Microsoft.Data.SqlClient;

namespace Inventory.Infrastructure.Repositories;

public class PurchaseRepository : IPurchaseRepository
{
    private readonly string _connectionString;

    public PurchaseRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<PagedResult<PurchaseOrderGridItem>> GetGridAsync(DataTableRequest request, int? supplierId = null, int? warehouseId = null, string? status = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@SearchText", request.Search);
        parameters.Add("@SupplierId", supplierId);
        parameters.Add("@WarehouseId", warehouseId);
        parameters.Add("@Status", status);
        parameters.Add("@SortColumn", string.IsNullOrWhiteSpace(request.SortBy) ? "PoNumber" : request.SortBy);
        parameters.Add("@SortOrder", request.SortDescending ? "DESC" : "ASC");
        parameters.Add("@PageSize", request.PageSize <= 0 ? 25 : request.PageSize);
        parameters.Add("@PageIndex", request.Page <= 0 ? 1 : request.Page);
        parameters.Add("@TotalRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@TotalFilteredRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);

        var items = (await connection.QueryAsync<PurchaseOrderGridItem>(
            "dbo.usp_Purchase_GridList",
            parameters,
            commandType: CommandType.StoredProcedure)).AsList();

        var totalRecords = parameters.Get<int>("@TotalRecords");
        var totalFiltered = parameters.Get<int>("@TotalFilteredRecords");

        return new PagedResult<PurchaseOrderGridItem>(items, totalFiltered, request.Page <= 0 ? 1 : request.Page, request.PageSize <= 0 ? 25 : request.PageSize);
    }

    public async Task<PurchaseOrderDetailViewModel?> GetByIdAsync(int id, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        using var multi = await connection.QueryMultipleAsync(
            "dbo.usp_Purchase_GetById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);

        var header = await multi.ReadFirstOrDefaultAsync<dynamic>();
        if (header == null) return null;

        var lines = (await multi.ReadAsync<PurchaseOrderLineDetailViewModel>()).AsList();

        return new PurchaseOrderDetailViewModel
        {
            Id = header.Id,
            PoNumber = header.PoNumber,
            SupplierId = header.SupplierId,
            SupplierName = header.SupplierName,
            SupplierEmail = header.SupplierEmail,
            SupplierPhone = header.SupplierPhone,
            WarehouseId = header.WarehouseId,
            WarehouseName = header.WarehouseName,
            OrderDate = header.OrderedOn ?? DateTime.UtcNow,
            ExpectedDate = header.ExpectedOn,
            ReceivedDate = header.ReceivedOn,
            Status = header.Status ?? "Draft",
            Notes = header.Note,
            SubTotal = header.SubTotal ?? 0m,
            TaxAmount = header.TaxAmount ?? 0m,
            ShippingAmount = header.ShippingCost ?? 0m,
            TotalAmount = header.TotalValue ?? 0m,
            LineCount = lines.Count,
            QuantityOrdered = header.QuantityOrdered ?? 0,
            QuantityReceived = header.QuantityReceived ?? 0,
            CreatedOn = header.CreatedAt ?? DateTime.UtcNow,
            Lines = lines
        };
    }

    public async Task<int> SaveAsync(PurchaseOrderSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();

        var linesPayload = request.Lines.Select(l => new
        {
            ProductId = l.ProductId,
            VariantId = l.VariantId,
            Sku = l.Sku ?? string.Empty,
            ProductName = l.ProductName ?? string.Empty,
            QuantityOrdered = l.OrderedQuantity,
            UnitCost = l.UnitCost,
            TaxPercent = l.TaxPercent
        });

        var linesJson = JsonSerializer.Serialize(linesPayload);

        var parameters = new DynamicParameters();
        parameters.Add("@Id", request.Id);
        parameters.Add("@PoNumber", request.PoNumber);
        parameters.Add("@SupplierId", request.SupplierId);
        parameters.Add("@WarehouseId", request.WarehouseId);
        parameters.Add("@OrderedOn", request.OrderDate);
        parameters.Add("@ExpectedOn", request.ExpectedDate);
        parameters.Add("@ShippingCost", request.ShippingAmount);
        parameters.Add("@Note", request.Notes);
        parameters.Add("@Status", request.Status ?? "Draft");
        parameters.Add("@LinesJson", linesJson);
        parameters.Add("@LoggedInUserId", adminUserId);
        parameters.Add("@NewId", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await connection.ExecuteAsync("dbo.usp_Purchase_Save", parameters, commandType: CommandType.StoredProcedure);

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

        await connection.ExecuteAsync("dbo.usp_Purchase_Delete", parameters, commandType: CommandType.StoredProcedure);

        var errorMessage = parameters.Get<string?>("@ErrorMessage");
        if (!string.IsNullOrWhiteSpace(errorMessage))
        {
            throw new InvalidOperationException(errorMessage);
        }

        return true;
    }

    public async Task<bool> UpdateStatusAsync(int id, string status, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Id", id);
        parameters.Add("@Status", status);
        parameters.Add("@LoggedInUserId", adminUserId);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await connection.ExecuteAsync("dbo.usp_Purchase_UpdateStatus", parameters, commandType: CommandType.StoredProcedure);

        var errorMessage = parameters.Get<string?>("@ErrorMessage");
        if (!string.IsNullOrWhiteSpace(errorMessage))
        {
            throw new InvalidOperationException(errorMessage);
        }

        return true;
    }

    public async Task<bool> ReceiveStockAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@PurchaseOrderId", id);
        parameters.Add("@LoggedInUserId", adminUserId);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await connection.ExecuteAsync("dbo.usp_Purchase_ReceiveStock", parameters, commandType: CommandType.StoredProcedure);

        var errorMessage = parameters.Get<string?>("@ErrorMessage");
        if (!string.IsNullOrWhiteSpace(errorMessage))
        {
            throw new InvalidOperationException(errorMessage);
        }

        return true;
    }
}
