using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Customers.Domain.Entities;
using Customers.Domain.IServices;

namespace Customers.Application.Services;

public class CustomerAddressService : ICustomerAddressService
{
    private readonly ICustomerAddressRepository _repository;

    public CustomerAddressService(ICustomerAddressRepository repository)
    {
        _repository = repository;
    }

    public async Task<ResponseViewModel<PagedResult<AddressViewModel>>> GetListAsync(CustomerAddressListRequest request)
    {
        if (request.CustomerId <= 0)
        {
            return ResponseViewModel<PagedResult<AddressViewModel>>.Fail("Invalid customer identifier.", ApiStatusCode.BadRequest);
        }

        var (items, totalCount) = await _repository.GetListAsync(
            request.CustomerId,
            request.Search,
            request.SortBy,
            request.SortDescending,
            request.Page,
            request.PageSize);

        var viewModels = items.Select(MapToViewModel).ToList();

        var result = new PagedResult<AddressViewModel>
        {
            Items = viewModels,
            TotalCount = totalCount,
            Page = request.Page,
            PageSize = request.PageSize
        };

        return ResponseViewModel<PagedResult<AddressViewModel>>.Success(result);
    }

    public async Task<ResponseViewModel<List<AddressViewModel>>> GetAllAsync(int customerId)
    {
        if (customerId <= 0)
        {
            return ResponseViewModel<List<AddressViewModel>>.Fail("Invalid customer identifier.", ApiStatusCode.BadRequest);
        }

        var (items, _) = await _repository.GetListAsync(customerId, null, null, false, 1, 100);
        var viewModels = items.Select(MapToViewModel).ToList();
        return ResponseViewModel<List<AddressViewModel>>.Success(viewModels);
    }

    public async Task<ResponseViewModel<AddressViewModel>> GetByIdAsync(int addressId, int customerId)
    {
        if (addressId <= 0 || customerId <= 0)
        {
            return ResponseViewModel<AddressViewModel>.Fail("Invalid request parameters.", ApiStatusCode.BadRequest);
        }

        var address = await _repository.GetByIdAsync(addressId, customerId);
        if (address == null)
        {
            return ResponseViewModel<AddressViewModel>.Fail("Address not found.", ApiStatusCode.NotFound);
        }

        return ResponseViewModel<AddressViewModel>.Success(MapToViewModel(address));
    }

    public async Task<ResponseViewModel<int>> SaveAsync(CustomerAddressSaveRequest request)
    {
        if (request.CustomerId <= 0)
        {
            return ResponseViewModel<int>.Fail("Invalid customer identifier.", ApiStatusCode.BadRequest);
        }

        if (string.IsNullOrWhiteSpace(request.FullName) || string.IsNullOrWhiteSpace(request.Phone) ||
            string.IsNullOrWhiteSpace(request.Line1) || string.IsNullOrWhiteSpace(request.Pincode))
        {
            return ResponseViewModel<int>.Fail("Please fill all required address fields.", ApiStatusCode.ValidationFailed);
        }

        var entity = new CustomerAddress
        {
            Id = request.Id,
            CustomerId = request.CustomerId,
            LabelType = (byte)request.Label,
            FullName = request.FullName,
            Phone = request.Phone,
            AlternatePhone = request.AlternatePhone,
            Line1 = request.Line1,
            Line2 = request.Line2,
            Landmark = request.Landmark,
            CityName = request.City,
            StateName = request.State,
            CountryName = string.IsNullOrWhiteSpace(request.Country) ? "India" : request.Country,
            Pincode = request.Pincode,
            IsDefault = request.IsDefault
        };

        var (newId, error) = await _repository.SaveAsync(entity);
        if (!string.IsNullOrEmpty(error) || newId <= 0)
        {
            return ResponseViewModel<int>.Fail(error ?? "Failed to save address.", ApiStatusCode.BadRequest);
        }

        return ResponseViewModel<int>.Success(newId, "Address saved successfully.");
    }

    public async Task<ResponseViewModel<bool>> DeleteAsync(int addressId, int customerId)
    {
        if (addressId <= 0 || customerId <= 0)
        {
            return ResponseViewModel<bool>.Fail("Invalid request parameters.", ApiStatusCode.BadRequest);
        }

        var (success, error) = await _repository.DeleteAsync(addressId, customerId);
        if (!success)
        {
            return ResponseViewModel<bool>.Fail(error ?? "Failed to delete address.", ApiStatusCode.BadRequest);
        }

        return ResponseViewModel<bool>.Success(true, "Address deleted successfully.");
    }

    public async Task<ResponseViewModel<bool>> SetDefaultAsync(int addressId, int customerId)
    {
        if (addressId <= 0 || customerId <= 0)
        {
            return ResponseViewModel<bool>.Fail("Invalid request parameters.", ApiStatusCode.BadRequest);
        }

        var (success, error) = await _repository.SetDefaultAsync(addressId, customerId);
        if (!success)
        {
            return ResponseViewModel<bool>.Fail(error ?? "Failed to set default address.", ApiStatusCode.BadRequest);
        }

        return ResponseViewModel<bool>.Success(true, "Default delivery address updated.");
    }

    private static AddressViewModel MapToViewModel(CustomerAddress address)
    {
        return new AddressViewModel
        {
            Id = address.Id,
            Label = (AddressType)address.LabelType,
            FullName = address.FullName,
            Phone = address.Phone,
            Line1 = address.Line1,
            Line2 = address.Line2,
            Landmark = address.Landmark ?? string.Empty,
            City = address.CityName,
            State = address.StateName,
            Country = address.CountryName,
            Pincode = address.Pincode,
            IsDefault = address.IsDefault
        };
    }
}
