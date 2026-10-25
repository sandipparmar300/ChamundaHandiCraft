using System.Data;
using Customers.Domain.Entities;
using Customers.Domain.IServices;
using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Customers.Infrastructure.Repositories;

public class CustomerAuthRepository : ICustomerAuthRepository
{
    private readonly string _connectionString;

    public CustomerAuthRepository(string connectionString)
    {
        _connectionString = connectionString ?? throw new ArgumentNullException(nameof(connectionString));
    }

    public CustomerAuthRepository(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("AppDbConnection")
            ?? configuration.GetConnectionString("DefaultConnection")
            ?? configuration["ConnectionStrings:AppDbConnection"]
            ?? configuration["ConnectionStrings:DefaultConnection"]
            ?? throw new InvalidOperationException("Connection string 'AppDbConnection' not found in configuration.");
    }

    private IDbConnection CreateConnection() => new SqlConnection(_connectionString);

    public async Task<(int CustomerId, string? ErrorMessage)> RegisterAsync(
        string fullName, string email, string? phone, string passwordHash, string? guestToken)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@FullName", fullName);
        parameters.Add("@Email", email);
        parameters.Add("@Phone", phone);
        parameters.Add("@PasswordHash", passwordHash);
        parameters.Add("@GuestToken", guestToken);
        parameters.Add("@NewCustomerId", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 400, direction: ParameterDirection.Output);

        await connection.ExecuteAsync(
            "dbo.usp_Customer_Register",
            parameters,
            commandType: CommandType.StoredProcedure);

        int newId = parameters.Get<int>("@NewCustomerId");
        string? error = parameters.Get<string?>("@ErrorMessage");

        return (newId, error);
    }

    public async Task<Customer?> GetByIdentifierAsync(string identifier)
    {
        using var connection = CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Customer>(
            "dbo.usp_Customer_Authenticate",
            new { Identifier = identifier },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<Customer?> GetByIdAsync(int id)
    {
        using var connection = CreateConnection();
        const string sql = @"
            SELECT TOP 1
                Id, FullName, Email, Phone, PasswordHash, EmailVerified, MobileVerified,
                Gender, DateOfBirth, AvatarUrl, Gstin, Status, BlockedReason,
                OrderCount, LifetimeValue, LastOrderOn, RewardPointBalance, RewardTier,
                GuestToken, RegisteredOn, LastLoginOn, CreatedAt, CreatedBy, UpdatedAt,
                UpdatedBy, IsActive, IsDeleted
            FROM dbo.Customers
            WHERE Id = @Id AND IsDeleted = 0";

        return await connection.QueryFirstOrDefaultAsync<Customer>(sql, new { Id = id });
    }

    public async Task RecordLoginAsync(int customerId, string? ipAddress, string? userAgent)
    {
        using var connection = CreateConnection();
        await connection.ExecuteAsync(
            "dbo.usp_Customer_RecordLogin",
            new
            {
                CustomerId = customerId,
                IpAddress = ipAddress,
                UserAgent = userAgent
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<(bool Success, int CustomerId, string? FullName, string? Email, string? ErrorMessage)> SavePasswordResetTokenAsync(
        string destination, byte channel, string tokenHash, DateTime expiresAt)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Destination", destination);
        parameters.Add("@Channel", channel);
        parameters.Add("@TokenHash", tokenHash);
        parameters.Add("@ExpiresAt", expiresAt);
        parameters.Add("@CustomerId", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@FullName", dbType: DbType.String, size: 200, direction: ParameterDirection.Output);
        parameters.Add("@Email", dbType: DbType.String, size: 256, direction: ParameterDirection.Output);
        parameters.Add("@Success", dbType: DbType.Boolean, direction: ParameterDirection.Output);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 400, direction: ParameterDirection.Output);

        await connection.ExecuteAsync(
            "dbo.usp_Customer_SavePasswordResetToken",
            parameters,
            commandType: CommandType.StoredProcedure);

        bool success = parameters.Get<bool>("@Success");
        int customerId = parameters.Get<int>("@CustomerId");
        string? fullName = parameters.Get<string?>("@FullName");
        string? email = parameters.Get<string?>("@Email");
        string? error = parameters.Get<string?>("@ErrorMessage");

        return (success, customerId, fullName, email, error);
    }

    public async Task<(bool Success, string? ErrorMessage)> ValidateAndResetPasswordAsync(
        string tokenHash, string newPasswordHash, bool signOutOthers)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@TokenHash", tokenHash);
        parameters.Add("@NewPasswordHash", newPasswordHash);
        parameters.Add("@SignOutOthers", signOutOthers);
        parameters.Add("@Success", dbType: DbType.Boolean, direction: ParameterDirection.Output);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 400, direction: ParameterDirection.Output);

        await connection.ExecuteAsync(
            "dbo.usp_Customer_ValidateAndResetPassword",
            parameters,
            commandType: CommandType.StoredProcedure);

        bool success = parameters.Get<bool>("@Success");
        string? error = parameters.Get<string?>("@ErrorMessage");

        return (success, error);
    }

    public async Task SaveOtpAsync(string destination, byte channel, string purpose, string codeHash, DateTime expiresAt)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Destination", destination);
        parameters.Add("@Channel", channel);
        parameters.Add("@Purpose", purpose);
        parameters.Add("@CodeHash", codeHash);
        parameters.Add("@ExpiresAt", expiresAt);

        await connection.ExecuteAsync(
            "dbo.usp_Customer_SaveOtp",
            parameters,
            commandType: CommandType.StoredProcedure);
    }

    public async Task<(bool Success, string? ErrorMessage)> VerifyMobileOtpAsync(
        int customerId, string mobile, string codeHash, string? masterHash = null)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@CustomerId", customerId);
        parameters.Add("@Mobile", mobile);
        parameters.Add("@CodeHash", codeHash);
        parameters.Add("@MasterHash", masterHash);
        parameters.Add("@Success", dbType: DbType.Boolean, direction: ParameterDirection.Output);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 400, direction: ParameterDirection.Output);

        await connection.ExecuteAsync(
            "dbo.usp_Customer_VerifyMobileOtp",
            parameters,
            commandType: CommandType.StoredProcedure);

        bool success = parameters.Get<bool>("@Success");
        string? error = parameters.Get<string?>("@ErrorMessage");

        return (success, error);
    }
}
