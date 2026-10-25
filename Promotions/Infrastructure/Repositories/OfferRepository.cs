using System.Data;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Dapper;
using Microsoft.Data.SqlClient;
using Promotions.Domain.IServices;

namespace Promotions.Infrastructure.Repositories;

public class OfferRepository : IOfferRepository
{
    private readonly string _connectionString;

    public OfferRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<PagedResult<OfferGridItem>> GetGridAsync(DataTableRequest request, CancellationToken ct = default)
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

        var rawItems = (await connection.QueryAsync<dynamic>(
            "dbo.usp_Offer_GridList",
            parameters,
            commandType: CommandType.StoredProcedure)).AsList();

        var items = rawItems.Select(d => new OfferGridItem
        {
            Id = d.Id,
            Name = d.Name ?? "",
            OfferType = d.OfferType ?? "Flash Sale",
            DiscountPercent = d.DiscountPercent ?? 0,
            StartsOn = d.StartsOn ?? DateTime.UtcNow,
            EndsOn = d.EndsOn ?? DateTime.UtcNow.AddDays(7),
            ProductCount = d.ProductCount ?? 0,
            OrdersInfluenced = d.OrdersInfluenced ?? 0,
            RevenueInfluenced = d.RevenueInfluenced ?? 0m,
            IsActive = d.IsActive ?? true,
            CreatedOn = d.CreatedAt ?? DateTime.UtcNow,
            UpdatedOn = d.UpdatedAt
        }).ToList();

        var totalFiltered = parameters.Get<int>("@TotalFilteredRecords");
        return new PagedResult<OfferGridItem>(items, totalFiltered, request.Page <= 0 ? 1 : request.Page, request.PageSize <= 0 ? 25 : request.PageSize);
    }

    public async Task<FlashSaleSaveRequest?> GetByIdAsync(int id, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var data = await connection.QueryFirstOrDefaultAsync<dynamic>(
            "dbo.usp_Offer_GetById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);

        if (data == null) return null;

        return new FlashSaleSaveRequest
        {
            Id = data.Id,
            Name = data.Name ?? "",
            StartsOn = data.StartsOn ?? DateTime.UtcNow,
            EndsOn = data.EndsOn ?? DateTime.UtcNow.AddDays(7),
            DiscountPercent = data.DiscountPercent ?? 0,
            OfferType = data.OfferType ?? "Flash Sale",
            Description = data.Description,
            Priority = data.Priority,
            IsActive = data.IsActive ?? true
        };
    }

    public async Task<OfferGridItem?> GetDetailAsync(int id, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var data = await connection.QueryFirstOrDefaultAsync<dynamic>(
            "dbo.usp_Offer_GetById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);

        if (data == null) return null;

        return new OfferGridItem
        {
            Id = data.Id,
            Name = data.Name ?? "",
            OfferType = data.OfferType ?? "Flash Sale",
            DiscountPercent = data.DiscountPercent ?? 0,
            StartsOn = data.StartsOn ?? DateTime.UtcNow,
            EndsOn = data.EndsOn ?? DateTime.UtcNow.AddDays(7),
            ProductCount = 0,
            OrdersInfluenced = data.OrdersInfluenced ?? 0,
            RevenueInfluenced = data.RevenueInfluenced ?? 0m,
            IsActive = data.IsActive ?? true,
            CreatedOn = data.CreatedAt ?? DateTime.UtcNow,
            UpdatedOn = data.UpdatedAt
        };
    }

    public async Task<int> SaveAsync(FlashSaleSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Id", request.Id);
        parameters.Add("@Name", request.Name);
        parameters.Add("@OfferType", request.OfferType);
        parameters.Add("@Description", request.Description);
        parameters.Add("@DiscountPercent", request.DiscountPercent);
        parameters.Add("@StartsOn", request.StartsOn);
        parameters.Add("@EndsOn", request.EndsOn);
        parameters.Add("@SortOrder", request.Priority ?? 0);
        parameters.Add("@IsActive", request.IsActive);
        parameters.Add("@LoggedInUserId", adminUserId);
        parameters.Add("@NewId", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await connection.ExecuteAsync("dbo.usp_Offer_Save", parameters, commandType: CommandType.StoredProcedure);

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

        await connection.ExecuteAsync("dbo.usp_Offer_Delete", parameters, commandType: CommandType.StoredProcedure);

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

        await connection.ExecuteAsync("dbo.usp_Offer_UpdateStatus", parameters, commandType: CommandType.StoredProcedure);

        var errorMessage = parameters.Get<string?>("@ErrorMessage");
        if (!string.IsNullOrWhiteSpace(errorMessage))
        {
            throw new InvalidOperationException(errorMessage);
        }

        return parameters.Get<bool>("@Success");
    }

    public async Task<FlashSaleOfferViewModel?> GetFlashSaleOfferAsync(CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<FlashSaleOfferViewModel>(
            "dbo.usp_Offer_GetFlashSale",
            commandType: CommandType.StoredProcedure);
    }
}
