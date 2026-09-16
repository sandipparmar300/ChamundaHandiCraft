using System.Data;
using Categories.Domain.IServices;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Dapper;
using Microsoft.Data.SqlClient;

namespace Categories.Infrastructure.Repositories;

public class CategoryRepository : ICategoryRepository
{
    private readonly string _connectionString;

    public CategoryRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<List<CategoryViewModel>> GetTreeAsync(CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var flatList = (await connection.QueryAsync<CategoryViewModel>(
            "dbo.usp_Category_GetTree",
            commandType: CommandType.StoredProcedure)).AsList();

        // Build hierarchical tree
        var lookup = flatList.ToDictionary(c => c.Id);
        var roots = new List<CategoryViewModel>();

        foreach (var item in flatList)
        {
            if (item.ParentId.HasValue && lookup.TryGetValue(item.ParentId.Value, out var parent))
            {
                parent.Children.Add(item);
            }
            else
            {
                roots.Add(item);
            }
        }

        return roots;
    }

    public async Task<PagedResult<CategoryGridItem>> GetGridAsync(DataTableRequest request, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@SearchText", request.Search);
        parameters.Add("@SortColumn", string.IsNullOrWhiteSpace(request.SortBy) ? "SortOrder" : request.SortBy);
        parameters.Add("@SortOrder", request.SortDescending ? "DESC" : "ASC");
        parameters.Add("@PageSize", request.PageSize <= 0 ? 25 : request.PageSize);
        parameters.Add("@PageIndex", request.Page <= 0 ? 1 : request.Page);
        parameters.Add("@TotalRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@TotalFilteredRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);

        var items = (await connection.QueryAsync<CategoryGridItem>(
            "dbo.usp_Category_GridList",
            parameters,
            commandType: CommandType.StoredProcedure)).AsList();

        int total = parameters.Get<int>("@TotalRecords");
        int totalFiltered = parameters.Get<int>("@TotalFilteredRecords");

        return new PagedResult<CategoryGridItem>
        {
            Items = items,
            TotalCount = totalFiltered,
            Page = request.Page <= 0 ? 1 : request.Page,
            PageSize = request.PageSize <= 0 ? 25 : request.PageSize
        };
    }

    public async Task<CategorySaveRequest?> GetByIdAsync(int id, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        using var multi = await connection.QueryMultipleAsync(
            "dbo.usp_Category_GetById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);

        var category = await multi.ReadFirstOrDefaultAsync<CategorySaveRequest>();
        if (category is null) return null;

        var seo = await multi.ReadFirstOrDefaultAsync<SeoViewModel>();
        category.Seo = seo ?? new SeoViewModel();

        return category;
    }

    public async Task<int> SaveAsync(CategorySaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Id", request.Id);
        parameters.Add("@ParentId", request.ParentId);
        parameters.Add("@Name", request.Name);
        parameters.Add("@Slug", request.Slug);
        parameters.Add("@Description", request.Description);
        parameters.Add("@IntroCopy", request.IntroCopy);
        parameters.Add("@ImageUrl", request.ImageUrl);
        parameters.Add("@IconName", request.IconName);
        parameters.Add("@SortOrder", request.SortOrder);
        parameters.Add("@ShowInMegaMenu", request.ShowInMegaMenu);
        parameters.Add("@IsFeaturedOnHome", request.IsFeaturedOnHome);
        parameters.Add("@IsActive", request.IsActive);
        parameters.Add("@MetaTitle", request.Seo?.MetaTitle);
        parameters.Add("@MetaDescription", request.Seo?.MetaDescription);
        parameters.Add("@MetaKeywords", request.Seo?.MetaKeywords);
        parameters.Add("@CanonicalUrl", request.Seo?.CanonicalUrl);
        parameters.Add("@AdminUserId", adminUserId);

        return await connection.ExecuteScalarAsync<int>(
            "dbo.usp_Category_Save",
            parameters,
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "dbo.usp_Category_Delete",
            new { Id = id, AdminUserId = adminUserId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "dbo.usp_Category_UpdateStatus",
            new { Id = request.Id, IsActive = (request.Status == 1), AdminUserId = adminUserId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<List<IdNamePair>> GetLookupAsync(CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        return (await connection.QueryAsync<IdNamePair>(
            "dbo.usp_Category_Lookup",
            commandType: CommandType.StoredProcedure)).AsList();
    }
}
