using System.Data;
using Cart.Domain.IServices;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Dapper;
using Microsoft.Data.SqlClient;

namespace Cart.Infrastructure.Repositories;

public class CustomerCartRepository : ICustomerCartRepository
{
    private readonly string _connectionString;

    public CustomerCartRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<CartViewModel> GetCartAsync(
        int? customerId,
        string? guestToken,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@CustomerId", customerId);
        parameters.Add("@GuestToken", string.IsNullOrWhiteSpace(guestToken) ? null : guestToken);
        parameters.Add("@FreeShippingThreshold", freeShippingThreshold);

        using var multi = await connection.QueryMultipleAsync(
            "dbo.usp_Cart_Get",
            parameters,
            commandType: CommandType.StoredProcedure);

        return await MapCartAsync(multi);
    }

    public async Task<CartViewModel> AddItemAsync(
        int? customerId,
        string? guestToken,
        int productId,
        int? variantId,
        int quantity,
        string? note = null,
        string? slug = null,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default)
    {
        using var connection = CreateConnection();

        if (productId <= 0 && !string.IsNullOrWhiteSpace(slug))
        {
            var pid = await connection.QueryFirstOrDefaultAsync<int?>(
                "SELECT Id FROM dbo.Products WHERE Slug = @Slug AND IsDeleted = 0",
                new { Slug = slug });
            if (pid.HasValue && pid.Value > 0)
            {
                productId = pid.Value;
            }
        }

        var parameters = new DynamicParameters();
        parameters.Add("@CustomerId", customerId);
        parameters.Add("@GuestToken", string.IsNullOrWhiteSpace(guestToken) ? null : guestToken);
        parameters.Add("@ProductId", productId);
        parameters.Add("@VariantId", variantId);
        parameters.Add("@Quantity", quantity);
        parameters.Add("@Note", note);
        parameters.Add("@FreeShippingThreshold", freeShippingThreshold);

        using var multi = await connection.QueryMultipleAsync(
            "dbo.usp_Cart_AddItem",
            parameters,
            commandType: CommandType.StoredProcedure);

        return await MapCartAsync(multi);
    }

    public async Task<CartViewModel> UpdateQuantityAsync(
        int? customerId,
        string? guestToken,
        long cartItemId,
        int quantity,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@CartItemId", cartItemId);
        parameters.Add("@Quantity", quantity);
        parameters.Add("@CustomerId", customerId);
        parameters.Add("@GuestToken", string.IsNullOrWhiteSpace(guestToken) ? null : guestToken);
        parameters.Add("@FreeShippingThreshold", freeShippingThreshold);

        using var multi = await connection.QueryMultipleAsync(
            "dbo.usp_Cart_UpdateQuantity",
            parameters,
            commandType: CommandType.StoredProcedure);

        return await MapCartAsync(multi);
    }

    public async Task<CartViewModel> RemoveItemAsync(
        int? customerId,
        string? guestToken,
        long cartItemId,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@CartItemId", cartItemId);
        parameters.Add("@CustomerId", customerId);
        parameters.Add("@GuestToken", string.IsNullOrWhiteSpace(guestToken) ? null : guestToken);
        parameters.Add("@FreeShippingThreshold", freeShippingThreshold);

        using var multi = await connection.QueryMultipleAsync(
            "dbo.usp_Cart_RemoveItem",
            parameters,
            commandType: CommandType.StoredProcedure);

        return await MapCartAsync(multi);
    }

    public async Task<CartViewModel> ApplyCouponAsync(
        int? customerId,
        string? guestToken,
        string couponCode,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@CouponCode", couponCode);
        parameters.Add("@CustomerId", customerId);
        parameters.Add("@GuestToken", string.IsNullOrWhiteSpace(guestToken) ? null : guestToken);
        parameters.Add("@FreeShippingThreshold", freeShippingThreshold);

        using var multi = await connection.QueryMultipleAsync(
            "dbo.usp_Cart_ApplyCoupon",
            parameters,
            commandType: CommandType.StoredProcedure);

        return await MapCartAsync(multi);
    }

    public async Task<CartViewModel> RemoveCouponAsync(
        int? customerId,
        string? guestToken,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@CustomerId", customerId);
        parameters.Add("@GuestToken", string.IsNullOrWhiteSpace(guestToken) ? null : guestToken);
        parameters.Add("@FreeShippingThreshold", freeShippingThreshold);

        using var multi = await connection.QueryMultipleAsync(
            "dbo.usp_Cart_RemoveCoupon",
            parameters,
            commandType: CommandType.StoredProcedure);

        return await MapCartAsync(multi);
    }

