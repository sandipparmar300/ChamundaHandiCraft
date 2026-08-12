using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace ChamundaHandicraft.Helper.ViewModel.Admin;

#region Marketing

public class CouponGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public DiscountType DiscountType { get; set; }
    public decimal DiscountValue { get; set; }
    public decimal? MinimumOrderValue { get; set; }
    public DateTime StartsOn { get; set; }
    public DateTime? ExpiresOn { get; set; }
    public int UsageCount { get; set; }
    public int? TotalUsageLimit { get; set; }
    public decimal TotalDiscountGiven { get; set; }
    public CouponStatus Status { get; set; }
    public bool IsPublic { get; set; } = true;

    public bool IsExhausted => TotalUsageLimit is not null && UsageCount >= TotalUsageLimit;
    public bool IsActive => Status == CouponStatus.Active;
    public string DisplayName => Code;
}

public class OfferGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string OfferType { get; set; } = "Flash Sale";
    public int DiscountPercent { get; set; }
    public DateTime StartsOn { get; set; }
    public DateTime EndsOn { get; set; }
    public int ProductCount { get; set; }
    public int OrdersInfluenced { get; set; }
    public decimal RevenueInfluenced { get; set; }
    public bool IsActive { get; set; }

    /// <summary>
    /// Live right now by the clock, not by a flag someone forgot to turn off. The
    /// storefront countdown renders from <see cref="EndsOn"/> and disappears at zero.
    /// </summary>
    public bool IsLiveNow => IsActive && StartsOn <= DateTime.Now && EndsOn > DateTime.Now;

    public string DisplayName => Name;
}

public class CampaignGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Subject { get; set; } = string.Empty;
    public string Channel { get; set; } = "Email";
    public string? SegmentName { get; set; }
    public DateTime? ScheduledOn { get; set; }
    public DateTime? SentOn { get; set; }
    public int Recipients { get; set; }
    public int Delivered { get; set; }
    public int Opened { get; set; }
    public int Clicked { get; set; }
    public int Unsubscribed { get; set; }
    public string Status { get; set; } = "Draft";

    public decimal OpenRate => Delivered == 0 ? 0 : Math.Round(Opened * 100m / Delivered, 1);
    public decimal ClickRate => Delivered == 0 ? 0 : Math.Round(Clicked * 100m / Delivered, 1);

    public bool IsActive => Status != "Cancelled";
    public string DisplayName => Name;
}

/// <summary>An automated sequence — welcome, abandoned cart, post-delivery review.</summary>
public class FlowGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string TriggerEvent { get; set; } = string.Empty;
    public int StepCount { get; set; }
    public int EnrolledCount { get; set; }
    public int CompletedCount { get; set; }
    public decimal RevenueAttributed { get; set; }
    public bool IsActive { get; set; }

    public string DisplayName => Name;
}

public class SubscriberGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string? Name { get; set; }
    public string Source { get; set; } = "Footer";
    public DateTime SubscribedOn { get; set; }
    public DateTime? UnsubscribedOn { get; set; }

    /// <summary>Explicit consent, captured unticked. Never assumed.</summary>
    public bool HasMarketingConsent { get; set; }

    public bool IsSuppressed { get; set; }
    public string? SuppressionReason { get; set; }
    public bool IsActive => UnsubscribedOn is null && !IsSuppressed;

    public string DisplayName => Email;
}

public class SegmentGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string RuleSummary { get; set; } = string.Empty;
    public int CustomerCount { get; set; }
    public DateTime? LastEvaluatedOn { get; set; }
    public bool IsActive { get; set; } = true;

    public string DisplayName => Name;
}

public class NotificationTemplateGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string TemplateKey { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public NotificationChannel Channel { get; set; }
    public string? Subject { get; set; }

    /// <summary>The order event that fires it — this is the Admin↔Customer link.</summary>
    public string? TriggerEvent { get; set; }

    public int SentLast30Days { get; set; }
    public bool IsSystem { get; set; }
    public bool IsActive { get; set; } = true;

    public string DisplayName => Name;
}

public class NotificationLogGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Body { get; set; }
    public NotificationChannel Channel { get; set; }
    public string Recipient { get; set; } = string.Empty;
    public string Status { get; set; } = "Sent";
    public DateTime SentOn { get; set; }
    public DateTime? ReadOn { get; set; }
    public string? FailureReason { get; set; }

    public bool IsActive => Status == "Sent";
    public string DisplayName => Title;
}

#endregion

#region Content

