using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace Customers.Domain.IServices;

public interface ICustomerProfileService
{
    Task<ResponseViewModel<CustomerProfileViewModel>> GetProfileAsync(int customerId);
    Task<ResponseViewModel<bool>> UpdateProfileAsync(int customerId, CustomerProfileUpdateRequest request);
    Task<ResponseViewModel<bool>> ChangePasswordAsync(int customerId, CustomerChangePasswordRequest request);
    Task<ResponseViewModel<CustomerDashboardViewModel>> GetDashboardAsync(int customerId);
}
