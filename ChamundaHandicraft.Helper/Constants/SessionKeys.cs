namespace ChamundaHandicraft.Helper.Constants;

/// <summary>
/// Session, cookie and header names shared by both web tiers. String literals for
/// these have a habit of drifting apart between projects; they live here instead.
/// </summary>
public static class SessionKeys
{
    // Admin
    public const string AdminToken = "Admin.Token";
    public const string AdminRefreshToken = "Admin.RefreshToken";
    public const string AdminUserId = "Admin.UserId";
    public const string AdminUserName = "Admin.UserName";
    public const string AdminRole = "Admin.Role";
    public const string AdminPermissions = "Admin.Permissions";

    // Customer
    public const string CustomerToken = "Customer.Token";
    public const string CustomerId = "Customer.Id";
    public const string CustomerFirstName = "Customer.FirstName";

    /// <summary>
    /// Identifies an anonymous shopper's cart and wishlist. Long-lived on purpose —
    /// losing it loses their work, which CX principle 11 forbids. Merged into the
    /// customer's own cart at sign-in via <c>Auth/MergeGuestCart</c>.
    /// </summary>
    public const string GuestTokenCookie = "ch_guest";

    public const string GuestTokenHeader = "X-Guest-Token";

    /// <summary>Remembered for 30 days and reused on PDP, cart, checkout and cards.</summary>
    public const string DeliveryPincodeCookie = "ch_pin";

    public const string ThemePreference = "chamunda-theme";
    public const string RecentlyViewedCookie = "ch_recent";
    public const string CompareCookie = "ch_compare";
}
