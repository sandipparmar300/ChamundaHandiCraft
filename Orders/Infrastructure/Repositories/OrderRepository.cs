using System.Data;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Dapper;
using Microsoft.Data.SqlClient;
using Orders.Domain.IServices;

namespace Orders.Infrastructure.Repositories;

public class OrderRepository : IOrderRepository
{
    private readonly string _connectionString;

    public OrderRepository(string connectionString)
    {
        _connectionString = connectionString ?? throw new ArgumentNullException(nameof(connectionString));
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<PlaceOrderResult> CreateOrderFromCartAsync(PlaceOrderRequest request, CancellationToken ct = default)
    {
        using var conn = CreateConnection();
        await conn.OpenAsync(ct);

        var p = new DynamicParameters();
        p.Add("@CustomerId", request.CustomerId, DbType.Int32);
        p.Add("@GuestToken", request.GuestToken, DbType.AnsiString, size: 100);
        p.Add("@CustomerName", request.CustomerName, DbType.String, size: 200);
        p.Add("@CustomerEmail", request.CustomerEmail, DbType.String, size: 256);
        p.Add("@CustomerPhone", request.CustomerPhone, DbType.AnsiString, size: 24);
        p.Add("@PaymentMethod", (byte)request.PaymentMethod, DbType.Byte);
        p.Add("@DeliveryMethod", request.DeliveryMethod == 2 ? "Express" : "Standard", DbType.AnsiString, size: 50);
        p.Add("@PointsRedeemed", request.PointsToRedeem, DbType.Int32);
        p.Add("@CustomerNote", request.CustomerNote, DbType.String, size: 1000);

        p.Add("@ShippingAddressId", request.ShippingAddressId, DbType.Int32);
        p.Add("@ShippingFullName", request.ShippingFullName, DbType.String, size: 200);
        p.Add("@ShippingPhone", request.ShippingPhone, DbType.AnsiString, size: 24);
        p.Add("@ShippingLine1", request.ShippingLine1, DbType.String, size: 300);
        p.Add("@ShippingLine2", request.ShippingLine2, DbType.String, size: 300);
        p.Add("@ShippingLandmark", request.ShippingLandmark, DbType.String, size: 200);
        p.Add("@ShippingCity", request.ShippingCity, DbType.String, size: 150);
        p.Add("@ShippingState", request.ShippingState, DbType.String, size: 150);
        p.Add("@ShippingPincode", request.ShippingPincode, DbType.AnsiString, size: 12);

        p.Add("@BillingSameAsShipping", request.BillingSameAsShipping, DbType.Boolean);
        p.Add("@BillingFullName", request.BillingFullName, DbType.String, size: 200);
        p.Add("@BillingPhone", request.BillingPhone, DbType.AnsiString, size: 24);
        p.Add("@BillingLine1", request.BillingLine1, DbType.String, size: 300);
        p.Add("@BillingLine2", request.BillingLine2, DbType.String, size: 300);
        p.Add("@BillingCity", request.BillingCity, DbType.String, size: 150);
        p.Add("@BillingState", request.BillingState, DbType.String, size: 150);
        p.Add("@BillingPincode", request.BillingPincode, DbType.AnsiString, size: 12);
        p.Add("@SaveAddressForCustomer", request.SaveShippingAddress, DbType.Boolean);

        p.Add("@OrderId", dbType: DbType.Int32, direction: ParameterDirection.Output);
        p.Add("@OrderNumber", dbType: DbType.AnsiString, size: 32, direction: ParameterDirection.Output);
        p.Add("@TotalAmount", dbType: DbType.Decimal, precision: 18, scale: 2, direction: ParameterDirection.Output);
        p.Add("@ResultCode", dbType: DbType.Int32, direction: ParameterDirection.Output);
        p.Add("@Message", dbType: DbType.String, size: 300, direction: ParameterDirection.Output);

        await conn.ExecuteAsync(
            "dbo.usp_Order_CreateFromCart",
            p,
            commandType: CommandType.StoredProcedure);

        int resultCode = p.Get<int?>("@ResultCode") ?? 99;
        int orderId = p.Get<int?>("@OrderId") ?? 0;
        string orderNumber = p.Get<string>("@OrderNumber") ?? string.Empty;
        decimal grandTotal = p.Get<decimal?>("@TotalAmount") ?? 0m;
        string message = p.Get<string>("@Message") ?? (resultCode == 0 ? "Order placed successfully." : "Order placement failed.");

        return new PlaceOrderResult
        {
            Success = resultCode == 0,
            ResultCode = resultCode,
            OrderId = orderId,
            OrderNumber = orderNumber,
            GrandTotal = grandTotal,
            Message = message,
            RedirectUrl = resultCode == 0 ? $"/checkout/success/{orderNumber}" : null
        };
    }

    public async Task<OrderDetailViewModel?> GetOrderByIdOrNumberAsync(int? orderId, string? orderNumber, int? customerId, CancellationToken ct = default)
    {
        using var conn = CreateConnection();
        await conn.OpenAsync(ct);

        using var multi = await conn.QueryMultipleAsync(
            "dbo.usp_Order_GetById",
            new { OrderId = orderId, OrderNumber = orderNumber, CustomerId = customerId },
            commandType: CommandType.StoredProcedure);

        var headerRow = await multi.ReadFirstOrDefaultAsync<dynamic>();
        if (headerRow == null)
            return null;

        var detail = new OrderDetailViewModel();

        detail.Header = new OrderSummaryCardViewModel
        {
            Id = (int)headerRow.Id,
            OrderNumber = (string)headerRow.OrderNumber,
            PlacedOn = (DateTime)headerRow.PlacedOn,
            Status = (OrderStatus)(byte)headerRow.Status,
            PaymentStatus = (PaymentStatus)(byte)headerRow.PaymentStatus,
            Total = (decimal)headerRow.Total,
            ItemCount = (int)headerRow.ItemCount,
            DeliveryBy = (DateTime?)headerRow.DeliveryBy,
            DeliveredOn = (DateTime?)headerRow.DeliveredOn,
            Courier = (string?)headerRow.CourierName,
            TrackingNumber = (string?)headerRow.TrackingNumber
        };

        detail.Summary = new OrderSummaryViewModel
        {
            Subtotal = (decimal)headerRow.SubTotal,
            MrpTotal = (decimal)headerRow.MrpTotal,
            CouponCode = (string?)headerRow.CouponCode,
            CouponDiscount = (decimal)headerRow.CouponDiscount,
            PointsApplied = (decimal)headerRow.PointsDiscount,
            Shipping = (decimal)headerRow.ShippingCost,
            CodFee = (decimal)headerRow.CodFee,
            GiftWrap = (decimal)headerRow.GiftWrapCost,
            TaxTotal = (decimal)headerRow.TaxTotal,
            TaxInclusive = (bool)headerRow.IsTaxInclusive
        };

        detail.PaymentMethod = (PaymentMethod)(byte)headerRow.PaymentMethod;
        detail.InvoiceUrl = (string?)headerRow.InvoicePdfUrl;
        detail.PointsEarned = (int)headerRow.PointsEarned;

        // 2. Lines
        var lineRows = (await multi.ReadAsync<dynamic>()).ToList();
        foreach (var l in lineRows)
        {
            var line = new CartLineViewModel
            {
                Id = (int)(long)l.Id,
                ProductId = (int)l.ProductId,
                VariantId = (int?)l.VariantId,
                Name = (string)l.ProductName,
                Sku = (string)l.Sku,
                Slug = (string?)l.Slug ?? string.Empty,
                VariantSummary = (string?)l.VariantSummary ?? string.Empty,
                ImageUrl = (string?)l.ImageUrl ?? "/images/placeholder-product.svg",
                Quantity = (int)l.Quantity,
                Price = (decimal)l.UnitPrice,
                Mrp = (decimal?)l.UnitMrp
            };
            detail.Lines.Add(line);

            if (string.IsNullOrWhiteSpace(detail.Header.PrimaryItemName))
                detail.Header.PrimaryItemName = line.Name;

            if (!string.IsNullOrWhiteSpace(line.ImageUrl))
                detail.Header.Thumbnails.Add(line.ImageUrl);
        }

        // 3. Addresses
        var addressRows = (await multi.ReadAsync<dynamic>()).ToList();
        foreach (var a in addressRows)
        {
            string kind = (string)a.AddressKind;
            var addr = new AddressViewModel
            {
                Id = (int)(long)a.Id,
                FullName = (string)a.FullName,
                Phone = (string)a.Phone,
                Line1 = (string)a.Line1,
                Line2 = (string?)a.Line2,
                Landmark = (string?)a.Landmark ?? string.Empty,
                City = (string)a.CityName,
                State = (string)a.StateName,
                Country = (string)a.CountryName,
                Pincode = (string)a.Pincode,
                Label = a.LabelType != null ? (AddressType)(byte)a.LabelType : AddressType.Home
            };

            if (string.Equals(kind, "Shipping", StringComparison.OrdinalIgnoreCase))
            {
                detail.ShippingAddress = addr;
            }
            else if (string.Equals(kind, "Billing", StringComparison.OrdinalIgnoreCase))
            {
                detail.BillingAddress = addr;
            }
        }

        if (detail.BillingAddress == null)
            detail.BillingAddress = detail.ShippingAddress;

        // 4. Timeline
        if (!multi.IsConsumed)
        {
            var timelineRows = (await multi.ReadAsync<dynamic>()).ToList();
            foreach (var t in timelineRows)
            {
                var toStatus = (OrderStatus)(byte)t.ToStatus;
                detail.Timeline.Add(new OrderTimelineStep
                {
                    Title = toStatus.ToString(),
                    Meta = (string?)t.Note,
                    Location = (string?)t.Location,
                    At = (DateTime?)t.ChangedAt,
                    State = "done"
                });
            }
        }

        return detail;
    }
}