    public async Task<CartViewModel> MergeGuestCartAsync(
        int customerId,
        string guestToken,
        decimal freeShippingThreshold = 999.00m,
        CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@CustomerId", customerId);
        parameters.Add("@GuestToken", guestToken);
        parameters.Add("@FreeShippingThreshold", freeShippingThreshold);

        using var multi = await connection.QueryMultipleAsync(
            "dbo.usp_Cart_MergeGuestCart",
            parameters,
            commandType: CommandType.StoredProcedure);

        return await MapCartAsync(multi);
    }

    private static async Task<CartViewModel> MapCartAsync(SqlMapper.GridReader multi)
    {
        var summaryRow = await multi.ReadFirstOrDefaultAsync<CartSummaryRow>();
        var activeLines = (await multi.ReadAsync<CartLineRow>()).AsList();
        var savedLines = (await multi.ReadAsync<CartLineRow>()).AsList();

        var cart = new CartViewModel
        {
            GiftWrapSelected = summaryRow?.GiftWrapSelected ?? false,
            GiftMessage = summaryRow?.GiftMessage,
            Lines = activeLines.Select(MapLine).ToList(),
            SavedForLater = savedLines.Select(MapLine).ToList()
        };

        if (summaryRow != null)
        {
            cart.Summary = new OrderSummaryViewModel
            {
                Subtotal = summaryRow.Subtotal,
                MrpTotal = summaryRow.MrpTotal,
                CouponCode = summaryRow.CouponCode,
                CouponDiscount = summaryRow.CouponDiscount,
                Shipping = summaryRow.Shipping,
                CodFee = summaryRow.CodFee,
                GiftWrap = summaryRow.GiftWrap,
                PointsApplied = summaryRow.PointsApplied,
                TaxTotal = summaryRow.TaxTotal,
                TaxInclusive = summaryRow.TaxInclusive,
                ItemCount = summaryRow.ItemCount,
                FreeShippingThreshold = summaryRow.FreeShippingThreshold
            };
        }

        return cart;
    }

    private static CartLineViewModel MapLine(CartLineRow row) => new()
    {
        Id = (int)row.Id,
        ProductId = row.ProductId,
        VariantId = row.VariantId,
        Slug = row.Slug,
        Name = row.Name,
        ImageUrl = row.ImageUrl,
        ImageAlt = row.ImageAlt,
        VariantSummary = row.VariantSummary,
        Sku = row.Sku,
        Price = row.Price,
        Mrp = row.Mrp,
        Quantity = row.Quantity,
        MaxQuantity = row.MaxQuantity,
        Stock = (StockState)row.Stock,
        StockCount = row.StockCount,
        IsHandmade = row.IsHandmade
    };

    #region Internal DTOs

    private class CartSummaryRow
    {
        public int CartId { get; set; }
        public int? CustomerId { get; set; }
        public string? GuestToken { get; set; }
        public decimal Subtotal { get; set; }
        public decimal MrpTotal { get; set; }
        public string? CouponCode { get; set; }
        public decimal CouponDiscount { get; set; }
        public decimal Shipping { get; set; }
        public decimal CodFee { get; set; }
        public decimal GiftWrap { get; set; }
        public decimal PointsApplied { get; set; }
        public decimal TaxTotal { get; set; }
        public bool TaxInclusive { get; set; }
        public int ItemCount { get; set; }
        public decimal FreeShippingThreshold { get; set; }
        public bool GiftWrapSelected { get; set; }
        public string? GiftMessage { get; set; }
    }

    private class CartLineRow
    {
        public long Id { get; set; }
        public int ProductId { get; set; }
        public int? VariantId { get; set; }
        public string Slug { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string ImageUrl { get; set; } = string.Empty;
        public string ImageAlt { get; set; } = string.Empty;
        public string VariantSummary { get; set; } = string.Empty;
        public string Sku { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public decimal? Mrp { get; set; }
        public int Quantity { get; set; }
        public int MaxQuantity { get; set; }
        public int Stock { get; set; }
        public int? StockCount { get; set; }
        public bool IsHandmade { get; set; }
        public decimal LineTotal { get; set; }
    }

    #endregion
}
