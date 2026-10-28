using System.Security.Claims;
using Cart.Application.Services;
using ChamundaHandicraft.API.Services.Email;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Customers.Domain.IServices;
using Microsoft.AspNetCore.Mvc;
using Orders.Application.Services;
using Settings.Domain.IServices;

namespace ChamundaHandicraft.API.Controllers.Customer;

[ApiController]
[Route("api/customer/checkout")]
public class CustomerCheckoutController : ControllerBase
{
    private readonly ICustomerCartService _cartService;
    private readonly ICustomerAddressService _addressService;
    private readonly ISettingsService _settingsService;
    private readonly IOrderService _orderService;
    private readonly IEmailService _emailService;
    private readonly ILogger<CustomerCheckoutController> _logger;

    public CustomerCheckoutController(
        ICustomerCartService cartService,
        ICustomerAddressService addressService,
        ISettingsService settingsService,
        IOrderService orderService,
        IEmailService emailService,
        ILogger<CustomerCheckoutController> logger)
    {
        _cartService = cartService;
        _addressService = addressService;
        _settingsService = settingsService;
        _orderService = orderService;
        _emailService = emailService;
        _logger = logger;
    }

    private (int? CustomerId, string? GuestToken) ResolveIdentity()
    {
        int? customerId = null;
        var claimId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                      ?? User.FindFirst("CustomerId")?.Value;

        if (int.TryParse(claimId, out var id))
        {
            customerId = id;
        }
        else if (Request.Headers.TryGetValue("X-Customer-Id", out var headerId)
                 && int.TryParse(headerId, out var parsedHeaderId))
        {
            customerId = parsedHeaderId;
        }

        string? guestToken = null;
        if (Request.Headers.TryGetValue(SessionKeys.GuestTokenHeader, out var guestHeader)
            && !string.IsNullOrWhiteSpace(guestHeader))
        {
            guestToken = guestHeader.ToString().Trim();
        }
        else if (Request.Query.TryGetValue("guestToken", out var queryToken)
                 && !string.IsNullOrWhiteSpace(queryToken))
        {
            guestToken = queryToken.ToString().Trim();
        }

        return (customerId, guestToken);
    }

