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

    public Task<ResponseViewModel<List<CategoryViewModel>>> GetCategoryTreeAsync(CancellationToken ct = default) =>
        _api.GetAsync<List<CategoryViewModel>>(ApiEndPoint.Category.Tree, null, ct);

    public Task<ResponseViewModel<int>> SaveCategoryAsync(CategorySaveRequest request, CancellationToken ct = default) =>
        _api.PostAsync<int>(ApiEndPoint.Category.Save, request, ct);

    public Task<ResponseViewModel<PagedResult<StockGridItem>>> GetStockAsync(
        DataTableRequest request, CancellationToken ct = default) =>
        _api.PostAsync<PagedResult<StockGridItem>>(ApiEndPoint.Inventory.StockGridList, request, ct);

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
        _api.GetAsync<List<PermissionMatrixItem>>(ApiEndPoint.Auth.AdminPermissionKeys,
            new Dictionary<string, string?> { ["roleId"] = roleId?.ToString() }, ct);

    public Task<ResponseViewModel<AdminProfileViewModel>> GetProfileAsync(CancellationToken ct = default) =>
        _api.GetAsync<AdminProfileViewModel>(ApiEndPoint.Auth.AdminProfileGet, null, ct);

    public Task<ResponseViewModel<bool>> SaveProfileAsync(
        AdminProfileViewModel request, CancellationToken ct = default) =>
        _api.PostAsync<bool>(ApiEndPoint.Auth.AdminProfileSave, request, ct);

    #endregion
}
