using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// User Management - Admin Users administration.
/// </summary>
public class AdminUserController : AdminCrudController<AdminUserGridItem, AdminUserSaveRequest>
{
    private readonly IFileUploadService _fileUploadService;

    public AdminUserController(IAdminClient client, IFileUploadService fileUploadService)
        : base(client)
    {
        _fileUploadService = fileUploadService;
    }

    protected override string Module => "AdminUser";

    public override async Task<IActionResult> Index(int page = 1, string? search = null, CancellationToken ct = default)
    {
        var rolesResponse = await Client.GetLookupAsync(ApiEndPoint.Crud.Lookup("Role"), null, ct);
        ViewBag.Roles = rolesResponse.Data ?? new List<IdNamePair>();

        return await base.Index(page, search, ct);
    }

    public override async Task<IActionResult> Add()
    {
        var rolesResponse = await Client.GetLookupAsync(ApiEndPoint.Crud.Lookup("Role"));
        ViewBag.Roles = rolesResponse.Data ?? new List<IdNamePair>();

        return View("Create", new AdminUserSaveRequest());
    }

    public override async Task<IActionResult> Edit(int id, CancellationToken ct = default)
    {
        var rolesResponse = await Client.GetLookupAsync(ApiEndPoint.Crud.Lookup("Role"), null, ct);
        ViewBag.Roles = rolesResponse.Data ?? new List<IdNamePair>();

        var response = await Client.GetByIdAsync<AdminUserSaveRequest>(ApiEndPoint.Crud.GetById(Module), id, ct);
        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message ?? "Admin user not found.";
            return RedirectToAction(nameof(Index));
        }

        return View("Create", response.Data);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public override async Task<IActionResult> Save(AdminUserSaveRequest request, CancellationToken ct = default)
    {
        // Handle file upload
        if (Request.Form.Files["Photo"] is { Length: > 0 } photoFile)
        {
            var photoUrl = await _fileUploadService.SaveFileAsync(photoFile, "users", ct);
            if (!string.IsNullOrEmpty(photoUrl))
            {
                request.PhotoUrl = photoUrl;
            }
        }

        // Validate password
        if (request.Id <= 0 && string.IsNullOrWhiteSpace(request.Password))
        {
            TempData["ErrorMessage"] = "Password is required when creating a new admin user.";
            var roles = await Client.GetLookupAsync(ApiEndPoint.Crud.Lookup("Role"), null, ct);
            ViewBag.Roles = roles.Data ?? new List<IdNamePair>();
            return View("Create", request);
        }

        if (!string.IsNullOrWhiteSpace(request.Password) && request.Password != request.ConfirmPassword)
        {
            TempData["ErrorMessage"] = "Password and Confirm Password do not match.";
            var roles = await Client.GetLookupAsync(ApiEndPoint.Crud.Lookup("Role"), null, ct);
            ViewBag.Roles = roles.Data ?? new List<IdNamePair>();
            return View("Create", request);
        }

        var response = await Client.SaveAsync(ApiEndPoint.Crud.Save(Module), request, ct);
        if (!response.IsSuccess)
        {
            TempData["ErrorMessage"] = response.Message ?? "Failed to save admin user.";
            var roles = await Client.GetLookupAsync(ApiEndPoint.Crud.Lookup("Role"), null, ct);
            ViewBag.Roles = roles.Data ?? new List<IdNamePair>();
            return View("Create", request);
        }

        TempData["SuccessMessage"] = response.Message ?? "Admin user saved successfully.";

        var saveAndNew = string.Equals(Request.Form["saveAndNew"], "true", StringComparison.OrdinalIgnoreCase);
        if (saveAndNew)
        {
            return RedirectToAction(nameof(Add));
        }

        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    public async Task<IActionResult> UploadPhoto(IFormFile file, CancellationToken ct = default)
    {
        if (file == null || file.Length == 0)
            return Json(new { success = false, message = "No file uploaded." });

        var url = await _fileUploadService.SaveFileAsync(file, "users", ct);
        return Json(new { success = !string.IsNullOrEmpty(url), url });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ChangePassword([FromBody] AdminUserChangePasswordRequest request, CancellationToken ct = default)
    {
        if (request == null || request.Id <= 0)
        {
            return Json(new { success = false, message = "Invalid request." });
        }

        if (string.IsNullOrWhiteSpace(request.NewPassword))
        {
            return Json(new { success = false, message = "New password is required." });
        }

        if (request.NewPassword != request.ConfirmPassword)
        {
            return Json(new { success = false, message = "Passwords do not match." });
        }

        var response = await Client.ChangeAdminUserPasswordAsync(request, ct);
        return Json(new { success = response.IsSuccess, message = response.Message });
    }

    public override async Task<IActionResult> Details(int id, CancellationToken ct = default)
    {
        var response = await Client.GetByIdAsync<AdminUserSaveRequest>(ApiEndPoint.Crud.GetById(Module), id, ct);
        if (!response.IsSuccess || response.Data is null)
        {
            TempData["ErrorMessage"] = response.Message ?? "Admin user not found.";
            return RedirectToAction(nameof(Index));
        }

        return View(response.Data);
    }
}
