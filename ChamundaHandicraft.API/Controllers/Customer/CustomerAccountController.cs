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
/// Storefront Customer account controller.
/// Downstream target of APIGateway routes: /Shop/Account/* -> /api/customer/account/*
/// </summary>
[ApiController]
[Route("api/customer/account")]
public class CustomerAccountController : ControllerBase
{
    private readonly ICustomerProfileService _profileService;
    private readonly ILogger<CustomerAccountController> _logger;

    public CustomerAccountController(
        ICustomerProfileService profileService,
        ILogger<CustomerAccountController> logger)
    {
        _profileService = profileService;
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
    /// Returns customer account dashboard summary.
    /// Route: GET /api/customer/account/dashboard
    /// </summary>
    [HttpGet("dashboard")]
    public async Task<ActionResult<ResponseViewModel<CustomerDashboardViewModel>>> Dashboard([FromQuery] int? customerId = null)
    {
        int cid = customerId ?? GetCustomerId();
        if (cid <= 0)
        {
            return StatusCode((int)ApiStatusCode.Unauthorized, ResponseViewModel<CustomerDashboardViewModel>.Fail("Unauthorized customer.", ApiStatusCode.Unauthorized));
        }

        var response = await _profileService.GetDashboardAsync(cid);
        return StatusCode((int)response.StatusCode, response);
    }

    /// <summary>
    /// Returns customer profile details.
    /// Route: GET /api/customer/account/profile
    /// </summary>
    [HttpGet("profile")]
    public async Task<ActionResult<ResponseViewModel<CustomerProfileViewModel>>> GetProfile([FromQuery] int? customerId = null)
    {
        int cid = customerId ?? GetCustomerId();
        if (cid <= 0)
        {
            return StatusCode((int)ApiStatusCode.Unauthorized, ResponseViewModel<CustomerProfileViewModel>.Fail("Unauthorized customer.", ApiStatusCode.Unauthorized));
        }

        var response = await _profileService.GetProfileAsync(cid);
        return StatusCode((int)response.StatusCode, response);
    }

    /// <summary>
    /// Updates customer personal profile details.
    /// Route: POST /api/customer/account/profilesave
    /// </summary>
    [HttpPost("profilesave")]
    [HttpPost("profile-save")]
    public async Task<ActionResult<ResponseViewModel<bool>>> UpdateProfile([FromBody] CustomerProfileUpdateRequest request, [FromQuery] int? customerId = null)
    {
        int cid = customerId ?? GetCustomerId();
        if (cid <= 0)
        {
            return StatusCode((int)ApiStatusCode.Unauthorized, ResponseViewModel<bool>.Fail("Unauthorized customer.", ApiStatusCode.Unauthorized));
        }

        var response = await _profileService.UpdateProfileAsync(cid, request);
        return StatusCode((int)response.StatusCode, response);
    }

    /// <summary>
    /// Changes customer password.
    /// Route: POST /api/customer/account/changepassword
    /// </summary>
    [HttpPost("changepassword")]
    [HttpPost("change-password")]
    public async Task<ActionResult<ResponseViewModel<bool>>> ChangePassword([FromBody] CustomerChangePasswordRequest request, [FromQuery] int? customerId = null)
    {
        int cid = customerId ?? GetCustomerId();
        if (cid <= 0)
        {
            return StatusCode((int)ApiStatusCode.Unauthorized, ResponseViewModel<bool>.Fail("Unauthorized customer.", ApiStatusCode.Unauthorized));
        }

        var response = await _profileService.ChangePasswordAsync(cid, request);
        return StatusCode((int)response.StatusCode, response);
    }
}
