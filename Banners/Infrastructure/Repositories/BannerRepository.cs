using System.Data;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Dapper;
using Microsoft.Data.SqlClient;
using Banners.Domain.IServices;

namespace Banners.Infrastructure.Repositories;

public class BannerRepository : IBannerRepository
{
    private readonly string _connectionString;

    public BannerRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<PagedResult<BannerViewModel>> GetGridAsync(DataTableRequest request, CancellationToken ct = default)
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
            "dbo.usp_Banner_GridList",
            parameters,
            commandType: CommandType.StoredProcedure)).AsList();

        var items = rawItems.Select(d => new BannerViewModel
        {
            Id = d.Id,
            Placement = (BannerPlacement)(int)d.Placement,
            Eyebrow = d.Eyebrow,
            Heading = d.Heading ?? "",
            SubHeading = d.SubHeading,
            ImageUrl = d.ImageUrl ?? "/assets/images/default-banner.png",
            MobileImageUrl = d.MobileImageUrl,
            ImageAlt = d.ImageAlt ?? "",
            PrimaryCtaLabel = d.PrimaryCtaLabel,
            PrimaryCtaUrl = d.PrimaryCtaUrl,
            SecondaryCtaLabel = d.SecondaryCtaLabel,
            SecondaryCtaUrl = d.SecondaryCtaUrl,
            SortOrder = d.SortOrder ?? 0,
            Status = (ContentStatus)(int)d.Status,
            StartsOn = d.StartsOn,
            EndsOn = d.EndsOn,
            ImpressionCount = d.ImpressionCount ?? 0,
            ClickCount = d.ClickCount ?? 0,
            IsActive = d.IsActive ?? true,
            CreatedAt = d.CreatedAt ?? DateTime.UtcNow,
            UpdatedAt = d.UpdatedAt
        }).ToList();

        var totalFiltered = parameters.Get<int>("@TotalFilteredRecords");
        return new PagedResult<BannerViewModel>(items, totalFiltered, request.Page <= 0 ? 1 : request.Page, request.PageSize <= 0 ? 25 : request.PageSize);
    }

    public async Task<BannerSaveRequest?> GetByIdAsync(int id, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var data = await connection.QueryFirstOrDefaultAsync<dynamic>(
            "dbo.usp_Banner_GetById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);

        if (data == null) return null;

        return new BannerSaveRequest
        {
            Id = data.Id,
            Placement = (BannerPlacement)(int)data.Placement,
            Eyebrow = data.Eyebrow,
            Heading = data.Heading ?? "",
            SubHeading = data.SubHeading,
            ImageUrl = data.ImageUrl ?? "/assets/images/default-banner.png",
            MobileImageUrl = data.MobileImageUrl,
            ImageAlt = data.ImageAlt ?? "",
            PrimaryCtaLabel = data.PrimaryCtaLabel,
            PrimaryCtaUrl = data.PrimaryCtaUrl,
            SecondaryCtaLabel = data.SecondaryCtaLabel,
            SecondaryCtaUrl = data.SecondaryCtaUrl,
            StartsOn = data.StartsOn,
            EndsOn = data.EndsOn,
            SortOrder = data.SortOrder ?? 0,
            Status = (ContentStatus)(int)data.Status,
            IsActive = data.IsActive ?? true,
            ImpressionCount = data.ImpressionCount ?? 0,
            ClickCount = data.ClickCount ?? 0
        };
    }

    public async Task<BannerViewModel?> GetDetailAsync(int id, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var data = await connection.QueryFirstOrDefaultAsync<dynamic>(
            "dbo.usp_Banner_GetById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);

        if (data == null) return null;

        return new BannerViewModel
        {
            Id = data.Id,
            Placement = (BannerPlacement)(int)data.Placement,
            Eyebrow = data.Eyebrow,
            Heading = data.Heading ?? "",
            SubHeading = data.SubHeading,
            ImageUrl = data.ImageUrl ?? "/assets/images/default-banner.png",
            MobileImageUrl = data.MobileImageUrl,
            ImageAlt = data.ImageAlt ?? "",
            PrimaryCtaLabel = data.PrimaryCtaLabel,
            PrimaryCtaUrl = data.PrimaryCtaUrl,
            SecondaryCtaLabel = data.SecondaryCtaLabel,
            SecondaryCtaUrl = data.SecondaryCtaUrl,
            SortOrder = data.SortOrder ?? 0,
            Status = (ContentStatus)(int)data.Status,
            StartsOn = data.StartsOn,
            EndsOn = data.EndsOn,
            ImpressionCount = data.ImpressionCount ?? 0,
            ClickCount = data.ClickCount ?? 0,
            IsActive = data.IsActive ?? true,
            CreatedAt = data.CreatedAt ?? DateTime.UtcNow,
            UpdatedAt = data.UpdatedAt
        };
    }

    public async Task<int> SaveAsync(BannerSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Id", request.Id);
        parameters.Add("@Placement", (int)request.Placement);
        parameters.Add("@Eyebrow", request.Eyebrow);
        parameters.Add("@Heading", request.Heading);
        parameters.Add("@SubHeading", request.SubHeading);
        parameters.Add("@ImageUrl", request.ImageUrl);
        parameters.Add("@MobileImageUrl", request.MobileImageUrl);
        parameters.Add("@ImageAlt", request.ImageAlt);
        parameters.Add("@PrimaryCtaLabel", request.PrimaryCtaLabel);
        parameters.Add("@PrimaryCtaUrl", request.PrimaryCtaUrl);
        parameters.Add("@SecondaryCtaLabel", request.SecondaryCtaLabel);
        parameters.Add("@SecondaryCtaUrl", request.SecondaryCtaUrl);
        parameters.Add("@StartsOn", request.StartsOn);
        parameters.Add("@EndsOn", request.EndsOn);
        parameters.Add("@SortOrder", request.SortOrder);
        parameters.Add("@Status", (int)request.Status);
        parameters.Add("@IsActive", request.IsActive);
        parameters.Add("@LoggedInUserId", adminUserId);
        parameters.Add("@NewId", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await connection.ExecuteAsync("dbo.usp_Banner_Save", parameters, commandType: CommandType.StoredProcedure);

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

        await connection.ExecuteAsync("dbo.usp_Banner_Delete", parameters, commandType: CommandType.StoredProcedure);

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

        await connection.ExecuteAsync("dbo.usp_Banner_UpdateStatus", parameters, commandType: CommandType.StoredProcedure);

        var errorMessage = parameters.Get<string?>("@ErrorMessage");
        if (!string.IsNullOrWhiteSpace(errorMessage))
        {
            throw new InvalidOperationException(errorMessage);
        }

        return parameters.Get<bool>("@Success");
    }

    public async Task<List<BannerViewModel>> GetByPlacementAsync(int placement, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var list = (await connection.QueryAsync<dynamic>(
            "dbo.usp_Banner_GetByPlacement",
            new { Placement = placement },
            commandType: CommandType.StoredProcedure)).ToList();

        var result = new List<BannerViewModel>();
        foreach (var data in list)
        {
            result.Add(new BannerViewModel
            {
                Id = data.Id,
                Placement = (BannerPlacement)(int)data.Placement,
                Eyebrow = data.Eyebrow,
                Heading = data.Heading ?? "",
                SubHeading = data.SubHeading,
                ImageUrl = data.ImageUrl ?? "/assets/images/placeholders/hero.svg",
                MobileImageUrl = data.MobileImageUrl,
                ImageAlt = data.ImageAlt ?? "",
                PrimaryCtaLabel = data.PrimaryCtaLabel,
                PrimaryCtaUrl = data.PrimaryCtaUrl,
                SecondaryCtaLabel = data.SecondaryCtaLabel,
                SecondaryCtaUrl = data.SecondaryCtaUrl,
                SortOrder = data.SortOrder ?? 0,
                Status = (ContentStatus)(int)data.Status,
                StartsOn = data.StartsOn,
                EndsOn = data.EndsOn,
                ImpressionCount = data.ImpressionCount ?? 0,
                ClickCount = data.ClickCount ?? 0,
                IsActive = data.IsActive ?? true,
                CreatedAt = data.CreatedAt ?? DateTime.UtcNow,
                UpdatedAt = data.UpdatedAt
            });
        }

        return result;
    }
}
