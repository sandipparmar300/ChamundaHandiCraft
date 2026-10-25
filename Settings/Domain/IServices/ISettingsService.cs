using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace Settings.Domain.IServices;

public interface ISettingsService
{
    Task<ResponseViewModel<StorefrontConfigViewModel>> GetStorefrontConfigAsync(CancellationToken ct = default);
}
