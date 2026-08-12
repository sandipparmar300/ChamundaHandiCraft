using ChamundaHandicraft.Helper.Enums;

namespace ChamundaHandicraft.Helper.ViewModel.Common;

/// <summary>
/// The envelope every API endpoint returns. The Admin panel and the Customer site
/// both unwrap this shape, so error handling is written once rather than per screen.
/// </summary>
public class ResponseViewModel<T>
{
    public bool IsSuccess { get; set; }
    public ApiStatusCode StatusCode { get; set; } = ApiStatusCode.Success;

    /// <summary>Shown to the user as-is. Must already be plain language (CX principle 12).</summary>
    public string Message { get; set; } = string.Empty;

    public T? Data { get; set; }

    /// <summary>Field-level errors keyed by the form field name, for inline display.</summary>
    public Dictionary<string, string[]>? Errors { get; set; }

    /// <summary>Correlation id from the API log — quoted to support when something breaks.</summary>
    public string? TraceId { get; set; }

    public static ResponseViewModel<T> Success(T data, string message = "") => new()
    {
        IsSuccess = true,
        StatusCode = ApiStatusCode.Success,
        Message = message,
        Data = data
    };

    public static ResponseViewModel<T> Fail(
        string message,
        ApiStatusCode code = ApiStatusCode.BadRequest,
        Dictionary<string, string[]>? errors = null) => new()
    {
        IsSuccess = false,
        StatusCode = code,
        Message = message,
        Errors = errors
    };
}

/// <summary>Non-generic form for endpoints that return nothing but success or failure.</summary>
public class ResponseViewModel : ResponseViewModel<object>
{
}

/// <summary>
/// Paging contract shared by every list endpoint. The Admin grids drive it from
/// DataTables; the storefront drives it from Load More and the numbered pager.
/// </summary>
public class PagedRequest
{
    private int _pageSize = 24;

    public int Page { get; set; } = 1;

    /// <summary>Capped so a crafted query cannot ask for the whole catalogue.</summary>
    public int PageSize
    {
        get => _pageSize;
        set => _pageSize = value is < 1 or > 100 ? 24 : value;
    }

    public string? Search { get; set; }
    public string? SortBy { get; set; }
    public bool SortDescending { get; set; }

    public int Skip => (Page < 1 ? 0 : Page - 1) * PageSize;
}

/// <summary>The list half of every response: the rows plus what the pager needs.</summary>
public class PagedResult<T>
{
    public List<T> Items { get; set; } = new();
    public int TotalCount { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 24;

    public int TotalPages => PageSize <= 0 ? 0 : (int)Math.Ceiling(TotalCount / (double)PageSize);
    public bool HasPrevious => Page > 1;
    public bool HasNext => Page < TotalPages;

    /// <summary>Drives "Load More (24 of 482)" and the progress line beneath it.</summary>
    public int LoadedCount => Math.Min(Page * PageSize, TotalCount);

    public static PagedResult<T> Empty(int pageSize = 24) => new() { PageSize = pageSize };
}

/// <summary>DataTables server-side contract used by the Admin grids.</summary>
public class DataTableRequest : PagedRequest
{
    public int Draw { get; set; }
    public int Start { get; set; }
    public int Length { get; set; } = 25;

    /// <summary>Column key → selected value, from the grid's filter row.</summary>
    public Dictionary<string, string?> Filters { get; set; } = new();
}

public class DataTableResponse<T>
{
    public int Draw { get; set; }
    public int RecordsTotal { get; set; }
    public int RecordsFiltered { get; set; }
    public List<T> Data { get; set; } = new();
}

/// <summary>Dropdown option. Used everywhere a select is populated from the API.</summary>
public class IdNamePair
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Slug { get; set; }
    public bool IsActive { get; set; } = true;
    public int? ParentId { get; set; }
    public int Count { get; set; }
}

/// <summary>Toggle payload shared by every Active/Inactive and Publish/Unpublish switch.</summary>
public class UpdateStatusRequest
{
    public int Id { get; set; }
    public int Status { get; set; }
    public string? Reason { get; set; }
}

/// <summary>Common audit columns every admin grid displays.</summary>
public class AuditableViewModel
{
    public DateTime CreatedOn { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime? ModifiedOn { get; set; }
    public string? ModifiedBy { get; set; }
}

/// <summary>
/// One image on any entity. The Admin Media module writes these; every storefront
/// surface reads them, which is why alt text is not optional here.
/// </summary>
public class MediaViewModel
{
    public int Id { get; set; }
    public string Url { get; set; } = string.Empty;
    public string? ThumbnailUrl { get; set; }

    /// <summary>Descriptive and product-specific. Never "product image" (§10.3).</summary>
    public string AltText { get; set; } = string.Empty;

    public ProductMediaType MediaType { get; set; } = ProductMediaType.Image;
    public int SortOrder { get; set; }
    public bool IsPrimary { get; set; }
    public int? Width { get; set; }
    public int? Height { get; set; }
}

/// <summary>
/// SEO block written by the Admin SEO module and rendered into the page head by the
/// storefront. Every indexable customer route carries one.
/// </summary>
public class SeoViewModel
{
    public string? MetaTitle { get; set; }
    public string? MetaDescription { get; set; }
    public string? CanonicalUrl { get; set; }
    public string? OgTitle { get; set; }
    public string? OgDescription { get; set; }
    public string? OgImageUrl { get; set; }
    public bool NoIndex { get; set; }
    public bool NoFollow { get; set; }

    /// <summary>Serialised JSON-LD the view writes verbatim into a script tag.</summary>
    public string? StructuredData { get; set; }
}

/// <summary>Breadcrumb trail. Emitted visually and as BreadcrumbList structured data.</summary>
public class BreadcrumbItem
{
    public string Label { get; set; } = string.Empty;
    public string? Url { get; set; }
}
