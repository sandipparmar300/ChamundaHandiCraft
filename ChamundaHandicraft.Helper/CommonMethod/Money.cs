using System.Globalization;

namespace ChamundaHandicraft.Helper.CommonMethod;

/// <summary>
/// Currency, date and quantity formatting. Shared, because an amount must read
/// identically on an admin order grid, a customer invoice and a confirmation email.
///
/// Rules from <c>docs/ui-ux-storefront/01-CX-Foundations.md §7.5</c>.
/// </summary>
public static class Money
{
    private static readonly CultureInfo IndianCulture = new("en-IN");

    /// <summary>INR with Indian grouping (lakh/crore), no decimals when the amount is whole.</summary>
    public static string Inr(decimal amount)
    {
        var pattern = amount == decimal.Truncate(amount) ? "C0" : "C2";
        return amount.ToString(pattern, IndianCulture);
    }

    /// <summary>Bare number with Indian grouping — for a column that already has a ₹ header.</summary>
    public static string Number(decimal amount) => amount.ToString("N0", IndianCulture);

    /// <summary>
    /// The accessible name for a price. A11Y-17 requires the currency in words, so a
    /// screen reader does not announce "₹4,250" as "4250".
    /// </summary>
    public static string InrSpoken(decimal amount) =>
        $"{decimal.Truncate(amount).ToString("N0", IndianCulture)} rupees";

    /// <summary>
    /// "Get it by Wed, 12 Aug". Never a bare "3–5 business days" — a shopper cannot
    /// plan around a range with no anchor.
    /// </summary>
    public static string DeliveryDate(DateTime date) => date.ToString("ddd, d MMM", IndianCulture);

    public static string DeliveryRange(DateTime from, DateTime to) =>
        from.Date == to.Date ? DeliveryDate(from) : $"{DeliveryDate(from)} – {DeliveryDate(to)}";

    public static string LongDate(DateTime date) => date.ToString("dd MMM yyyy", IndianCulture);

    public static string DateAndTime(DateTime value) => value.ToString("dd MMM yyyy, h:mm tt", IndianCulture);

    /// <summary>Relative time per §7.5, falling back to an absolute date beyond a week.</summary>
    public static string Relative(DateTime when)
    {
        var span = DateTime.Now - when;

        if (span.TotalSeconds < 60) return "Just now";
        if (span.TotalMinutes < 60) return $"{(int)span.TotalMinutes} min ago";
        if (span.TotalHours < 24) return $"{(int)span.TotalHours} hour{((int)span.TotalHours == 1 ? "" : "s")} ago";
        if (span.TotalDays < 7) return $"{(int)span.TotalDays} day{((int)span.TotalDays == 1 ? "" : "s")} ago";

        return LongDate(when);
    }

    /// <summary>
    /// Discount from MRP, rounded the way the badge shows it. Computed in one place so
    /// the card, the PDP and the invoice can never disagree by a percentage point.
    /// </summary>
    public static int DiscountPercent(decimal price, decimal? mrp) =>
        mrp is > 0 && mrp > price ? (int)Math.Round((mrp.Value - price) / mrp.Value * 100) : 0;

    /// <summary>"You save ₹350 (22%)".</summary>
    public static string Savings(decimal price, decimal? mrp)
    {
        if (mrp is not > 0 || mrp <= price)
        {
            return string.Empty;
        }

        return $"You save {Inr(mrp.Value - price)} ({DiscountPercent(price, mrp)}%)";
    }

    /// <summary>Order numbers render in monospace and never truncate (§7.6).</summary>
    public static string OrderNumber(string number) => number.ToUpperInvariant();
}
