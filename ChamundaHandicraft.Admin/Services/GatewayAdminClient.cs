using ChamundaHandicraft.Helper.ApiService;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace ChamundaHandicraft.Admin.Services;

/// <summary>
/// The production implementation. Every method is one call to a constant from
/// <see cref="ApiEndPoint"/> through the gateway, with the admin's JWT attached by
/// <see cref="ApiService"/> from session.
///
/// Complete against the contract; it starts returning data when the matching
/// <c>/api/admin/*</c> controllers exist on ChamundaHandicraft.API.
/// </summary>
public class GatewayAdminClient : IAdminClient
{
    private readonly IApiService _api;

    public GatewayAdminClient(IApiService api) => _api = api;

    #region Generic CRUD

    public Task<ResponseViewModel<PagedResult<T>>> GetGridAsync<T>(
        string endpoint, DataTableRequest request, CancellationToken ct = default) =>
        _api.PostAsync<PagedResult<T>>(endpoint, request, ct);

    public Task<ResponseViewModel<T>> GetByIdAsync<T>(
        string endpoint, int id, CancellationToken ct = default) =>
        _api.GetAsync<T>(endpoint, new Dictionary<string, string?> { ["id"] = id.ToString() }, ct);

    public Task<ResponseViewModel<int>> SaveAsync<TRequest>(
        string endpoint, TRequest payload, CancellationToken ct = default) =>
        _api.PostAsync<int>(endpoint, payload, ct);

    public Task<ResponseViewModel<bool>> DeleteAsync(
        string endpoint, int id, CancellationToken ct = default) =>
        _api.DeleteAsync<bool>(endpoint, new Dictionary<string, string?> { ["id"] = id.ToString() }, ct);

    public Task<ResponseViewModel<bool>> UpdateStatusAsync(
        string endpoint, UpdateStatusRequest request, CancellationToken ct = default) =>
        _api.PostAsync<bool>(endpoint, request, ct);

    public Task<ResponseViewModel<List<IdNamePair>>> GetLookupAsync(
        string endpoint, IDictionary<string, string?>? filter = null, CancellationToken ct = default) =>
        _api.GetAsync<List<IdNamePair>>(endpoint, filter, ct);

    #endregion

    public Task<ResponseViewModel<AdminDashboardViewModel>> GetDashboardAsync(CancellationToken ct = default) =>
        _api.GetAsync<AdminDashboardViewModel>(ApiEndPoint.Report.Dashboard, null, ct);

    #region Catalogue

    public Task<ResponseViewModel<PagedResult<ProductGridItem>>> GetProductsAsync(
        DataTableRequest request, CancellationToken ct = default) =>
        _api.PostAsync<PagedResult<ProductGridItem>>(ApiEndPoint.Product.GridList, request, ct);

    public Task<ResponseViewModel<ProductSaveRequest>> GetProductAsync(int id, CancellationToken ct = default) =>
        _api.GetAsync<ProductSaveRequest>(ApiEndPoint.Product.GetById,
            new Dictionary<string, string?> { ["id"] = id.ToString() }, ct);

    public Task<ResponseViewModel<int>> SaveProductAsync(ProductSaveRequest request, CancellationToken ct = default) =>
        _api.PostAsync<int>(ApiEndPoint.Product.Save, request, ct);

    public Task<ResponseViewModel<bool>> UpdateProductStatusAsync(
        UpdateStatusRequest request, CancellationToken ct = default) =>
        _api.PostAsync<bool>(ApiEndPoint.Product.UpdateStatus, request, ct);

    public Task<ResponseViewModel<bool>> DeleteProductAsync(int id, CancellationToken ct = default) =>
        _api.DeleteAsync<bool>(ApiEndPoint.Product.Delete, new Dictionary<string, string?> { ["id"] = id.ToString() }, ct);

    public Task<ResponseViewModel<ProductLookupsViewModel>> GetProductLookupsAsync(CancellationToken ct = default) =>
        _api.GetAsync<ProductLookupsViewModel>("Admin/Product/Lookups", null, ct);

