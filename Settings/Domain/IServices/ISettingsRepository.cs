using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace Settings.Domain.IServices;

public interface ISettingsRepository
{
    Task<StorefrontConfigViewModel> GetStorefrontConfigAsync(CancellationToken ct = default);
}
