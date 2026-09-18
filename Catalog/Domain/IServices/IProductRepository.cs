using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace Catalog.Domain.IServices;

public interface IProductRepository
{
    Task<PagedResult<ProductGridItem>> GetGridAsync(DataTableRequest request, CancellationToken ct = default);
    Task<ProductSaveRequest?> GetByIdAsync(int id, CancellationToken ct = default);
    Task<int> SaveAsync(ProductSaveRequest request, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default);
    Task<bool> UpdateStatusAsync(int id, byte status, int? adminUserId = null, CancellationToken ct = default);
    Task<ProductLookupsViewModel> GetLookupsAsync(CancellationToken ct = default);
    Task<List<IdNamePair>> GetLookupAsync(CancellationToken ct = default);
    Task<List<IdNamePair>> GetVariantsLookupAsync(int? productId = null, CancellationToken ct = default);
}