    public Task<ResponseViewModel<List<CategoryViewModel>>> GetCategoryTreeAsync(CancellationToken ct = default) =>
        _api.GetAsync<List<CategoryViewModel>>(ApiEndPoint.Category.Tree, null, ct);

    public Task<ResponseViewModel<CategorySaveRequest>> GetCategoryAsync(int id, CancellationToken ct = default) =>
        _api.GetAsync<CategorySaveRequest>(ApiEndPoint.Category.GetById, new Dictionary<string, string?> { ["id"] = id.ToString() }, ct);

    public Task<ResponseViewModel<int>> SaveCategoryAsync(CategorySaveRequest request, CancellationToken ct = default) =>
        _api.PostAsync<int>(ApiEndPoint.Category.Save, request, ct);

    public Task<ResponseViewModel<bool>> DeleteCategoryAsync(int id, CancellationToken ct = default) =>
        _api.DeleteAsync<bool>(ApiEndPoint.Category.Delete, new Dictionary<string, string?> { ["id"] = id.ToString() }, ct);

    public Task<ResponseViewModel<bool>> UpdateCategoryStatusAsync(UpdateStatusRequest request, CancellationToken ct = default) =>
        _api.PostAsync<bool>(ApiEndPoint.Category.UpdateStatus, request, ct);

    public Task<ResponseViewModel<List<IdNamePair>>> GetCategoryLookupAsync(CancellationToken ct = default) =>
        _api.GetAsync<List<IdNamePair>>(ApiEndPoint.Category.Lookup, null, ct);

    public Task<ResponseViewModel<PagedResult<StockGridItem>>> GetStockAsync(
        DataTableRequest request, CancellationToken ct = default) =>
        _api.PostAsync<PagedResult<StockGridItem>>(ApiEndPoint.Inventory.StockGridList, request, ct);

    #endregion

    #region Inventory Management

    public Task<ResponseViewModel<InventoryKpiSummaryViewModel>> GetInventoryKpisAsync(CancellationToken ct = default) =>
        _api.GetAsync<InventoryKpiSummaryViewModel>(ApiEndPoint.Inventory.Kpis, null, ct);

    public Task<ResponseViewModel<List<InventoryTransactionViewModel>>> GetInventoryLedgerAsync(int? productId = null, int? warehouseId = null, int maxRows = 100, CancellationToken ct = default)
    {
        var query = new Dictionary<string, string?>
        {
            ["maxRows"] = maxRows.ToString()
        };
        if (productId.HasValue) query["productId"] = productId.Value.ToString();
        if (warehouseId.HasValue) query["warehouseId"] = warehouseId.Value.ToString();

        return _api.GetAsync<List<InventoryTransactionViewModel>>(ApiEndPoint.Inventory.Ledger, query, ct);
    }

    public Task<ResponseViewModel<InventoryDetailViewModel>> GetInventoryDetailAsync(long id, CancellationToken ct = default) =>
        _api.GetAsync<InventoryDetailViewModel>(ApiEndPoint.Inventory.Details, new Dictionary<string, string?> { ["id"] = id.ToString() }, ct);

    public Task<ResponseViewModel<long>> SaveStockAsync(StockSaveRequest request, CancellationToken ct = default) =>
        _api.PostAsync<long>(ApiEndPoint.Inventory.Save, request, ct);

    public Task<ResponseViewModel<bool>> DeleteStockAsync(long id, CancellationToken ct = default) =>
        _api.DeleteAsync<bool>(ApiEndPoint.Inventory.Delete, new Dictionary<string, string?> { ["id"] = id.ToString() }, ct);

    public Task<ResponseViewModel<WarehouseDetailViewModel>> GetWarehouseDetailAsync(int id, CancellationToken ct = default) =>
        _api.GetAsync<WarehouseDetailViewModel>(ApiEndPoint.Warehouse.GridList.Replace("GridList", "Details"), new Dictionary<string, string?> { ["id"] = id.ToString() }, ct);

