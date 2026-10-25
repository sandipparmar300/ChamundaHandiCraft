using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.Extensions.Logging;
using Promotions.Domain.IServices;

namespace Promotions.Application.Services;

public class CouponService : ICouponService
{
    private readonly ICouponRepository _repository;
    private readonly ILogger<CouponService> _logger;

    public CouponService(ICouponRepository repository, ILogger<CouponService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<ResponseViewModel<PagedResult<CouponGridItem>>> GetGridAsync(DataTableRequest request, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetGridAsync(request, ct);
            return ResponseViewModel<PagedResult<CouponGridItem>>.Success(data, "Coupons retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving coupon grid.");
            return ResponseViewModel<PagedResult<CouponGridItem>>.Fail("An error occurred while retrieving coupons.");
        }
    }

    public async Task<ResponseViewModel<CouponSaveRequest>> GetByIdAsync(int id, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetByIdAsync(id, ct);
            if (data == null)
            {
                return ResponseViewModel<CouponSaveRequest>.Fail("Coupon not found.");
            }
            return ResponseViewModel<CouponSaveRequest>.Success(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving coupon with ID {Id}.", id);
            return ResponseViewModel<CouponSaveRequest>.Fail("An error occurred while retrieving coupon details.");
        }
    }

    public async Task<ResponseViewModel<CouponGridItem>> GetDetailAsync(int id, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetDetailAsync(id, ct);
            if (data == null)
            {
                return ResponseViewModel<CouponGridItem>.Fail("Coupon not found.");
            }
            return ResponseViewModel<CouponGridItem>.Success(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving coupon details with ID {Id}.", id);
            return ResponseViewModel<CouponGridItem>.Fail("An error occurred while retrieving coupon details.");
        }
    }

    public async Task<ResponseViewModel<int>> SaveAsync(CouponSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var newId = await _repository.SaveAsync(request, adminUserId, ct);
            return ResponseViewModel<int>.Success(newId, "Coupon saved successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<int>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving coupon.");
            return ResponseViewModel<int>.Fail("An unexpected error occurred while saving coupon.");
        }
    }

    public async Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var result = await _repository.DeleteAsync(id, adminUserId, ct);
            return ResponseViewModel<bool>.Success(result, "Coupon deleted successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting coupon ID {Id}.", id);
            return ResponseViewModel<bool>.Fail("An unexpected error occurred while deleting coupon.");
        }
    }

    public async Task<ResponseViewModel<bool>> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var result = await _repository.UpdateStatusAsync(request, adminUserId, ct);
            return ResponseViewModel<bool>.Success(result, "Coupon status updated successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating status for coupon ID {Id}.", request.Id);
            return ResponseViewModel<bool>.Fail("An unexpected error occurred while updating coupon status.");
        }
    }
}
