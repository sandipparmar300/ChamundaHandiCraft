using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace Customers.Domain.IServices;

public interface ICustomerAddressService
{
    Task<ResponseViewModel<PagedResult<AddressViewModel>>> GetListAsync(CustomerAddressListRequest request);
    Task<ResponseViewModel<List<AddressViewModel>>> GetAllAsync(int customerId);
    Task<ResponseViewModel<AddressViewModel>> GetByIdAsync(int addressId, int customerId);
    Task<ResponseViewModel<int>> SaveAsync(CustomerAddressSaveRequest request);
    Task<ResponseViewModel<bool>> DeleteAsync(int addressId, int customerId);
    Task<ResponseViewModel<bool>> SetDefaultAsync(int addressId, int customerId);
}