    public Task<ResponseViewModel<SupplierDetailViewModel>> GetSupplierDetailAsync(int id, CancellationToken ct = default) =>
        _api.GetAsync<SupplierDetailViewModel>(ApiEndPoint.Supplier.GridList.Replace("GridList", "Details"), new Dictionary<string, string?> { ["id"] = id.ToString() }, ct);

    public Task<ResponseViewModel<PurchaseOrderDetailViewModel>> GetPurchaseDetailAsync(int id, CancellationToken ct = default) =>
        _api.GetAsync<PurchaseOrderDetailViewModel>(ApiEndPoint.Purchase.GetById, new Dictionary<string, string?> { ["id"] = id.ToString() }, ct);

    public Task<ResponseViewModel<bool>> ReceivePurchaseOrderAsync(int id, CancellationToken ct = default) =>
        _api.PostAsync<bool>($"{ApiEndPoint.Purchase.ReceiveStock}?id={id}", null, ct);

    public Task<ResponseViewModel<StockAdjustmentDetailViewModel>> GetStockAdjustmentDetailAsync(int id, CancellationToken ct = default) =>
        _api.GetAsync<StockAdjustmentDetailViewModel>(ApiEndPoint.StockAdjustment.GetById, new Dictionary<string, string?> { ["id"] = id.ToString() }, ct);

    public Task<ResponseViewModel<StockTransferDetailViewModel>> GetStockTransferDetailAsync(int id, CancellationToken ct = default) =>
        _api.GetAsync<StockTransferDetailViewModel>(ApiEndPoint.StockTransfer.GetById, new Dictionary<string, string?> { ["id"] = id.ToString() }, ct);

    public Task<ResponseViewModel<StockRateDetailViewModel>> GetStockRateDetailAsync(int productId, int? variantId = null, CancellationToken ct = default)
    {
        var query = new Dictionary<string, string?> { ["productId"] = productId.ToString() };
        if (variantId.HasValue) query["variantId"] = variantId.Value.ToString();
        return _api.GetAsync<StockRateDetailViewModel>(ApiEndPoint.StockRate.GetById, query, ct);
    }

    public Task<ResponseViewModel<bool>> SaveStockRateAsync(StockRateSaveRequest request, CancellationToken ct = default) =>
        _api.PostAsync<bool>(ApiEndPoint.StockRate.Save, request, ct);

    #endregion

    #region Orders

    public Task<ResponseViewModel<PagedResult<OrderGridItem>>> GetOrdersAsync(
        DataTableRequest request, CancellationToken ct = default) =>
        _api.PostAsync<PagedResult<OrderGridItem>>(ApiEndPoint.Order.GridList, request, ct);

    public Task<ResponseViewModel<OrderDetailAdminViewModel>> GetOrderAsync(int id, CancellationToken ct = default) =>
        _api.GetAsync<OrderDetailAdminViewModel>(ApiEndPoint.Order.GetById,
            new Dictionary<string, string?> { ["id"] = id.ToString() }, ct);

    public Task<ResponseViewModel<bool>> UpdateOrderStatusAsync(
        OrderStatusUpdateRequest request, CancellationToken ct = default) =>
        _api.PostAsync<bool>(ApiEndPoint.Order.UpdateStatus, request, ct);

    public Task<ResponseViewModel<PagedResult<ReturnRequestViewModel>>> GetReturnsAsync(
        DataTableRequest request, CancellationToken ct = default) =>
        _api.PostAsync<PagedResult<ReturnRequestViewModel>>(ApiEndPoint.Order.ReturnGridList, request, ct);

    public Task<ResponseViewModel<ReturnRequestViewModel>> GetReturnAsync(int id, CancellationToken ct = default) =>
        _api.GetAsync<ReturnRequestViewModel>(ApiEndPoint.Order.ReturnGridList,
            new Dictionary<string, string?> { ["id"] = id.ToString() }, ct);

    #endregion

    #region Promotions & content

