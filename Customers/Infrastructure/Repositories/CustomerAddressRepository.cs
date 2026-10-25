using System.Data;
using Customers.Domain.Entities;
using Customers.Domain.IServices;
using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Customers.Infrastructure.Repositories;

public class CustomerAddressRepository : ICustomerAddressRepository
{
    private readonly string _connectionString;

    public CustomerAddressRepository(string connectionString)
    {
        _connectionString = connectionString ?? throw new ArgumentNullException(nameof(connectionString));
    }

    public CustomerAddressRepository(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("AppDbConnection")
            ?? configuration.GetConnectionString("DefaultConnection")
            ?? configuration["ConnectionStrings:AppDbConnection"]
            ?? configuration["ConnectionStrings:DefaultConnection"]
            ?? throw new InvalidOperationException("Connection string 'AppDbConnection' not found in configuration.");
    }

    private IDbConnection CreateConnection() => new SqlConnection(_connectionString);

    public async Task<(List<CustomerAddress> Items, int TotalCount)> GetListAsync(
        int customerId, string? search, string? sortBy, bool sortDescending, int page, int pageSize)
    {
        using var connection = CreateConnection();
        var items = (await connection.QueryAsync<CustomerAddress>(
            "dbo.usp_CustomerAddress_GetList",
            new
            {
                CustomerId = customerId,
                Search = search,
                SortBy = sortBy,
                SortDescending = sortDescending,
                Page = page,
                PageSize = pageSize
            },
            commandType: CommandType.StoredProcedure)).ToList();

        int totalCount = items.FirstOrDefault()?.TotalCount ?? 0;
        return (items, totalCount);
    }

    public async Task<CustomerAddress?> GetByIdAsync(int addressId, int customerId)
    {
        using var connection = CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<CustomerAddress>(
            "dbo.usp_CustomerAddress_GetById",
            new
            {
                AddressId = addressId,
                CustomerId = customerId
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<(int AddressId, string? ErrorMessage)> SaveAsync(CustomerAddress address)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Id", address.Id);
        parameters.Add("@CustomerId", address.CustomerId);
        parameters.Add("@LabelType", address.LabelType);
        parameters.Add("@FullName", address.FullName);
        parameters.Add("@Phone", address.Phone);
        parameters.Add("@AlternatePhone", address.AlternatePhone);
        parameters.Add("@Line1", address.Line1);
        parameters.Add("@Line2", address.Line2);
        parameters.Add("@Landmark", address.Landmark);
        parameters.Add("@CityName", address.CityName);
        parameters.Add("@StateName", address.StateName);
        parameters.Add("@CountryName", address.CountryName);
        parameters.Add("@Pincode", address.Pincode);
        parameters.Add("@IsDefault", address.IsDefault);
        parameters.Add("@NewAddressId", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 400, direction: ParameterDirection.Output);

        await connection.ExecuteAsync(
            "dbo.usp_CustomerAddress_Save",
            parameters,
            commandType: CommandType.StoredProcedure);

        int newId = parameters.Get<int>("@NewAddressId");
        string? error = parameters.Get<string?>("@ErrorMessage");

        return (newId, error);
    }

    public async Task<(bool Success, string? ErrorMessage)> DeleteAsync(int addressId, int customerId)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@AddressId", addressId);
        parameters.Add("@CustomerId", customerId);
        parameters.Add("@Success", dbType: DbType.Boolean, direction: ParameterDirection.Output);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 400, direction: ParameterDirection.Output);

        await connection.ExecuteAsync(
            "dbo.usp_CustomerAddress_Delete",
            parameters,
            commandType: CommandType.StoredProcedure);

        return (parameters.Get<bool>("@Success"), parameters.Get<string?>("@ErrorMessage"));
    }

    public async Task<(bool Success, string? ErrorMessage)> SetDefaultAsync(int addressId, int customerId)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@AddressId", addressId);
        parameters.Add("@CustomerId", customerId);
        parameters.Add("@Success", dbType: DbType.Boolean, direction: ParameterDirection.Output);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 400, direction: ParameterDirection.Output);

        await connection.ExecuteAsync(
            "dbo.usp_CustomerAddress_SetDefault",
            parameters,
            commandType: CommandType.StoredProcedure);

        return (parameters.Get<bool>("@Success"), parameters.Get<string?>("@ErrorMessage"));
    }
}
