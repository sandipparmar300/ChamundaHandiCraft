using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace Testimonials.Domain.IServices;

public interface ITestimonialService
{
    Task<ResponseViewModel<PagedResult<TestimonialGridItem>>> GetGridAsync(DataTableRequest request, CancellationToken ct = default);
    Task<ResponseViewModel<TestimonialSaveRequest>> GetByIdAsync(int id, CancellationToken ct = default);
    Task<ResponseViewModel<TestimonialGridItem>> GetDetailAsync(int id, CancellationToken ct = default);
    Task<ResponseViewModel<int>> SaveAsync(TestimonialSaveRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<bool>> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<ResponseViewModel<List<TestimonialGridItem>>> GetFeaturedAsync(int count = 10, CancellationToken ct = default);
}