    [HttpGet("init")]
    public async Task<ActionResult<ResponseViewModel<CheckoutViewModel>>> Init(CancellationToken ct = default)
    {
        var (customerId, guestToken) = ResolveIdentity();

        // 1. Get Storefront Config
        var configResp = await _settingsService.GetStorefrontConfigAsync(ct);
        var config = configResp.Data ?? new StorefrontConfigViewModel();

        // 2. Get Live Cart
        var cartResp = await _cartService.GetCartAsync(customerId, guestToken, config.FreeShippingThreshold, ct);
        var cart = cartResp.Data ?? new CartViewModel();

        var vm = new CheckoutViewModel
        {
            Lines = cart.Lines,
            Summary = cart.Summary,
            IsGuest = !customerId.HasValue
        };

        // 3. Saved Addresses for Authenticated Customer
        if (customerId.HasValue)
        {
            try
            {
                var addrResp = await _addressService.GetAllAsync(customerId.Value);
                if (addrResp?.Data != null)
                {
                    vm.Addresses = addrResp.Data;
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to load saved addresses for customer {CustomerId}", customerId.Value);
            }
        }

        // 4. Delivery Methods
        bool freeShipping = cart.Summary.QualifiesForFreeShipping;
        vm.DeliveryMethods = new List<DeliveryMethodViewModel>
        {
            new DeliveryMethodViewModel
            {
                Id = 1,
                Name = "Standard Delivery",
                Description = "3 to 5 business days, fully insured artisanal transit",
                Cost = freeShipping ? 0m : 99m,
                DeliverBy = DateTime.UtcNow.AddDays(4),
                IsSelected = true
            },
            new DeliveryMethodViewModel
            {
                Id = 2,
                Name = "Express Priority",
                Description = "1 to 2 business days expedited air dispatch",
                Cost = 199m,
                DeliverBy = DateTime.UtcNow.AddDays(2),
                IsSelected = false
            }
        };

        // 5. Payment Methods
        vm.PaymentMethods = new List<PaymentMethodViewModel>
        {
            new PaymentMethodViewModel
            {
                Method = PaymentMethod.Upi,
                Name = "UPI (Google Pay, PhonePe, Paytm, BHIM)",
                Description = "Instant, secure payment via any UPI app with zero surcharge.",
                ExtraFee = 0m,
                IsAvailable = true,
                IsRecommended = true
            },
            new PaymentMethodViewModel
            {
                Method = PaymentMethod.Card,
                Name = "Credit / Debit Cards",
                Description = "Visa, MasterCard, RuPay, Maestro. Secured via 256-bit SSL.",
                ExtraFee = 0m,
                IsAvailable = true
            },
            new PaymentMethodViewModel
            {
                Method = PaymentMethod.NetBanking,
                Name = "Net Banking",
                Description = "All major Indian banks supported (SBI, HDFC, ICICI, Axis, etc.).",
                ExtraFee = 0m,
                IsAvailable = true
            },
            new PaymentMethodViewModel
            {
                Method = PaymentMethod.CashOnDelivery,
                Name = "Cash on Delivery (COD)",
                Description = "Pay in cash or UPI to the courier upon delivery.",
                ExtraFee = 49m,
                IsAvailable = true
            }
        };

        return Ok(ResponseViewModel<CheckoutViewModel>.Success(vm));
    }

    [HttpPost("placeorder")]
    public async Task<ActionResult<ResponseViewModel<PlaceOrderResult>>> PlaceOrder(
        [FromBody] PlaceOrderRequest request,
        CancellationToken ct = default)
    {
        var (customerId, guestToken) = ResolveIdentity();

        if (customerId.HasValue && !request.CustomerId.HasValue)
            request.CustomerId = customerId;

        if (string.IsNullOrWhiteSpace(request.GuestToken))
            request.GuestToken = guestToken;

        request.IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString();

        var result = await _orderService.PlaceOrderAsync(request, ct);

        if (!result.Success)
        {
            return Ok(ResponseViewModel<PlaceOrderResult>.Fail(result.Message));
        }

        // Fire & Forget Order Confirmation Email
        _ = Task.Run(async () =>
        {
            try
            {
                var paymentMethodName = (PaymentMethod)request.PaymentMethod switch
                {
                    PaymentMethod.CashOnDelivery => "Cash on Delivery",
                    PaymentMethod.Upi => "Instant UPI",
                    PaymentMethod.Card => "Credit / Debit Card",
                    PaymentMethod.NetBanking => "Net Banking",
                    _ => "Online Payment"
                };
                var tokens = new Dictionary<string, string>
                {
                    ["CompanyName"] = "Chamunda Handicraft",
                    ["CustomerName"] = request.CustomerName,
                    ["OrderNumber"] = result.OrderNumber,
                    ["GrandTotal"] = $"₹{result.GrandTotal:N2}",
                    ["PaymentMethod"] = paymentMethodName,
                    ["ShippingCity"] = request.ShippingCity,
                    ["ShippingPincode"] = request.ShippingPincode,
                    ["TrackingUrl"] = $"/account/orders/{result.OrderNumber}",
                    ["SupportEmail"] = "support@chamundahandicraft.com",
                    ["SupportPhone"] = "+91 98765 43210"
                };

                await _emailService.SendEmailWithTemplateAsync(
                    request.CustomerEmail,
                    request.CustomerName,
                    "OrderConfirmation",
                    tokens);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to dispatch order confirmation email for order {OrderNumber}", result.OrderNumber);
            }
        });

        return Ok(ResponseViewModel<PlaceOrderResult>.Success(result, result.Message));
    }

    [HttpGet("order/{orderNumber}")]
    public async Task<ActionResult<ResponseViewModel<OrderDetailViewModel>>> GetOrderDetail(
        string orderNumber,
        CancellationToken ct = default)
    {
        var (customerId, _) = ResolveIdentity();
        var order = await _orderService.GetOrderDetailAsync(orderNumber, customerId, ct);

        if (order == null)
        {
            return Ok(ResponseViewModel<OrderDetailViewModel>.Fail("Order not found.", ApiStatusCode.NotFound));
        }

        return Ok(ResponseViewModel<OrderDetailViewModel>.Success(order));
    }
}