public class BlogGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string? CoverUrl { get; set; }
    public string CategoryName { get; set; } = string.Empty;
    public string AuthorName { get; set; } = string.Empty;
    public DateTime? PublishedOn { get; set; }
    public int ReadMinutes { get; set; }
    public int ViewCount { get; set; }
    public int CommentCount { get; set; }
    public int FeaturedProductCount { get; set; }
    public ContentStatus Status { get; set; }

    public bool IsLiveOnStorefront => Status == ContentStatus.Published
                                      && (PublishedOn is null || PublishedOn <= DateTime.Now);

    public string StorefrontUrl => $"/blog/{Slug}";
    public bool IsActive => Status == ContentStatus.Published;
    public string DisplayName => Title;
}

public class BlogCommentGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string PostTitle { get; set; } = string.Empty;
    public string AuthorName { get; set; } = string.Empty;
    public string? AuthorEmail { get; set; }
    public string Body { get; set; } = string.Empty;
    public DateTime SubmittedOn { get; set; }
    public ModerationStatus Status { get; set; }

    public bool IsActive => Status == ModerationStatus.Approved;
    public string DisplayName => AuthorName;
}

public class CmsPageGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string Template { get; set; } = "Policy";
    public DateTime? PublishedOn { get; set; }
    public ContentStatus Status { get; set; }

    /// <summary>Policy pages are linked from the footer and cannot be deleted.</summary>
    public bool IsSystemPage { get; set; }

    public string StorefrontUrl => $"/pages/{Slug}";
    public bool IsActive => Status == ContentStatus.Published;
    public string DisplayName => Title;
}

public class TestimonialGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public string? Location { get; set; }
    public string Quote { get; set; } = string.Empty;
    public int Rating { get; set; }
    public string? PhotoUrl { get; set; }
    public bool ShowOnHome { get; set; }
    public int SortOrder { get; set; }
    public ContentStatus Status { get; set; }

    public bool IsActive => Status == ContentStatus.Published;
    public string DisplayName => CustomerName;
}

public class ArtisanGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string Craft { get; set; } = string.Empty;
    public string Cluster { get; set; } = string.Empty;
    public string? PhotoUrl { get; set; }
    public int ProductCount { get; set; }
    public decimal AverageRating { get; set; }
    public int? WorkingSinceYear { get; set; }
    public bool IsGiTagged { get; set; }
    public bool IsActive { get; set; } = true;

    public string StorefrontUrl => $"/artisans/{Slug}";
    public string DisplayName => Name;
}

public class MediaGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string FileName { get; set; } = string.Empty;
    public string Url { get; set; } = string.Empty;
    public string? ThumbnailUrl { get; set; }
    public ProductMediaType MediaType { get; set; }
    public string AltText { get; set; } = string.Empty;
    public long SizeBytes { get; set; }
    public int? Width { get; set; }
    public int? Height { get; set; }
    public string? Folder { get; set; }
    public int UsedInCount { get; set; }
    public bool IsActive { get; set; } = true;

    public string SizeDisplay => SizeBytes < 1024 * 1024
        ? $"{SizeBytes / 1024} KB"
        : $"{SizeBytes / 1024d / 1024d:0.0} MB";

    /// <summary>An image with no alt text cannot be attached to a published product.</summary>
    public bool IsMissingAltText => string.IsNullOrWhiteSpace(AltText);

    public string DisplayName => FileName;
}

public class SeoMetaGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string RoutePath { get; set; } = string.Empty;
    public string EntityType { get; set; } = string.Empty;
    public string? MetaTitle { get; set; }
    public string? MetaDescription { get; set; }
    public bool NoIndex { get; set; }

    /// <summary>Titles beyond ~60 characters get truncated in search results.</summary>
    public bool HasIssue => string.IsNullOrWhiteSpace(MetaTitle)
                            || string.IsNullOrWhiteSpace(MetaDescription)
                            || MetaTitle.Length > 60;

    public bool IsActive => !NoIndex;
    public string DisplayName => RoutePath;
}

public class RedirectGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string FromPath { get; set; } = string.Empty;
    public string ToPath { get; set; } = string.Empty;
    public int StatusCode { get; set; } = 301;
    public int HitCount { get; set; }
    public DateTime? LastHitOn { get; set; }
    public bool IsActive { get; set; } = true;

    public string DisplayName => FromPath;
}

#endregion

#region People & system

public class AdminUserGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string RoleName { get; set; } = string.Empty;
    public string? PhotoUrl { get; set; }
    public DateTime? LastLoginOn { get; set; }
    public bool TwoFactorEnabled { get; set; }
    public bool IsLocked { get; set; }
    public bool IsActive { get; set; } = true;

    public string DisplayName => FullName;
}

public class RoleGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string RoleName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int PermissionCount { get; set; }
    public int UserCount { get; set; }

    /// <summary>System roles cannot be deleted or have their key permissions removed.</summary>
    public bool IsSystem { get; set; }

    public bool IsActive { get; set; } = true;
    public string DisplayName => RoleName;
}