    public Task<ResponseViewModel<int>> SaveCouponAsync(CouponSaveRequest request, CancellationToken ct = default) =>
        _api.PostAsync<int>(ApiEndPoint.Promotion.CouponSave, request, ct);

    public Task<ResponseViewModel<int>> SaveBannerAsync(BannerSaveRequest request, CancellationToken ct = default) =>
        _api.PostAsync<int>(ApiEndPoint.Banner.Save, request, ct);

    public Task<ResponseViewModel<int>> SaveBlogPostAsync(BlogPostSaveRequest request, CancellationToken ct = default) =>
        _api.PostAsync<int>(ApiEndPoint.Content.BlogSave, request, ct);

    #endregion

    #region Moderation

    public Task<ResponseViewModel<PagedResult<ReviewModerationItem>>> GetReviewQueueAsync(
        DataTableRequest request, CancellationToken ct = default) =>
        _api.PostAsync<PagedResult<ReviewModerationItem>>(ApiEndPoint.Review.Queue, request, ct);

    public Task<ResponseViewModel<ReviewModerationItem>> GetReviewAsync(int id, CancellationToken ct = default) =>
        _api.GetAsync<ReviewModerationItem>(ApiEndPoint.Review.GetById,
            new Dictionary<string, string?> { ["id"] = id.ToString() }, ct);

    public Task<ResponseViewModel<bool>> ModerateReviewAsync(
        int reviewId, bool approve, string? reason, CancellationToken ct = default) =>
        _api.PostAsync<bool>(
            approve ? ApiEndPoint.Review.Approve : ApiEndPoint.Review.Reject,
            new { reviewId, reason },
            ct);

    #endregion

    #region Settings & permissions

    public Task<ResponseViewModel<Dictionary<string, string?>>> GetSettingsAsync(
        string section, CancellationToken ct = default) =>
        _api.GetAsync<Dictionary<string, string?>>(ApiEndPoint.Settings.GetSection,
            new Dictionary<string, string?> { ["section"] = section }, ct);

    public Task<ResponseViewModel<bool>> SaveSettingsAsync(
        SettingsSectionRequest request, CancellationToken ct = default) =>
        _api.PostAsync<bool>(ApiEndPoint.Settings.SaveSection, request, ct);

    public Task<ResponseViewModel<List<SettingsHistoryItem>>> GetSettingsHistoryAsync(CancellationToken ct = default) =>
        _api.GetAsync<List<SettingsHistoryItem>>(ApiEndPoint.Settings.History, null, ct);

    public Task<ResponseViewModel<List<PermissionMatrixItem>>> GetPermissionMatrixAsync(
        int? roleId, CancellationToken ct = default) =>
        _api.GetAsync<List<PermissionMatrixItem>>(ApiEndPoint.Permission.Matrix,
            new Dictionary<string, string?> { ["roleId"] = roleId?.ToString() }, ct);

    public Task<ResponseViewModel<bool>> SaveRolePermissionsAsync(
        int roleId, List<int> permissionIds, CancellationToken ct = default) =>
        _api.PostAsync<bool>(ApiEndPoint.Permission.SaveRolePermissions,
            new { RoleId = roleId, PermissionIds = permissionIds }, ct);

    public Task<ResponseViewModel<bool>> ChangeAdminUserPasswordAsync(
        AdminUserChangePasswordRequest request, CancellationToken ct = default) =>
        _api.PostAsync<bool>($"{ApiEndPoint.AdminPrefix}AdminUser/ChangePassword", request, ct);

    public Task<ResponseViewModel<AdminProfileViewModel>> GetProfileAsync(CancellationToken ct = default) =>
        _api.GetAsync<AdminProfileViewModel>(ApiEndPoint.Auth.AdminProfileGet, null, ct);

    public Task<ResponseViewModel<bool>> SaveProfileAsync(
        AdminProfileViewModel request, CancellationToken ct = default) =>
        _api.PostAsync<bool>(ApiEndPoint.Auth.AdminProfileSave, request, ct);

    #endregion
}
