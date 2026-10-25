using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.Extensions.Logging;
using Settings.Domain.IServices;

namespace Settings.Application.Services;

public class SettingsService : ISettingsService
{
    private readonly ISettingsRepository _repository;
    private readonly ILogger<SettingsService> _logger;

    public SettingsService(ISettingsRepository repository, ILogger<SettingsService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<ResponseViewModel<StorefrontConfigViewModel>> GetStorefrontConfigAsync(CancellationToken ct = default)
    {
        try
        {
            var config = await _repository.GetStorefrontConfigAsync(ct);
            return ResponseViewModel<StorefrontConfigViewModel>.Success(config, "Storefront configuration retrieved successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving storefront configuration.");
            return ResponseViewModel<StorefrontConfigViewModel>.Fail("An error occurred while retrieving storefront configuration.");
        }
    }
}
