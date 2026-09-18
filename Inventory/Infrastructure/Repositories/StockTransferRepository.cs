using System.Data;
using System.Text.Json;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Dapper;
using Inventory.Domain.IServices;
using Microsoft.Data.SqlClient;

namespace Inventory.Infrastructure.Repositories;

public class StockTransferRepository : IStockTransferRepository
{
    private readonly string _connectionString;

    public StockTransferRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<PagedResult<StockTransferGridItem>> GetGridAsync(DataTableRequest request, int? fromWarehouseId = null, int? toWarehouseId = null, string? status = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@SearchText", request.Search);
        parameters.Add("@FromWarehouseId", fromWarehouseId);
        parameters.Add("@ToWarehouseId", toWarehouseId);
        parameters.Add("@Status", status);
        parameters.Add("@SortColumn", string.IsNullOrWhiteSpace(request.SortBy) ? "TransferNumber" : request.SortBy);
        parameters.Add("@SortOrder", request.SortDescending ? "DESC" : "ASC");
        parameters.Add("@PageSize", request.PageSize <= 0 ? 25 : request.PageSize);
        parameters.Add("@PageIndex", request.Page <= 0 ? 1 : request.Page);
        parameters.Add("@TotalRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@TotalFilteredRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);

        var items = (await connection.QueryAsync<StockTransferGridItem>(
            "dbo.usp_StockTransfer_GridList",
            parameters,
            commandType: CommandType.StoredProcedure)).AsList();

        var totalRecords = parameters.Get<int>("@TotalRecords");
        var totalFiltered = parameters.Get<int>("@TotalFilteredRecords");

        return new PagedResult<StockTransferGridItem>(items, totalFiltered, request.Page <= 0 ? 1 : request.Page, request.PageSize <= 0 ? 25 : request.PageSize);
    }

    public async Task<StockTransferDetailViewModel?> GetByIdAsync(int id, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        using var multi = await connection.QueryMultipleAsync(
            "dbo.usp_StockTransfer_GetById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);

        var header = await multi.ReadFirstOrDefaultAsync<dynamic>();
        if (header == null) return null;

        var lines = (await multi.ReadAsync<dynamic>()).Select(l => new StockTransferLineDetailViewModel
        {
            Id = (int)l.Id,
            ProductId = (int)l.ProductId,
            VariantId = (int?)l.VariantId,
            ProductName = (string)l.ProductName,
            Sku = (string)l.Sku,
            Quantity = (int)l.QuantitySent,
            Notes = null
        }).AsList();

        return new StockTransferDetailViewModel
        {
            Id = header.Id,
            TransferNumber = header.TransferNumber,
            FromWarehouseId = header.FromWarehouseId,
            FromWarehouseName = header.FromWarehouseName,
            ToWarehouseId = header.ToWarehouseId,
            ToWarehouseName = header.ToWarehouseName,
            TransferDate = header.CreatedAt ?? DateTime.UtcNow,
            ShippedDate = header.DispatchedOn,
            ReceivedDate = header.ReceivedOn,
            Status = header.Status ?? "Draft",
            Notes = header.Note,
            TotalQuantity = header.TotalQuantity ?? 0,
            LineCount = lines.Count,
            CreatedOn = header.CreatedAt ?? DateTime.UtcNow,
            Lines = lines
        };
    }

    public async Task<int> SaveAsync(StockTransferSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();

        var linesPayload = request.Lines.Select(l => new
        {
            ProductId = l.ProductId,
            VariantId = l.VariantId,
            Sku = l.Sku ?? string.Empty,
            QuantitySent = l.Quantity
        });

        var linesJson = JsonSerializer.Serialize(linesPayload);

        var parameters = new DynamicParameters();
        parameters.Add("@Id", request.Id);
        parameters.Add("@FromWarehouseId", request.FromWarehouseId);
        parameters.Add("@ToWarehouseId", request.ToWarehouseId);
        parameters.Add("@Note", request.Notes);
        parameters.Add("@LinesJson", linesJson);
        parameters.Add("@LoggedInUserId", adminUserId);
        parameters.Add("@NewId", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await connection.ExecuteAsync("dbo.usp_StockTransfer_Save", parameters, commandType: CommandType.StoredProcedure);

        var errorMessage = parameters.Get<string?>("@ErrorMessage");
        if (!string.IsNullOrWhiteSpace(errorMessage))
        {
            throw new InvalidOperationException(errorMessage);
        }

        return parameters.Get<int>("@NewId");
    }

    public async Task<bool> UpdateStatusAsync(int id, string newStatus, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Id", id);
        parameters.Add("@NewStatus", newStatus);
        parameters.Add("@LoggedInUserId", adminUserId);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await connection.ExecuteAsync("dbo.usp_StockTransfer_UpdateStatus", parameters, commandType: CommandType.StoredProcedure);

        var errorMessage = parameters.Get<string?>("@ErrorMessage");
        if (!string.IsNullOrWhiteSpace(errorMessage))
        {
            throw new InvalidOperationException(errorMessage);
        }

        return true;
    }

    public async Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Id", id);
        parameters.Add("@LoggedInUserId", adminUserId);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await connection.ExecuteAsync("dbo.usp_StockTransfer_Delete", parameters, commandType: CommandType.StoredProcedure);

        var errorMessage = parameters.Get<string?>("@ErrorMessage");
        if (!string.IsNullOrWhiteSpace(errorMessage))
        {
            throw new InvalidOperationException(errorMessage);
        }

        return true;
    }
}
