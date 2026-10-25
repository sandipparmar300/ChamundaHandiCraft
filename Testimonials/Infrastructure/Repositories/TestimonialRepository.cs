using System.Data;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Dapper;
using Microsoft.Data.SqlClient;
using Testimonials.Domain.IServices;

namespace Testimonials.Infrastructure.Repositories;

public class TestimonialRepository : ITestimonialRepository
{
    private readonly string _connectionString;

    public TestimonialRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<PagedResult<TestimonialGridItem>> GetGridAsync(DataTableRequest request, CancellationToken ct = default)
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

        var items = (await connection.QueryAsync<TestimonialGridItem>(
            "dbo.usp_Testimonial_GridList",
            parameters,
            commandType: CommandType.StoredProcedure)).AsList();

        var totalFiltered = parameters.Get<int>("@TotalFilteredRecords");
        return new PagedResult<TestimonialGridItem>(items, totalFiltered, request.Page <= 0 ? 1 : request.Page, request.PageSize <= 0 ? 25 : request.PageSize);
    }

    public async Task<TestimonialSaveRequest?> GetByIdAsync(int id, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var data = await connection.QueryFirstOrDefaultAsync<dynamic>(
            "dbo.usp_Testimonial_GetById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);

        if (data == null) return null;

        return new TestimonialSaveRequest
        {
            Id = data.Id,
            CustomerName = data.CustomerName,
            Location = data.Location,
            Quote = data.Quote,
            Rating = (int)data.Rating,
            PhotoUrl = data.PhotoUrl,
            ShowOnHome = data.ShowOnHome ?? false,
            SortOrder = data.SortOrder ?? 0,
            Status = (ContentStatus)(int)data.Status,
            IsActive = data.IsActive ?? true
        };
    }

    public async Task<TestimonialGridItem?> GetDetailAsync(int id, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var data = await connection.QueryFirstOrDefaultAsync<dynamic>(
            "dbo.usp_Testimonial_GetById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);

        if (data == null) return null;

        return new TestimonialGridItem
        {
            Id = data.Id,
            CustomerName = data.CustomerName,
            Location = data.Location,
            Quote = data.Quote,
            Rating = (int)data.Rating,
            PhotoUrl = data.PhotoUrl,
            ShowOnHome = data.ShowOnHome ?? false,
            SortOrder = data.SortOrder ?? 0,
            Status = (ContentStatus)(int)data.Status,
            CreatedAt = data.CreatedAt ?? DateTime.UtcNow,
            UpdatedAt = data.UpdatedAt
        };
    }

    public async Task<int> SaveAsync(TestimonialSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Id", request.Id);
        parameters.Add("@CustomerName", request.CustomerName);
        parameters.Add("@Location", request.Location);
        parameters.Add("@Quote", request.Quote);
        parameters.Add("@Rating", request.Rating);
        parameters.Add("@PhotoUrl", request.PhotoUrl);
        parameters.Add("@ShowOnHome", request.ShowOnHome);
        parameters.Add("@SortOrder", request.SortOrder);
        parameters.Add("@Status", (int)request.Status);
        parameters.Add("@IsActive", request.IsActive);
        parameters.Add("@LoggedInUserId", adminUserId);
        parameters.Add("@NewId", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await connection.ExecuteAsync("dbo.usp_Testimonial_Save", parameters, commandType: CommandType.StoredProcedure);

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

        await connection.ExecuteAsync("dbo.usp_Testimonial_Delete", parameters, commandType: CommandType.StoredProcedure);

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

        await connection.ExecuteAsync("dbo.usp_Testimonial_UpdateStatus", parameters, commandType: CommandType.StoredProcedure);

        var errorMessage = parameters.Get<string?>("@ErrorMessage");
        if (!string.IsNullOrWhiteSpace(errorMessage))
        {
            throw new InvalidOperationException(errorMessage);
        }

        return parameters.Get<bool>("@Success");
    }

    public async Task<List<TestimonialGridItem>> GetFeaturedAsync(int count = 10, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return (await connection.QueryAsync<TestimonialGridItem>(
            "dbo.usp_Testimonial_GetFeatured",
            new { Count = count },
            commandType: CommandType.StoredProcedure)).AsList();
    }
}
