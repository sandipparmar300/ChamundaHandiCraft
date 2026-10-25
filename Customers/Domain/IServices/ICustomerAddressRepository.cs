using Customers.Domain.Entities;

namespace Customers.Domain.IServices;

public interface ICustomerAddressRepository
{
    Task<(List<CustomerAddress> Items, int TotalCount)> GetListAsync(int customerId, string? search, string? sortBy, bool sortDescending, int page, int pageSize);
    Task<CustomerAddress?> GetByIdAsync(int addressId, int customerId);
    Task<(int AddressId, string? ErrorMessage)> SaveAsync(CustomerAddress address);
    Task<(bool Success, string? ErrorMessage)> DeleteAsync(int addressId, int customerId);
    Task<(bool Success, string? ErrorMessage)> SetDefaultAsync(int addressId, int customerId);
}
