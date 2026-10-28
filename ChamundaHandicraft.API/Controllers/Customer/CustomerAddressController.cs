using System.Security.Claims;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Customers.Domain.IServices;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.API.Controllers.Customer;

/// <summary>
/// Storefront Customer address management controller.
/// Downstream target of APIGateway routes: /Shop/Account/* -> /api/customer/account/*
/// </summary>
[ApiController]
[Route("api/customer/account")]
public class CustomerAddressController : ControllerBase
{
    private readonly ICustomerAddressService _addressService;
    private readonly ILogger<CustomerAddressController> _logger;

    public CustomerAddressController(
        ICustomerAddressService addressService,
        ILogger<CustomerAddressController> logger)
    {
        _addressService = addressService;
        _logger = logger;
    }

    private int GetCustomerId()
    {
        var idClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                   ?? User.FindFirst("CustomerId")?.Value;

        if (int.TryParse(idClaim, out int cid) && cid > 0)
        {
            return cid;
        }

        if (Request.Headers.TryGetValue("X-Customer-Id", out var headerVal) &&
            int.TryParse(headerVal.FirstOrDefault(), out int hCid) && hCid > 0)
        {
            return hCid;
        }

        if (Request.Query.TryGetValue("customerId", out var qVal) &&
            int.TryParse(qVal.FirstOrDefault(), out int qCid) && qCid > 0)
        {
            return qCid;
        }

        return 0;
    }

    /// <summary>
    /// Gets customer's address list with pagination, search and sort.
    /// Route: GET /api/customer/account/addresslist OR /api/customer/account/addresses
    /// </summary>
    [HttpGet("addresslist")]
    [HttpGet("addresses")]
    public async Task<ActionResult<ResponseViewModel<PagedResult<AddressViewModel>>>> GetList(
        [FromQuery] string? search = null,
        [FromQuery] string? sortBy = null,
        [FromQuery] bool sortDescending = false,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] int? customerId = null)
    {
        int cid = customerId ?? GetCustomerId();
        if (cid <= 0)
        {
            return StatusCode((int)ApiStatusCode.Unauthorized, ResponseViewModel<PagedResult<AddressViewModel>>.Fail("Unauthorized customer.", ApiStatusCode.Unauthorized));
        }

        var request = new CustomerAddressListRequest
        {
            CustomerId = cid,
            Search = search,
            SortBy = sortBy,
            SortDescending = sortDescending,
            Page = page,
            PageSize = pageSize
        };

        var response = await _addressService.GetListAsync(request);
        return StatusCode((int)response.StatusCode, response);
    }

    /// <summary>
    /// Gets a single customer address by ID.
    /// Route: GET /api/customer/account/address/{id}
    /// </summary>
    [HttpGet("address/{id:int}")]
    public async Task<ActionResult<ResponseViewModel<AddressViewModel>>> GetById(
        int id, [FromQuery] int? customerId = null)
    {
        int cid = customerId ?? GetCustomerId();
        if (cid <= 0)
        {
            return StatusCode((int)ApiStatusCode.Unauthorized, ResponseViewModel<AddressViewModel>.Fail("Unauthorized customer.", ApiStatusCode.Unauthorized));
        }

        var response = await _addressService.GetByIdAsync(id, cid);
        return StatusCode((int)response.StatusCode, response);
    }

    /// <summary>
    /// Creates or updates an address.
    /// Route: POST /api/customer/account/addresssave OR /api/customer/account/address
    /// </summary>
    [HttpPost("addresssave")]
    [HttpPost("address")]
    public async Task<ActionResult<ResponseViewModel<int>>> Save(
        [FromBody] CustomerAddressSaveRequest request, [FromQuery] int? customerId = null)
    {
        int cid = customerId ?? GetCustomerId();
        if (cid <= 0)
        {
            return StatusCode((int)ApiStatusCode.Unauthorized, ResponseViewModel<int>.Fail("Unauthorized customer.", ApiStatusCode.Unauthorized));
        }

        request.CustomerId = cid;
        var response = await _addressService.SaveAsync(request);
        return StatusCode((int)response.StatusCode, response);
    }

    /// <summary>
    /// Deletes a customer address.
    /// Route: POST /api/customer/account/addressdelete OR DELETE /api/customer/account/address/{id}
    /// </summary>
    [HttpPost("addressdelete")]
    [HttpDelete("address/{id:int}")]
    public async Task<ActionResult<ResponseViewModel<bool>>> Delete(
        [FromRoute(Name = "id")] int? routeId = null,
        [FromQuery(Name = "id")] int? queryId = null,
        [FromQuery] int? customerId = null)
    {
        int addressId = (routeId.HasValue && routeId.Value > 0) ? routeId.Value : (queryId ?? 0);
        int cid = customerId ?? GetCustomerId();
        if (cid <= 0)
        {
            return StatusCode((int)ApiStatusCode.Unauthorized, ResponseViewModel<bool>.Fail("Unauthorized customer.", ApiStatusCode.Unauthorized));
        }

        var response = await _addressService.DeleteAsync(addressId, cid);
        return StatusCode((int)response.StatusCode, response);
    }

    /// <summary>
    /// Sets an address as the default delivery address.
    /// Route: POST /api/customer/account/setdefaultaddress OR POST /api/customer/account/address/{id}/default
    /// </summary>
    [HttpPost("setdefaultaddress")]
    [HttpPost("address/{id:int}/default")]
    public async Task<ActionResult<ResponseViewModel<bool>>> SetDefault(
        [FromRoute(Name = "id")] int? routeId = null,
        [FromQuery(Name = "id")] int? queryId = null,
        [FromQuery] int? customerId = null)
    {
        int addressId = (routeId.HasValue && routeId.Value > 0) ? routeId.Value : (queryId ?? 0);
        int cid = customerId ?? GetCustomerId();
        if (cid <= 0)
        {
            return StatusCode((int)ApiStatusCode.Unauthorized, ResponseViewModel<bool>.Fail("Unauthorized customer.", ApiStatusCode.Unauthorized));
        }

        var response = await _addressService.SetDefaultAsync(addressId, cid);
        return StatusCode((int)response.StatusCode, response);
    }
}
