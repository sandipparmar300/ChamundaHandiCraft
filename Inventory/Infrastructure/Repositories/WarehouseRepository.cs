using System.Data;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Dapper;
using Inventory.Domain.IServices;
using Microsoft.Data.SqlClient;

namespace Inventory.Infrastructure.Repositories;

public class WarehouseRepository : IWarehouseRepository
{
    private readonly string _connectionString;

    public WarehouseRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<PagedResult<WarehouseGridItem>> GetGridAsync(DataTableRequest request, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@SearchText", request.Search);
        parameters.Add("@SortColumn", string.IsNullOrWhiteSpace(request.SortBy) ? "WarehouseName" : request.SortBy);
        parameters.Add("@SortOrder", request.SortDescending ? "DESC" : "ASC");
        parameters.Add("@PageSize", request.PageSize <= 0 ? 25 : request.PageSize);
        parameters.Add("@PageIndex", request.Page <= 0 ? 1 : request.Page);
        parameters.Add("@TotalRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@TotalFilteredRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);

        var items = (await connection.QueryAsync<WarehouseGridItem>(
            "dbo.usp_Warehouse_GridList",
            parameters,
            commandType: CommandType.StoredProcedure)).AsList();

        var totalRecords = parameters.Get<int>("@TotalRecords");
        var totalFiltered = parameters.Get<int>("@TotalFilteredRecords");

        return new PagedResult<WarehouseGridItem>(items, totalFiltered, request.Page <= 0 ? 1 : request.Page, request.PageSize <= 0 ? 25 : request.PageSize);
    }

    public async Task<WarehouseSaveRequest?> GetByIdAsync(int id, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var data = await connection.QueryFirstOrDefaultAsync<dynamic>(
            "dbo.usp_Warehouse_GetById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);

        if (data == null) return null;

        return new WarehouseSaveRequest
        {
            Id = data.Id,
            WarehouseName = data.WarehouseName,
            Code = data.Code,
            AddressLine1 = data.Line1,
            AddressLine2 = data.Line2,
            City = data.City,
            StateName = data.State,
            StateId = data.StateId,
            Pincode = data.Pincode,
            ContactPerson = data.ContactPerson,
            Phone = data.Phone,
            Email = data.Email,
            IsDefault = data.IsDefault ?? false,
            IsActive = data.IsActive ?? true
        };
    }

    public async Task<WarehouseDetailViewModel?> GetDetailAsync(int id, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var data = await connection.QueryFirstOrDefaultAsync<dynamic>(
            "dbo.usp_Warehouse_GetById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);

        if (data == null) return null;

        return new WarehouseDetailViewModel
        {
            Id = data.Id,
            WarehouseName = data.WarehouseName,
            Code = data.Code,
            AddressLine1 = data.Line1,
            AddressLine2 = data.Line2,
            City = data.City,
            StateName = data.State,
            StateId = data.StateId,
            Pincode = data.Pincode,
            ContactPerson = data.ContactPerson,
            Phone = data.Phone,
            Email = data.Email,
            IsDefault = data.IsDefault ?? false,
            IsActive = data.IsActive ?? true,
            TotalStockItems = data.SkuCount ?? 0,
            TotalOnHandUnits = data.TotalStock ?? 0,
            CreatedOn = data.CreatedAt ?? DateTime.UtcNow,
            UpdatedOn = data.UpdatedAt
        };
    }

    public async Task<int> SaveAsync(WarehouseSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Id", request.Id);
        parameters.Add("@WarehouseName", request.WarehouseName);
        parameters.Add("@Code", request.Code);
        parameters.Add("@Line1", request.AddressLine1);
        parameters.Add("@Line2", request.AddressLine2);
        parameters.Add("@City", request.City);
        parameters.Add("@State", request.StateName);
        parameters.Add("@Pincode", request.Pincode);
        parameters.Add("@ContactPerson", request.ContactPerson);
        parameters.Add("@Phone", request.Phone);
        parameters.Add("@Email", request.Email);
        parameters.Add("@IsDefault", request.IsDefault);
        parameters.Add("@IsActive", request.IsActive);
        parameters.Add("@LoggedInUserId", adminUserId);
        parameters.Add("@NewId", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await connection.ExecuteAsync("dbo.usp_Warehouse_Save", parameters, commandType: CommandType.StoredProcedure);

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
        parameters.Add("@Success", dbType: DbType.Boolean, direction: ParameterDirection.Output);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await connection.ExecuteAsync("dbo.usp_Warehouse_Delete", parameters, commandType: CommandType.StoredProcedure);

        var errorMessage = parameters.Get<string?>("@ErrorMessage");
        if (!string.IsNullOrWhiteSpace(errorMessage))
        {
            throw new InvalidOperationException(errorMessage);
        }

        return parameters.Get<bool>("@Success");
    }

    public async Task<bool> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Id", request.Id);
        parameters.Add("@IsActive", request.IsActive);
        parameters.Add("@LoggedInUserId", adminUserId);
        parameters.Add("@Success", dbType: DbType.Boolean, direction: ParameterDirection.Output);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await connection.ExecuteAsync("dbo.usp_Warehouse_UpdateStatus", parameters, commandType: CommandType.StoredProcedure);

        var errorMessage = parameters.Get<string?>("@ErrorMessage");
        if (!string.IsNullOrWhiteSpace(errorMessage))
        {
            throw new InvalidOperationException(errorMessage);
        }

        return parameters.Get<bool>("@Success");
    }

    public async Task<List<IdNamePair>> GetLookupAsync(CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var items = await connection.QueryAsync<IdNamePair>(
            "dbo.usp_Warehouse_Lookup",
            commandType: CommandType.StoredProcedure);
        return items.AsList();
    }
}
