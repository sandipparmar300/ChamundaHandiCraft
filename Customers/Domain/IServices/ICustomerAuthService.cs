using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace Customers.Domain.IServices;

public interface ICustomerAuthService
{
    Task<ResponseViewModel<CustomerAuthResponse>> RegisterAsync(CustomerRegisterRequest request);
    Task<ResponseViewModel<CustomerAuthResponse>> LoginAsync(CustomerLoginRequest request, string? ipAddress = null, string? userAgent = null);
    Task<ResponseViewModel<CustomerForgotPasswordResponse>> ForgotPasswordAsync(CustomerForgotPasswordRequest request);
    Task<ResponseViewModel<bool>> ResetPasswordAsync(CustomerResetPasswordRequest request);
    Task<ResponseViewModel<bool>> SendOtpAsync(CustomerOtpSendRequest request);
    Task<ResponseViewModel<bool>> VerifyMobileAsync(int customerId, CustomerVerifyMobileRequest request);
}
