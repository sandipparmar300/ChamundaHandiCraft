using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;
using Settings.Domain.IServices;

namespace ChamundaHandicraft.API.Controllers.Customer;

[ApiController]
[Route("api/customer/settings")]
public class CustomerSettingsController : ControllerBase
{
    private readonly ISettingsService _settingsService;

    public CustomerSettingsController(ISettingsService settingsService)
    {
        _settingsService = settingsService;
    }

    [HttpGet("StorefrontConfig")]
    public async Task<ActionResult<ResponseViewModel<StorefrontConfigViewModel>>> GetStorefrontConfig(CancellationToken ct)
    {
        var response = await _settingsService.GetStorefrontConfigAsync(ct);
        return Ok(response);
    }
}
