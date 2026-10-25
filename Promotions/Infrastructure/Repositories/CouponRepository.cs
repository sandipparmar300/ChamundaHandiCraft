using System.Data;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Dapper;
using Microsoft.Data.SqlClient;
using Promotions.Domain.IServices;

namespace Promotions.Infrastructure.Repositories;

public class CouponRepository : ICouponRepository
{
    private readonly string _connectionString;

    public CouponRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<PagedResult<CouponGridItem>> GetGridAsync(DataTableRequest request, CancellationToken ct = default)
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
            "dbo.usp_Coupon_GridList",
            parameters,
            commandType: CommandType.StoredProcedure)).AsList();

        var items = rawItems.Select(d => new CouponGridItem
        {
            Id = d.Id,
            Code = d.Code ?? "",
            Title = d.Title ?? "",
            DiscountType = (DiscountType)(int)d.DiscountType,
            DiscountValue = d.DiscountValue ?? 0m,
            MinimumOrderValue = d.MinimumOrderValue,
            StartsOn = d.StartsOn ?? DateTime.UtcNow,
            ExpiresOn = d.ExpiresOn,
            UsageCount = d.UsageCount ?? 0,
            TotalUsageLimit = d.TotalUsageLimit,
            TotalDiscountGiven = d.TotalDiscountGiven ?? 0m,
            Status = (CouponStatus)(int)d.Status,
            IsPublic = d.IsPublic ?? true,
            CreatedOn = d.CreatedAt ?? DateTime.UtcNow,
            UpdatedOn = d.UpdatedAt
        }).ToList();

        var totalFiltered = parameters.Get<int>("@TotalFilteredRecords");
        return new PagedResult<CouponGridItem>(items, totalFiltered, request.Page <= 0 ? 1 : request.Page, request.PageSize <= 0 ? 25 : request.PageSize);
    }

    public async Task<CouponSaveRequest?> GetByIdAsync(int id, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var data = await connection.QueryFirstOrDefaultAsync<dynamic>(
            "dbo.usp_Coupon_GetById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);

        if (data == null) return null;

        return new CouponSaveRequest
        {
            Id = data.Id,
            Code = data.Code ?? "",
            Title = data.Title ?? "",
            Description = data.Description,
            DiscountType = (DiscountType)(int)data.DiscountType,
            DiscountValue = data.DiscountValue ?? 0m,
            MaxDiscount = data.MaxDiscount,
            MinimumOrderValue = data.MinimumOrderValue,
            StartsOn = data.StartsOn ?? DateTime.UtcNow,
            ExpiresOn = data.ExpiresOn,
            TotalUsageLimit = data.TotalUsageLimit,
            PerCustomerLimit = data.PerCustomerLimit ?? 1,
            IsPublic = data.IsPublic ?? true,
            Status = (CouponStatus)(int)data.Status,
            IsActive = data.IsActive ?? true
        };
    }

    public async Task<CouponGridItem?> GetDetailAsync(int id, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var data = await connection.QueryFirstOrDefaultAsync<dynamic>(
            "dbo.usp_Coupon_GetById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);

        if (data == null) return null;

        return new CouponGridItem
        {
            Id = data.Id,
            Code = data.Code ?? "",
            Title = data.Title ?? "",
            DiscountType = (DiscountType)(int)data.DiscountType,
            DiscountValue = data.DiscountValue ?? 0m,
            MinimumOrderValue = data.MinimumOrderValue,
            StartsOn = data.StartsOn ?? DateTime.UtcNow,
            ExpiresOn = data.ExpiresOn,
            UsageCount = data.UsageCount ?? 0,
            TotalUsageLimit = data.TotalUsageLimit,
            TotalDiscountGiven = data.TotalDiscountGiven ?? 0m,
            Status = (CouponStatus)(int)data.Status,
            IsPublic = data.IsPublic ?? true,
            CreatedOn = data.CreatedAt ?? DateTime.UtcNow,
            UpdatedOn = data.UpdatedAt
        };
    }

    public async Task<int> SaveAsync(CouponSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Id", request.Id);
        parameters.Add("@Code", request.Code);
        parameters.Add("@Title", request.Title);
        parameters.Add("@Description", request.Description);
        parameters.Add("@DiscountType", (int)request.DiscountType);
        parameters.Add("@DiscountValue", request.DiscountValue);
        parameters.Add("@MaxDiscount", request.MaxDiscount);
        parameters.Add("@MinimumOrderValue", request.MinimumOrderValue);
        parameters.Add("@StartsOn", request.StartsOn);
        parameters.Add("@ExpiresOn", request.ExpiresOn);
        parameters.Add("@TotalUsageLimit", request.TotalUsageLimit);
        parameters.Add("@PerCustomerLimit", request.PerCustomerLimit);
        parameters.Add("@IsPublic", request.IsPublic);
        parameters.Add("@Status", (int)request.Status);
        parameters.Add("@IsActive", request.IsActive);
        parameters.Add("@LoggedInUserId", adminUserId);
        parameters.Add("@NewId", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await connection.ExecuteAsync("dbo.usp_Coupon_Save", parameters, commandType: CommandType.StoredProcedure);

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

        await connection.ExecuteAsync("dbo.usp_Coupon_Delete", parameters, commandType: CommandType.StoredProcedure);

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

        await connection.ExecuteAsync("dbo.usp_Coupon_UpdateStatus", parameters, commandType: CommandType.StoredProcedure);

        var errorMessage = parameters.Get<string?>("@ErrorMessage");
        if (!string.IsNullOrWhiteSpace(errorMessage))
        {
            throw new InvalidOperationException(errorMessage);
        }

        return parameters.Get<bool>("@Success");
    }
}
