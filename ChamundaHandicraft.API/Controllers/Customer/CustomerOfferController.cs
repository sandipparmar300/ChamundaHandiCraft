using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;
using Promotions.Domain.IServices;

namespace ChamundaHandicraft.API.Controllers.Customer;

[ApiController]
[Route("api/customer/offer")]
[Route("api/customer/promotion")]
public class CustomerOfferController : ControllerBase
{
    private readonly IOfferService _offerService;

    public CustomerOfferController(IOfferService offerService)
    {
        _offerService = offerService;
    }

    [HttpGet("FlashSale")]
    public async Task<ActionResult<ResponseViewModel<FlashSaleOfferViewModel?>>> GetFlashSale(CancellationToken ct)
    {
        var response = await _offerService.GetFlashSaleOfferAsync(ct);
        return Ok(response);
    }
}
