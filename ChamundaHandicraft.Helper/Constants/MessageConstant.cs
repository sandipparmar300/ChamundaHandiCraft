namespace ChamundaHandicraft.Helper.Constants;

/// <summary>
/// User-facing message text, shared so the Admin panel and the storefront say the
/// same thing about the same event.
///
/// Storefront copy follows the templates in
/// <c>docs/ui-ux-storefront/01-CX-Foundations.md §7.4</c>: an error names what went
/// wrong and exactly how to fix it. No message here blames the shopper.
/// </summary>
public static class MessageConstant
{
    #region Platform

    public const string ServiceUnavailable =
        "We couldn't reach our system just now. Nothing was changed — please try again in a moment.";

    public const string RequestTimedOut =
        "That took longer than expected. Nothing was changed — please try again.";

    public const string UnexpectedError =
        "Something went wrong at our end. This is our fault, not yours.";

    public const string SessionExpired = "Your session has expired. Sign in again to continue.";
    public const string NotAuthorised = "You don't have permission to do that.";
    public const string NotFound = "We couldn't find what you were looking for.";

    #endregion

    #region Auth

    public const string InvalidCredentials = "The email or password is incorrect.";
    public const string AccountLocked = "Too many attempts. Try again in 15 minutes, or reset your password.";
    public const string OtpIncorrect = "That code isn't right.";
    public const string OtpExpired = "This code has expired. Send a new one to continue.";
    public const string ResetLinkExpired = "This link has expired. Request a new one.";
    public const string EmailAlreadyRegistered = "This email is already registered. Sign in instead.";
    public const string MobileAlreadyRegistered = "This number is already registered. Sign in instead.";
    public const string MobileNotVerified = "Verify your mobile number to use cash on delivery.";

    #endregion

    #region Cart & checkout

    public const string AddedToCart = "Added to cart";
    public const string RemovedFromCart = "Removed from your cart";
    public const string CartEmpty = "Your cart is empty";
    public const string SavedToWishlist = "Saved to your wishlist";
    public const string RemovedFromWishlist = "Removed from your wishlist";

    public const string OutOfStock = "Out of stock";
    public const string QuantityUnavailable = "We don't have that many left.";
    public const string OptionRequired = "Choose an option before adding to cart.";

    public const string CouponApplied = "Coupon applied";
    public const string CouponInvalid = "Couldn't apply that coupon. Check the code and try again.";
    public const string CouponExpired = "Couldn't apply that coupon. It has expired.";
    public const string CouponNotEligible = "This coupon doesn't apply to what's in your cart yet.";

    public const string PincodeNotServiceable =
        "We don't deliver to that PIN code yet. We'll let you know when we do.";

    public const string PaymentFailed = "Payment didn't go through. Your cart is safe.";
    public const string OrderPlaced = "Order confirmed";

    #endregion

    #region Orders

    public const string OrderCancelled = "Order cancelled. Your refund is on its way.";
    public const string ReturnRequested = "Return requested. We'll collect it within 2–4 working days.";
    public const string OrderCannotBeCancelled = "This order has already shipped, so we can't stop it. Start a return instead.";
    public const string ReturnWindowClosed = "The 7-day return window has closed for this order.";

    #endregion

    #region Admin

    public const string SavedSuccessfully = "Saved successfully.";
    public const string DeletedSuccessfully = "Deleted successfully.";
    public const string StatusUpdated = "Status updated.";
    public const string PublishedSuccessfully = "Published. It is now live on the storefront.";
    public const string UnpublishedSuccessfully = "Unpublished. It is no longer visible to shoppers.";
    public const string ReviewApproved = "Review approved and published.";
    public const string ReviewRejected = "Review rejected. It stays hidden from the storefront.";
    public const string DuplicateSlug = "That URL slug is already in use. Choose another.";
    public const string CannotDeleteInUse = "This is used elsewhere and can't be deleted. Unpublish it instead.";

    #endregion
}
