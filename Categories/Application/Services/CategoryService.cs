using Categories.Domain.IServices;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;

namespace Categories.Application.Services;

public class CategoryService : ICategoryService
{
    private readonly ICategoryRepository _repository;
    private readonly ILogger<CategoryService> _logger;

    public CategoryService(ICategoryRepository repository, ILogger<CategoryService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<ResponseViewModel<List<CategoryViewModel>>> GetTreeAsync(CancellationToken ct = default)
    {
        try
        {
            var tree = await _repository.GetTreeAsync(ct);
            return ResponseViewModel<List<CategoryViewModel>>.Success(tree, "Category tree retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving category tree.");
            return ResponseViewModel<List<CategoryViewModel>>.Fail("An error occurred while retrieving the category tree.");
        }
    }

    public async Task<ResponseViewModel<PagedResult<CategoryGridItem>>> GetGridAsync(DataTableRequest request, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetGridAsync(request, ct);
            return ResponseViewModel<PagedResult<CategoryGridItem>>.Success(data, "Categories retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving category grid.");
            return ResponseViewModel<PagedResult<CategoryGridItem>>.Fail("An error occurred while retrieving categories.");
        }
    }

    public async Task<ResponseViewModel<CategorySaveRequest>> GetByIdAsync(int id, CancellationToken ct = default)
    {
        try
        {
            var category = await _repository.GetByIdAsync(id, ct);
            if (category == null)
            {
                return ResponseViewModel<CategorySaveRequest>.Fail("Category not found.", ApiStatusCode.NotFound);
            }
            return ResponseViewModel<CategorySaveRequest>.Success(category);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving category ID {CategoryId}", id);
            return ResponseViewModel<CategorySaveRequest>.Fail("An error occurred while fetching the category.");
        }
    }

    public async Task<ResponseViewModel<int>> SaveAsync(CategorySaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(request.Name))
            {
                return ResponseViewModel<int>.Fail("Category name is required.", ApiStatusCode.ValidationFailed);
            }

            var id = await _repository.SaveAsync(request, adminUserId, ct);
            return ResponseViewModel<int>.Success(id, "Category saved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving category.");
            return ResponseViewModel<int>.Fail(ex.Message);
        }
    }

    public async Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var success = await _repository.DeleteAsync(id, adminUserId, ct);
            return ResponseViewModel<bool>.Success(success, "Category deleted successfully.");
        }
        catch (SqlException ex)
        {
            _logger.LogWarning(ex, "SQL constraint error deleting category ID {CategoryId}", id);
            return ResponseViewModel<bool>.Fail(ex.Message, ApiStatusCode.BadRequest);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting category ID {CategoryId}", id);
            return ResponseViewModel<bool>.Fail("An error occurred while deleting the category.");
        }
    }

    public async Task<ResponseViewModel<bool>> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var success = await _repository.UpdateStatusAsync(request, adminUserId, ct);
            return ResponseViewModel<bool>.Success(success, "Category status updated successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating category status ID {CategoryId}", request.Id);
            return ResponseViewModel<bool>.Fail("An error occurred while updating the status.");
        }
    }

    public async Task<ResponseViewModel<List<IdNamePair>>> GetLookupAsync(CancellationToken ct = default)
    {
        try
        {
            var list = await _repository.GetLookupAsync(ct);
            return ResponseViewModel<List<IdNamePair>>.Success(list);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving category lookup.");
            return ResponseViewModel<List<IdNamePair>>.Fail("An error occurred while fetching category lookups.");
        }
    }
}
