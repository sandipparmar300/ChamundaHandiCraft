using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace ChamundaHandicraft.Admin.Services;

/// <summary>
/// Everything the Admin panel needs from the platform, in one seam — the mirror of
/// <c>ChamundaHandicraft.Customer/Services/IStorefrontClient.cs</c>.
///
/// Most of the 60 admin modules are the same four operations against a different type,
/// so those go through the generic methods below rather than 240 near-identical
/// interface members. The caller still names its type, so nothing is lost:
///
/// <code>
/// var rows = await _client.GetGridAsync&lt;CountryGridItem&gt;(ApiEndPoint.Location.CountryList, request);
/// </code>
///
/// Modules with real behaviour beyond CRUD — orders, dashboards, moderation, settings —
/// keep explicit methods, because their semantics are worth naming.
///
/// The pairing with the storefront is deliberate: <see cref="SaveAsync"/> against
/// <c>Product/Save</c> writes the record <c>IStorefrontClient.GetProductAsync</c> reads.
/// <c>docs/INTEGRATION-MAP.md</c> lists every pair.
/// </summary>
public interface IAdminClient
{
    #region Generic CRUD — used by the reference-data and simple modules

    /// <summary>A paged, searchable grid of <typeparamref name="T"/>.</summary>
    Task<ResponseViewModel<PagedResult<T>>> GetGridAsync<T>(
        string endpoint, DataTableRequest request, CancellationToken ct = default);

    /// <summary>One record for an edit form or a detail screen.</summary>
    Task<ResponseViewModel<T>> GetByIdAsync<T>(
        string endpoint, int id, CancellationToken ct = default);

    /// <summary>Insert or update. Returns the id of the saved record.</summary>
    Task<ResponseViewModel<int>> SaveAsync<TRequest>(
        string endpoint, TRequest payload, CancellationToken ct = default);

    /// <summary>Soft delete — the record stays available for reporting.</summary>
    Task<ResponseViewModel<bool>> DeleteAsync(
        string endpoint, int id, CancellationToken ct = default);

    /// <summary>Active/Inactive and Publish/Unpublish toggles.</summary>
    Task<ResponseViewModel<bool>> UpdateStatusAsync(
        string endpoint, UpdateStatusRequest request, CancellationToken ct = default);

    /// <summary>Dropdown options — categories, roles, warehouses, couriers.</summary>
    Task<ResponseViewModel<List<IdNamePair>>> GetLookupAsync(
        string endpoint, IDictionary<string, string?>? filter = null, CancellationToken ct = default);

    #endregion

    #region Dashboard

    Task<ResponseViewModel<AdminDashboardViewModel>> GetDashboardAsync(CancellationToken ct = default);

    #endregion

    #region Catalogue

    Task<ResponseViewModel<PagedResult<ProductGridItem>>> GetProductsAsync(
        DataTableRequest request, CancellationToken ct = default);

    Task<ResponseViewModel<ProductSaveRequest>> GetProductAsync(int id, CancellationToken ct = default);
    Task<ResponseViewModel<int>> SaveProductAsync(ProductSaveRequest request, CancellationToken ct = default);

    /// <summary>
    /// The publish gate. Moving a product to Published is what makes it appear on the
    /// storefront — nothing else does.
    /// </summary>
    Task<ResponseViewModel<bool>> UpdateProductStatusAsync(UpdateStatusRequest request, CancellationToken ct = default);

    Task<ResponseViewModel<List<CategoryViewModel>>> GetCategoryTreeAsync(CancellationToken ct = default);
    Task<ResponseViewModel<int>> SaveCategoryAsync(CategorySaveRequest request, CancellationToken ct = default);

    Task<ResponseViewModel<PagedResult<StockGridItem>>> GetStockAsync(
        DataTableRequest request, CancellationToken ct = default);

    #endregion

    #region Orders

    Task<ResponseViewModel<PagedResult<OrderGridItem>>> GetOrdersAsync(
        DataTableRequest request, CancellationToken ct = default);

    Task<ResponseViewModel<OrderDetailAdminViewModel>> GetOrderAsync(int id, CancellationToken ct = default);

    /// <summary>
    /// Writes the status the customer's tracking page renders as the next timeline
    /// step, and fires the matching notification.
    /// </summary>
    Task<ResponseViewModel<bool>> UpdateOrderStatusAsync(
        OrderStatusUpdateRequest request, CancellationToken ct = default);

    Task<ResponseViewModel<PagedResult<ReturnRequestViewModel>>> GetReturnsAsync(
        DataTableRequest request, CancellationToken ct = default);

    Task<ResponseViewModel<ReturnRequestViewModel>> GetReturnAsync(int id, CancellationToken ct = default);

    #endregion

    #region Promotions & content

    Task<ResponseViewModel<int>> SaveCouponAsync(CouponSaveRequest request, CancellationToken ct = default);
    Task<ResponseViewModel<int>> SaveBannerAsync(BannerSaveRequest request, CancellationToken ct = default);
    Task<ResponseViewModel<int>> SaveBlogPostAsync(BlogPostSaveRequest request, CancellationToken ct = default);

    #endregion

    #region Moderation

    Task<ResponseViewModel<PagedResult<ReviewModerationItem>>> GetReviewQueueAsync(
        DataTableRequest request, CancellationToken ct = default);

    Task<ResponseViewModel<ReviewModerationItem>> GetReviewAsync(int id, CancellationToken ct = default);

    /// <summary>Approving publishes the review to the PDP. Rejecting keeps it hidden.</summary>
    Task<ResponseViewModel<bool>> ModerateReviewAsync(
        int reviewId, bool approve, string? reason, CancellationToken ct = default);

    #endregion

    #region Settings & permissions

    Task<ResponseViewModel<Dictionary<string, string?>>> GetSettingsAsync(
        string section, CancellationToken ct = default);

    /// <summary>
    /// Writes the figures the storefront quotes — free-shipping threshold, COD fee,
    /// return window. Saving here changes what every shopper sees.
    /// </summary>
    Task<ResponseViewModel<bool>> SaveSettingsAsync(SettingsSectionRequest request, CancellationToken ct = default);

    Task<ResponseViewModel<List<SettingsHistoryItem>>> GetSettingsHistoryAsync(CancellationToken ct = default);

    Task<ResponseViewModel<List<PermissionMatrixItem>>> GetPermissionMatrixAsync(
        int? roleId, CancellationToken ct = default);

    Task<ResponseViewModel<AdminProfileViewModel>> GetProfileAsync(CancellationToken ct = default);

    /// <summary>
    /// The operator editing their own name, phone and timezone. Role and email are not
    /// part of this — changing either is an administrator's action, not a self-service one.
    /// </summary>
    Task<ResponseViewModel<bool>> SaveProfileAsync(AdminProfileViewModel request, CancellationToken ct = default);

    #endregion
}
