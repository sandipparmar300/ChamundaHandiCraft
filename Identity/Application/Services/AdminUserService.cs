using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Identity.Domain.IServices;

namespace Identity.Application.Services;

public class AdminUserService : IAdminUserService
{
    private readonly IAdminUserRepository _adminUserRepository;
    private readonly IPasswordHasher _passwordHasher;

    public AdminUserService(IAdminUserRepository adminUserRepository, IPasswordHasher passwordHasher)
    {
        _adminUserRepository = adminUserRepository;
        _passwordHasher = passwordHasher;
    }

    public async Task<ResponseViewModel<PagedResult<AdminUserGridItem>>> GetGridAsync(DataTableRequest request, CancellationToken ct = default)
    {
        try
        {
            var result = await _adminUserRepository.GetGridAsync(request, ct);
            return ResponseViewModel<PagedResult<AdminUserGridItem>>.Success(result, "Admin users retrieved successfully.");
        }
        catch (Exception ex)
        {
            return ResponseViewModel<PagedResult<AdminUserGridItem>>.Fail(
                $"Failed to retrieve admin users: {ex.Message}", ApiStatusCode.ServerError);
        }
    }

    public async Task<ResponseViewModel<AdminUserSaveRequest>> GetByIdAsync(int id, CancellationToken ct = default)
    {
        try
        {
            var user = await _adminUserRepository.GetByIdAsync(id, ct);
            if (user == null)
            {
                return ResponseViewModel<AdminUserSaveRequest>.Fail("Admin user not found.", ApiStatusCode.NotFound);
            }

            return ResponseViewModel<AdminUserSaveRequest>.Success(user, "Admin user details retrieved successfully.");
        }
        catch (Exception ex)
        {
            return ResponseViewModel<AdminUserSaveRequest>.Fail(
                $"Failed to retrieve admin user: {ex.Message}", ApiStatusCode.ServerError);
        }
    }

    public async Task<ResponseViewModel<int>> SaveAsync(AdminUserSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(request.Email))
            {
                return ResponseViewModel<int>.Fail("Email is required.", ApiStatusCode.BadRequest);
            }

            // On insert, password is mandatory
            if (request.Id <= 0 && string.IsNullOrWhiteSpace(request.Password))
            {
                return ResponseViewModel<int>.Fail("Password is required for new admin user.", ApiStatusCode.BadRequest);
            }

            // Hash password if provided
            if (!string.IsNullOrWhiteSpace(request.Password))
            {
                request.Password = _passwordHasher.HashPassword(request.Password);
            }
            else
            {
                request.Password = null;
            }

            var id = await _adminUserRepository.SaveAsync(request, adminUserId, ct);
            if (id <= 0)
            {
                return ResponseViewModel<int>.Fail("Failed to save admin user.", ApiStatusCode.BadRequest);
            }

            return ResponseViewModel<int>.Success(id, "Admin user saved successfully.");
        }
        catch (Exception ex)
        {
            return ResponseViewModel<int>.Fail(ex.Message, ApiStatusCode.BadRequest);
        }
    }

    public async Task<ResponseViewModel<bool>> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            if (id == 1)
            {
                return ResponseViewModel<bool>.Fail("Primary Super Admin account cannot be deleted.", ApiStatusCode.BadRequest);
            }

            var success = await _adminUserRepository.DeleteAsync(id, adminUserId, ct);
            return ResponseViewModel<bool>.Success(success, "Admin user deleted successfully.");
        }
        catch (Exception ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message, ApiStatusCode.BadRequest);
        }
    }

    public async Task<ResponseViewModel<bool>> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            bool isActive = request.Status == 1;
            if (request.Id == 1 && !isActive)
            {
                return ResponseViewModel<bool>.Fail("Primary Super Admin account cannot be deactivated.", ApiStatusCode.BadRequest);
            }

            var success = await _adminUserRepository.UpdateStatusAsync(request.Id, isActive, adminUserId, ct);
            return ResponseViewModel<bool>.Success(success, "Status updated successfully.");
        }
        catch (Exception ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message, ApiStatusCode.BadRequest);
        }
    }

    public async Task<ResponseViewModel<bool>> ChangePasswordAsync(AdminUserChangePasswordRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(request.NewPassword))
            {
                return ResponseViewModel<bool>.Fail("New password is required.", ApiStatusCode.BadRequest);
            }

            if (request.NewPassword != request.ConfirmPassword)
            {
                return ResponseViewModel<bool>.Fail("Passwords do not match.", ApiStatusCode.BadRequest);
            }

            var hash = _passwordHasher.HashPassword(request.NewPassword);
            var success = await _adminUserRepository.ChangePasswordAsync(request.Id, hash, adminUserId, ct);
            return ResponseViewModel<bool>.Success(success, "Password updated successfully.");
        }
        catch (Exception ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message, ApiStatusCode.BadRequest);
        }
    }
}
