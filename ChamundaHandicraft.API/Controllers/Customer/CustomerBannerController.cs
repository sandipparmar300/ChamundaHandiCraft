using Banners.Domain.IServices;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.API.Controllers.Customer;

[ApiController]
[Route("api/customer/banner")]
public class CustomerBannerController : ControllerBase
{
    private readonly IBannerService _bannerService;

    public CustomerBannerController(IBannerService bannerService)
    {
        _bannerService = bannerService;
    }

    [HttpGet("ByPlacement")]
    public async Task<ActionResult<ResponseViewModel<List<BannerViewModel>>>> ByPlacement([FromQuery] string? placement, CancellationToken ct)
    {
        int placementId = 0;
        if (!string.IsNullOrWhiteSpace(placement))
        {
            if (int.TryParse(placement, out int parsedId))
            {
                placementId = parsedId;
            }
            else if (Enum.TryParse<BannerPlacement>(placement, true, out var parsedEnum))
            {
                placementId = (int)parsedEnum;
            }
        }

        var response = await _bannerService.GetByPlacementAsync(placementId, ct);
        return Ok(response);
    }
}
