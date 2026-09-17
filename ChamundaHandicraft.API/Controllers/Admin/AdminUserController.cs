using ChamundaHandicraft.API.Services.Email;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Identity.Application.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace ChamundaHandicraft.API.Controllers.Admin;

[ApiController]
[Route("api/admin/[controller]")]
public class AdminUserController : ControllerBase
{
    private readonly IAdminUserService _adminUserService;
    private readonly IEmailService _emailService;
    private readonly IConfiguration _configuration;
    private readonly ILogger<AdminUserController> _logger;

    public AdminUserController(
        IAdminUserService adminUserService,
        IEmailService emailService,
        IConfiguration configuration,
        ILogger<AdminUserController> logger)
    {
        _adminUserService = adminUserService;
        _emailService = emailService;
        _configuration = configuration;
        _logger = logger;
    }

    [HttpPost("GridList")]
    public async Task<ActionResult<ResponseViewModel<PagedResult<AdminUserGridItem>>>> GridList([FromBody] DataTableRequest request, CancellationToken ct)
    {
        var response = await _adminUserService.GetGridAsync(request, ct);
        return Ok(response);
    }

    [HttpGet("GetById")]
    public async Task<ActionResult<ResponseViewModel<AdminUserSaveRequest>>> GetById([FromQuery] int id, CancellationToken ct)
    {
        var response = await _adminUserService.GetByIdAsync(id, ct);
        return Ok(response);
    }

    [HttpPost("Save")]
    public async Task<ActionResult<ResponseViewModel<int>>> Save([FromBody] AdminUserSaveRequest request, CancellationToken ct)
    {
        var isNewUser = request.Id <= 0;
        var plainPassword = request.Password;

        var response = await _adminUserService.SaveAsync(request, null, ct);

        if (response.IsSuccess && isNewUser && !string.IsNullOrWhiteSpace(request.Email) && !string.IsNullOrWhiteSpace(plainPassword))
        {
            try
            {
                var portalUrl = _configuration["AdminPortalBaseUrl"] ?? "https://localhost:7140";
                var companyName = _configuration["Email:FromName"] ?? "Chamunda Handicraft";
                var supportEmail = _configuration["Email:FromAddress"] ?? "sandipparmar300@gmail.com";

                var tokens = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                {
                    ["RecipientName"] = !string.IsNullOrWhiteSpace(request.FullName) 
                        ? request.FullName 
                        : $"{request.FirstName} {request.LastName}".Trim(),
                    ["Email"] = request.Email,
                    ["Password"] = plainPassword,
                    ["RoleName"] = !string.IsNullOrWhiteSpace(request.RoleName) ? request.RoleName : "Admin User",
                    ["AdminPortalUrl"] = portalUrl,
                    ["CompanyName"] = companyName,
                    ["SupportEmail"] = supportEmail,
                    ["CurrentYear"] = DateTime.UtcNow.Year.ToString()
                };

                _ = Task.Run(async () =>
                {
                    try
                    {
                        await _emailService.SendEmailWithTemplateAsync(
                            request.Email,
                            tokens["RecipientName"],
                            "AdminUserOnboarding",
                            tokens);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Failed to dispatch onboarding email to {Email}", request.Email);
                    }
                }, CancellationToken.None);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error preparing onboarding email for {Email}", request.Email);
            }
        }

        return Ok(response);
    }

    [HttpDelete("Delete")]
    public async Task<ActionResult<ResponseViewModel<bool>>> Delete([FromQuery] int id, CancellationToken ct)
    {
        var response = await _adminUserService.DeleteAsync(id, null, ct);
        return Ok(response);
    }

    [HttpPost("UpdateStatus")]
    public async Task<ActionResult<ResponseViewModel<bool>>> UpdateStatus([FromBody] UpdateStatusRequest request, CancellationToken ct)
    {
        var response = await _adminUserService.UpdateStatusAsync(request, null, ct);
        return Ok(response);
    }

    [HttpPost("ChangePassword")]
    public async Task<ActionResult<ResponseViewModel<bool>>> ChangePassword([FromBody] AdminUserChangePasswordRequest request, CancellationToken ct)
    {
        var response = await _adminUserService.ChangePasswordAsync(request, null, ct);
        return Ok(response);
    }
}
