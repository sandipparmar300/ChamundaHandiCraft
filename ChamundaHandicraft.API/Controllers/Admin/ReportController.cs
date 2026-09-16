using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace ChamundaHandicraft.API.Controllers.Admin;

[ApiController]
[Route("api/admin/[controller]")]
public class ReportController : ControllerBase
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<ReportController> _logger;

    public ReportController(IConfiguration configuration, ILogger<ReportController> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    [HttpGet("Dashboard")]
    public async Task<ActionResult<ResponseViewModel<AdminDashboardViewModel>>> Dashboard(CancellationToken ct)
    {
        try
        {
            var connStr = _configuration.GetConnectionString("DefaultConnection");
            await using var conn = new SqlConnection(connStr);
            await conn.OpenAsync(ct);

            var model = new AdminDashboardViewModel();

            // 1. Order counts
            try
            {
                var orderStats = await conn.QueryFirstOrDefaultAsync<dynamic>(@"
                    SELECT 
                        COUNT(1) AS TotalOrders,
                        ISNULL(SUM(CASE WHEN CAST(CreatedAt AS DATE) = CAST(SYSUTCDATETIME() AS DATE) THEN 1 ELSE 0 END), 0) AS TodaysOrders,
                        ISNULL(SUM(CASE WHEN Status = 'Pending' OR Status = 'PaymentPending' THEN 1 ELSE 0 END), 0) AS PendingOrders,
                        ISNULL(SUM(CASE WHEN Status = 'Processing' THEN 1 ELSE 0 END), 0) AS ProcessingOrders,
                        ISNULL(SUM(CASE WHEN Status = 'Packed' THEN 1 ELSE 0 END), 0) AS PackedOrders,
                        ISNULL(SUM(CASE WHEN Status = 'Shipped' THEN 1 ELSE 0 END), 0) AS ShippedOrders,
                        ISNULL(SUM(CASE WHEN Status = 'Delivered' THEN 1 ELSE 0 END), 0) AS DeliveredOrders,
                        ISNULL(SUM(CASE WHEN Status = 'Cancelled' THEN 1 ELSE 0 END), 0) AS CancelledOrders,
                        ISNULL(SUM(CASE WHEN Status = 'Returned' THEN 1 ELSE 0 END), 0) AS ReturnedOrders,
                        ISNULL(SUM(CASE WHEN Status = 'RefundPending' THEN 1 ELSE 0 END), 0) AS RefundPending,
                        ISNULL(SUM(TotalAmount), 0) AS TotalSales,
                        ISNULL(AVG(TotalAmount), 0) AS AverageOrderValue
                    FROM dbo.Orders WITH (NOLOCK)
                    WHERE IsDeleted = 0");

                if (orderStats != null)
                {
                    model.TotalOrders = (int)(orderStats.TotalOrders ?? 0);
                    model.TodaysOrders = (int)(orderStats.TodaysOrders ?? 0);
                    model.PendingOrders = (int)(orderStats.PendingOrders ?? 0);
                    model.ProcessingOrders = (int)(orderStats.ProcessingOrders ?? 0);
                    model.PackedOrders = (int)(orderStats.PackedOrders ?? 0);
                    model.ShippedOrders = (int)(orderStats.ShippedOrders ?? 0);
                    model.DeliveredOrders = (int)(orderStats.DeliveredOrders ?? 0);
                    model.CancelledOrders = (int)(orderStats.CancelledOrders ?? 0);
                    model.ReturnedOrders = (int)(orderStats.ReturnedOrders ?? 0);
                    model.RefundPending = (int)(orderStats.RefundPending ?? 0);
                    model.TotalSales = (decimal)(orderStats.TotalSales ?? 0m);
                    model.AverageOrderValue = (decimal)(orderStats.AverageOrderValue ?? 0m);
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Could not query dbo.Orders for dashboard metrics");
            }

            // 2. Stock metrics
            try
            {
                var stockStats = await conn.QueryFirstOrDefaultAsync<dynamic>(@"
                    SELECT 
                        ISNULL(SUM(CASE WHEN QuantityOnHand > 0 AND QuantityOnHand <= 5 THEN 1 ELSE 0 END), 0) AS LowStockCount,
                        ISNULL(SUM(CASE WHEN QuantityOnHand <= 0 THEN 1 ELSE 0 END), 0) AS OutOfStockCount
                    FROM dbo.InventoryStocks WITH (NOLOCK)");

                if (stockStats != null)
                {
                    model.LowStockCount = (int)(stockStats.LowStockCount ?? 0);
                    model.OutOfStockCount = (int)(stockStats.OutOfStockCount ?? 0);
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Could not query dbo.InventoryStocks for dashboard metrics");
            }

            // 3. Pending reviews
            try
            {
                var reviewCount = await conn.ExecuteScalarAsync<int>(@"
                    SELECT COUNT(1) FROM dbo.Reviews WITH (NOLOCK) WHERE Status = 'Pending' AND IsDeleted = 0");
                model.PendingReviewCount = reviewCount;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Could not query dbo.Reviews for dashboard metrics");
            }

            // 4. Open tickets
            try
            {
                var ticketCount = await conn.ExecuteScalarAsync<int>(@"
                    SELECT COUNT(1) FROM dbo.SupportTickets WITH (NOLOCK) WHERE Status IN ('Open', 'InProgress') AND IsDeleted = 0");
                model.OpenTicketCount = ticketCount;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Could not query dbo.SupportTickets for dashboard metrics");
            }

            return Ok(ResponseViewModel<AdminDashboardViewModel>.Success(model));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating dashboard metrics");
            return Ok(ResponseViewModel<AdminDashboardViewModel>.Success(new AdminDashboardViewModel()));
        }
    }
}
