using System.Data;
using Customers.Domain.Entities;
using Customers.Domain.IServices;
using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Customers.Infrastructure.Repositories;

public class CustomerProfileRepository : ICustomerProfileRepository
{
    private readonly string _connectionString;

    public CustomerProfileRepository(string connectionString)
    {
        _connectionString = connectionString ?? throw new ArgumentNullException(nameof(connectionString));
    }

    public CustomerProfileRepository(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("AppDbConnection")
            ?? configuration.GetConnectionString("DefaultConnection")
            ?? configuration["ConnectionStrings:AppDbConnection"]
            ?? configuration["ConnectionStrings:DefaultConnection"]
            ?? throw new InvalidOperationException("Connection string 'AppDbConnection' not found in configuration.");
    }

    private IDbConnection CreateConnection() => new SqlConnection(_connectionString);

    public async Task<Customer?> GetProfileAsync(int customerId)
    {
        using var connection = CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Customer>(
            "dbo.usp_Customer_GetProfile",
            new { CustomerId = customerId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<(bool Success, string? ErrorMessage)> UpdateProfileAsync(
        int customerId, string fullName, string? phone, string? gender, DateTime? dateOfBirth, string? gstin)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@CustomerId", customerId);
        parameters.Add("@FullName", fullName);
        parameters.Add("@Phone", phone);
        parameters.Add("@Gender", gender);
        parameters.Add("@DateOfBirth", dateOfBirth);
        parameters.Add("@Gstin", gstin);
        parameters.Add("@Success", dbType: DbType.Boolean, direction: ParameterDirection.Output);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 400, direction: ParameterDirection.Output);

        await connection.ExecuteAsync(
            "dbo.usp_Customer_UpdateProfile",
            parameters,
            commandType: CommandType.StoredProcedure);

        return (parameters.Get<bool>("@Success"), parameters.Get<string?>("@ErrorMessage"));
    }

    public async Task<(bool Success, string? ErrorMessage)> ChangePasswordAsync(
        int customerId, string newPasswordHash, bool signOutOthers)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@CustomerId", customerId);
        parameters.Add("@NewPasswordHash", newPasswordHash);
        parameters.Add("@SignOutOthers", signOutOthers);
        parameters.Add("@Success", dbType: DbType.Boolean, direction: ParameterDirection.Output);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 400, direction: ParameterDirection.Output);

        await connection.ExecuteAsync(
            "dbo.usp_Customer_ChangePassword",
            parameters,
            commandType: CommandType.StoredProcedure);

        return (parameters.Get<bool>("@Success"), parameters.Get<string?>("@ErrorMessage"));
    }
}
