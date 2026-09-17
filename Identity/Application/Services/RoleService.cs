using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Identity.Domain.IServices;

namespace Identity.Application.Services;

public class RoleService : IRoleService
{
    private readonly IRoleRepository _roleRepository;

    public RoleService(IRoleRepository roleRepository)
    {
        _roleRepository = roleRepository;
    }

    public async Task<ResponseViewModel<PagedResult<RoleGridItem>>> GetGridAsync(DataTableRequest request, CancellationToken ct = default)
    {
        try
        {
            var result = await _roleRepository.GetGridAsync(request, ct);
            return ResponseViewModel<PagedResult<RoleGridItem>>.Success(result, "Roles retrieved successfully.");
        }
        catch (Exception ex)
        {
            return ResponseViewModel<PagedResult<RoleGridItem>>.Fail(
                $"Failed to retrieve roles: {ex.Message}", ApiStatusCode.ServerError);
        }
    }

    public async Task<ResponseViewModel<RoleSaveRequest>> GetByIdAsync(int id, CancellationToken ct = default)
    {
        try
        {
            var role = await _roleRepository.GetByIdAsync(id, ct);
            if (role == null)
            {
                return ResponseViewModel<RoleSaveRequest>.Fail("Role not found.", ApiStatusCode.NotFound);
            }

            return ResponseViewModel<RoleSaveRequest>.Success(role, "Role retrieved successfully.");
        }
        catch (Exception ex)
        {
            return ResponseViewModel<RoleSaveRequest>.Fail(
                $"Failed to retrieve role: {ex.Message}", ApiStatusCode.ServerError);
        }
    }

    public async Task<ResponseViewModel<int>> SaveAsync(RoleSaveRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(request.RoleName))
            {
                return ResponseViewModel<int>.Fail("Role Name is required.", ApiStatusCode.BadRequest);
            }

            var id = await _roleRepository.SaveAsync(request, adminUserId, ct);
            if (id <= 0)
            {
                return ResponseViewModel<int>.Fail("Failed to save role.", ApiStatusCode.BadRequest);
            }

            return ResponseViewModel<int>.Success(id, "Role saved successfully.");
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
            var success = await _roleRepository.DeleteAsync(id, adminUserId, ct);
            return ResponseViewModel<bool>.Success(success, "Role deleted successfully.");
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
            var success = await _roleRepository.UpdateStatusAsync(request.Id, isActive, adminUserId, ct);
            return ResponseViewModel<bool>.Success(success, "Status updated successfully.");
        }
        catch (Exception ex)
        {
            return ResponseViewModel<bool>.Fail(ex.Message, ApiStatusCode.BadRequest);
        }
    }

    public async Task<ResponseViewModel<List<IdNamePair>>> GetLookupAsync(CancellationToken ct = default)
    {
        try
        {
            var list = await _roleRepository.GetLookupAsync(ct);
            return ResponseViewModel<List<IdNamePair>>.Success(list, "Role lookup retrieved successfully.");
        }
        catch (Exception ex)
        {
            return ResponseViewModel<List<IdNamePair>>.Fail(
                $"Failed to retrieve role lookup: {ex.Message}", ApiStatusCode.ServerError);
        }
    }
}