public class CustomerGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public bool EmailVerified { get; set; }
    public bool MobileVerified { get; set; }
    public int OrderCount { get; set; }
    public decimal LifetimeValue { get; set; }
    public decimal AverageOrderValue { get; set; }
    public DateTime? LastOrderOn { get; set; }
    public int RewardPoints { get; set; }
    public string? SegmentName { get; set; }
    public CustomerStatus Status { get; set; }

    public bool IsActive => Status == CustomerStatus.Active;
    public string DisplayName => FullName;
}

public class SupportTicketGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string TicketNumber { get; set; } = string.Empty;
    public string Subject { get; set; } = string.Empty;
    public string Topic { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string? OrderNumber { get; set; }
    public TicketStatus Status { get; set; }
    public string Priority { get; set; } = "Normal";
    public string? AssignedTo { get; set; }
    public DateTime OpenedOn { get; set; }
    public DateTime? LastReplyOn { get; set; }
    public int MessageCount { get; set; }

    /// <summary>One working day is the promise made on the help centre.</summary>
    public bool IsBreachingSla =>
        Status is TicketStatus.Open or TicketStatus.AwaitingAgent
        && (LastReplyOn ?? OpenedOn) < DateTime.Now.AddDays(-1);

    public bool IsActive => Status != TicketStatus.Closed;
    public string DisplayName => TicketNumber;
}

public class ContactSubmissionGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string Subject { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string? OrderNumber { get; set; }
    public DateTime SubmittedOn { get; set; }
    public bool IsHandled { get; set; }
    public string? HandledBy { get; set; }

    public bool IsActive => !IsHandled;
    public string DisplayName => Subject;
}

public class ApprovalGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string EntityType { get; set; } = string.Empty;
    public string EntityName { get; set; } = string.Empty;
    public string RequestedAction { get; set; } = string.Empty;
    public string RequestedBy { get; set; } = string.Empty;
    public DateTime RequestedOn { get; set; }
    public string Status { get; set; } = "Pending";
    public string? Reason { get; set; }
    public string? DecidedBy { get; set; }
    public DateTime? DecidedOn { get; set; }

    public bool IsActive => Status == "Pending";
    public string DisplayName => $"{EntityType}: {EntityName}";
}

public class AuditLogGridItem : IAdminGridRow
{
    public int Id { get; set; }
    public string Action { get; set; } = string.Empty;
    public string EntityType { get; set; } = string.Empty;
    public string? EntityName { get; set; }
    public int? EntityId { get; set; }
    public string PerformedBy { get; set; } = string.Empty;
    public string? IpAddress { get; set; }
    public DateTime PerformedOn { get; set; }

    /// <summary>Serialised before/after, rendered as a diff on the detail screen.</summary>
    public string? ChangeSummary { get; set; }

    public bool IsActive => true;
    public DateTime CreatedOn => PerformedOn;
    public string DisplayName => $"{Action} {EntityType}";
}

public class IntegrationGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string? Provider { get; set; }
    public bool IsConnected { get; set; }
    public DateTime? LastSyncOn { get; set; }
    public string? LastSyncStatus { get; set; }
    public string? ErrorMessage { get; set; }
    public bool IsActive { get; set; } = true;

    public string DisplayName => Name;
}

public class SavedReportGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string ReportType { get; set; } = string.Empty;
    public string? DateRange { get; set; }
    public string? Schedule { get; set; }
    public DateTime? LastRunOn { get; set; }
    public string? Recipients { get; set; }
    public bool IsActive { get; set; } = true;

    public string DisplayName => Name;
}

public class SettingsHistoryItem
{
    public int Id { get; set; }
    public string Section { get; set; } = string.Empty;
    public string SettingKey { get; set; } = string.Empty;
    public string? OldValue { get; set; }
    public string? NewValue { get; set; }
    public string ChangedBy { get; set; } = string.Empty;
    public DateTime ChangedOn { get; set; }
    public string? ChangeNote { get; set; }
}

/// <summary>One permission key and whether the role being edited holds it.</summary>
public class PermissionMatrixItem
{
    public string Module { get; set; } = string.Empty;
    public string Entity { get; set; } = string.Empty;
    public string Action { get; set; } = string.Empty;

    /// <summary>Format is <c>module.entity.action</c>, e.g. <c>catalog.product.create</c>.</summary>
    public string Key => $"{Module}.{Entity}.{Action}".ToLowerInvariant();

    public string Description { get; set; } = string.Empty;
    public bool IsGranted { get; set; }
}

public class AdminProfileViewModel
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string RoleName { get; set; } = string.Empty;
    public string? PhotoUrl { get; set; }
    public DateTime? LastLoginOn { get; set; }
    public bool TwoFactorEnabled { get; set; }
    public string? Timezone { get; set; } = "Asia/Kolkata";
}

#endregion
