using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.Extensions.Logging;
using Testimonials.Domain.IServices;

namespace Testimonials.Application.Services;

public class TestimonialService : ITestimonialService
{
    private readonly ITestimonialRepository _repository;
    private readonly ILogger<TestimonialService> _logger;

    public TestimonialService(ITestimonialRepository repository, ILogger<TestimonialService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<ResponseViewModel<PagedResult<TestimonialGridItem>>> GetGridAsync(DataTableRequest request, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetGridAsync(request, ct);
            return ResponseViewModel<PagedResult<TestimonialGridItem>>.Success(data, "Testimonials retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving testimonial grid.");
            return ResponseViewModel<PagedResult<TestimonialGridItem>>.Fail("An error occurred while retrieving testimonials.");
        }
    }

    public async Task<ResponseViewModel<TestimonialSaveRequest>> GetByIdAsync(int id, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetByIdAsync(id, ct);
            if (data == null)
            {
                return ResponseViewModel<TestimonialSaveRequest>.Fail("Testimonial not found.");
            }
            return ResponseViewModel<TestimonialSaveRequest>.Success(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving testimonial with ID {Id}.", id);
            return ResponseViewModel<TestimonialSaveRequest>.Fail("An error occurred while retrieving testimonial details.");
        }
    }

    public async Task<ResponseViewModel<TestimonialGridItem>> GetDetailAsync(int id, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetDetailAsync(id, ct);
            if (data == null)
            {
                return ResponseViewModel<TestimonialGridItem>.Fail("Testimonial not found.");
            }
            return ResponseViewModel<TestimonialGridItem>.Success(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving testimonial details with ID {Id}.", id);
            return ResponseViewModel<TestimonialGridItem>.Fail("An error occurred while retrieving testimonial details.");
        }
    }

    public async Task<ResponseViewModel<int>> SaveAsync(TestimonialSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var newId = await _repository.SaveAsync(request, adminUserId, ct);
            return ResponseViewModel<int>.Success(newId, "Testimonial saved successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<int>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving testimonial.");
            return ResponseViewModel<int>.Fail("An unexpected error occurred while saving testimonial.");
        }
    }

    public async Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var result = await _repository.DeleteAsync(id, adminUserId, ct);
            return ResponseViewModel<bool>.Success(result, "Testimonial deleted successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting testimonial ID {Id}.", id);
            return ResponseViewModel<bool>.Fail("An unexpected error occurred while deleting testimonial.");
        }
    }

    public async Task<ResponseViewModel<bool>> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            var result = await _repository.UpdateStatusAsync(request, adminUserId, ct);
            return ResponseViewModel<bool>.Success(result, "Testimonial status updated successfully.");
        }
        catch (InvalidOperationException ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating status for testimonial ID {Id}.", request.Id);
            return ResponseViewModel<bool>.Fail("An unexpected error occurred while updating testimonial status.");
        }
    }

    public async Task<ResponseViewModel<List<TestimonialGridItem>>> GetFeaturedAsync(int count = 10, CancellationToken ct = default)
    {
        try
        {
            var data = await _repository.GetFeaturedAsync(count, ct);
            return ResponseViewModel<List<TestimonialGridItem>>.Success(data, "Featured testimonials retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving featured testimonials.");
            return ResponseViewModel<List<TestimonialGridItem>>.Fail("An error occurred while retrieving featured testimonials.");
        }
    }
}
