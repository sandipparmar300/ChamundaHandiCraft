using Categories.Domain.IServices;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.Extensions.Logging;

namespace Categories.Application.Services;

public class MenuService : IMenuService
{
    private readonly IMenuRepository _repository;
    private readonly ILogger<MenuService> _logger;

    public MenuService(IMenuRepository repository, ILogger<MenuService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<ResponseViewModel<PagedResult<MenuGridItem>>> GetGridAsync(DataTableRequest request, string? location = null, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetGridAsync(request, location, ct);
            return ResponseViewModel<PagedResult<MenuGridItem>>.Success(data, "Menu items retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving menu grid.");
            return ResponseViewModel<PagedResult<MenuGridItem>>.Fail("An error occurred while retrieving menu items.");
        }
    }

    public async Task<ResponseViewModel<MenuGridItem>> GetByIdAsync(int id, CancellationToken ct = default)
    {
        try
        {
            var item = await _repository.GetByIdAsync(id, ct);
            if (item == null)
            {
                return ResponseViewModel<MenuGridItem>.Fail("Menu item not found.", ApiStatusCode.NotFound);
            }
            return ResponseViewModel<MenuGridItem>.Success(item);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching menu item ID {MenuId}", id);
            return ResponseViewModel<MenuGridItem>.Fail("An error occurred while fetching the menu item.");
        }
    }

    public async Task<ResponseViewModel<int>> SaveAsync(MenuGridItem request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(request.Title))
            {
                return ResponseViewModel<int>.Fail("Menu title is required.", ApiStatusCode.ValidationFailed);
            }

            var id = await _repository.SaveAsync(request, adminUserId, ct);
            return ResponseViewModel<int>.Success(id, "Menu item saved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving menu item.");
            return ResponseViewModel<int>.Fail(ex.Message);
        }
    }

    public async Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var success = await _repository.DeleteAsync(id, adminUserId, ct);
            return ResponseViewModel<bool>.Success(success, "Menu item deleted successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting menu item ID {MenuId}", id);
            return ResponseViewModel<bool>.Fail("An error occurred while deleting the menu item.");
        }
    }

    public async Task<ResponseViewModel<bool>> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var success = await _repository.UpdateStatusAsync(request, adminUserId, ct);
            return ResponseViewModel<bool>.Success(success, "Menu item status updated successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating menu item status ID {MenuId}", request.Id);
            return ResponseViewModel<bool>.Fail("An error occurred while updating the status.");
        }
    }

    public async Task<ResponseViewModel<List<IdNamePair>>> GetLookupAsync(string? location = null, CancellationToken ct = default)
    {
        try
        {
            var list = await _repository.GetLookupAsync(location, ct);
            return ResponseViewModel<List<IdNamePair>>.Success(list);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving menu lookup.");
            return ResponseViewModel<List<IdNamePair>>.Fail("An error occurred while fetching menu lookups.");
        }
    }
}
