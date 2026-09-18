using System.Data;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Dapper;
using Inventory.Domain.IServices;
using Microsoft.Data.SqlClient;

namespace Inventory.Infrastructure.Repositories;

public class SupplierRepository : ISupplierRepository
{
    private readonly string _connectionString;

    public SupplierRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<PagedResult<SupplierGridItem>> GetGridAsync(DataTableRequest request, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@SearchText", request.Search);
        parameters.Add("@SortColumn", string.IsNullOrWhiteSpace(request.SortBy) ? "SupplierName" : request.SortBy);
        parameters.Add("@SortOrder", request.SortDescending ? "DESC" : "ASC");
        parameters.Add("@PageSize", request.PageSize <= 0 ? 25 : request.PageSize);
        parameters.Add("@PageIndex", request.Page <= 0 ? 1 : request.Page);
        parameters.Add("@TotalRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@TotalFilteredRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);

        var items = (await connection.QueryAsync<SupplierGridItem>(
            "dbo.usp_Supplier_GridList",
            parameters,
            commandType: CommandType.StoredProcedure)).AsList();

        var totalRecords = parameters.Get<int>("@TotalRecords");
        var totalFiltered = parameters.Get<int>("@TotalFilteredRecords");

        return new PagedResult<SupplierGridItem>(items, totalFiltered, request.Page <= 0 ? 1 : request.Page, request.PageSize <= 0 ? 25 : request.PageSize);
    }

    public async Task<SupplierSaveRequest?> GetByIdAsync(int id, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var data = await connection.QueryFirstOrDefaultAsync<dynamic>(
            "dbo.usp_Supplier_GetById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);

        if (data == null) return null;

        return new SupplierSaveRequest
        {
            Id = data.Id,
            SupplierName = data.SupplierName,
            Code = data.Code,
            ContactPerson = data.ContactPerson,
            Phone = data.Phone,
            Email = data.Email,
            Gstin = data.Gstin,
            AddressLine1 = data.Line1,
            City = data.City,
            StateName = data.State,
            Pincode = data.Pincode,
            PaymentTermsDays = data.PaymentTermsDays ?? 30,
            OutstandingAmount = data.OutstandingAmount ?? 0,
            IsActive = data.IsActive ?? true
        };
    }

    public async Task<SupplierDetailViewModel?> GetDetailAsync(int id, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var data = await connection.QueryFirstOrDefaultAsync<dynamic>(
            "dbo.usp_Supplier_GetById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);

        if (data == null) return null;

        return new SupplierDetailViewModel
        {
            Id = data.Id,
            SupplierName = data.SupplierName,
            Code = data.Code,
            ContactPerson = data.ContactPerson,
            Phone = data.Phone,
            Email = data.Email,
            Gstin = data.Gstin,
            AddressLine1 = data.Line1,
            City = data.City,
            StateName = data.State,
            Pincode = data.Pincode,
            PaymentTermsDays = data.PaymentTermsDays ?? 30,
            OutstandingAmount = data.OutstandingAmount ?? 0,
            IsActive = data.IsActive ?? true,
            PurchaseOrderCount = data.PurchaseOrderCount ?? 0,
            CreatedOn = data.CreatedAt ?? DateTime.UtcNow,
            UpdatedOn = data.UpdatedAt
        };
    }

    public async Task<int> SaveAsync(SupplierSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Id", request.Id);
        parameters.Add("@SupplierName", request.SupplierName);
        parameters.Add("@Code", request.Code);
        parameters.Add("@ContactPerson", request.ContactPerson);
        parameters.Add("@Phone", request.Phone);
        parameters.Add("@Email", request.Email);
        parameters.Add("@Gstin", request.Gstin);
        parameters.Add("@Line1", request.AddressLine1);
        parameters.Add("@City", request.City);
        parameters.Add("@State", request.StateName);
        parameters.Add("@Pincode", request.Pincode);
        parameters.Add("@PaymentTermsDays", request.PaymentTermsDays);
        parameters.Add("@IsActive", request.IsActive);
        parameters.Add("@LoggedInUserId", adminUserId);
        parameters.Add("@NewId", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await connection.ExecuteAsync("dbo.usp_Supplier_Save", parameters, commandType: CommandType.StoredProcedure);

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

        await connection.ExecuteAsync("dbo.usp_Supplier_Delete", parameters, commandType: CommandType.StoredProcedure);

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

        await connection.ExecuteAsync("dbo.usp_Supplier_UpdateStatus", parameters, commandType: CommandType.StoredProcedure);

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
            "dbo.usp_Supplier_Lookup",
            commandType: CommandType.StoredProcedure);
        return items.AsList();
    }
}
