using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace Testimonials.Domain.IServices;

public interface ITestimonialRepository
{
    Task<PagedResult<TestimonialGridItem>> GetGridAsync(DataTableRequest request, CancellationToken ct = default);
    Task<TestimonialSaveRequest?> GetByIdAsync(int id, CancellationToken ct = default);
    Task<TestimonialGridItem?> GetDetailAsync(int id, CancellationToken ct = default);
    Task<int> SaveAsync(TestimonialSaveRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<List<TestimonialGridItem>> GetFeaturedAsync(int count = 10, CancellationToken ct = default);
}
