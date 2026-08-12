using ChamundaHandicraft.Helper.ViewModel.Common;

namespace ChamundaHandicraft.Helper.ViewModel.Admin;

/// <summary>
/// Reference and master data. Small, mostly-static tables that everything else
/// depends on — an address cannot be saved without a state, a product cannot be
/// filtered without an attribute.
///
/// They share <see cref="IAdminGridRow"/> so the listing views can render a common
/// row shape (status pill, created date, edit/delete actions) without 14 near-identical
/// partials.
/// </summary>
public interface IAdminGridRow
{
    int Id { get; }
    string DisplayName { get; }
    bool IsActive { get; }
    DateTime CreatedOn { get; }
}

public class CountryGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string CountryName { get; set; } = string.Empty;
    public string IsoCode { get; set; } = string.Empty;
    public string? DialCode { get; set; }
    public string? Currency { get; set; }
    public string? FlagUrl { get; set; }
    public int StateCount { get; set; }
    public bool IsActive { get; set; } = true;
    public string? Description { get; set; }

    public string DisplayName => CountryName;
}

public class StateGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string StateName { get; set; } = string.Empty;
    public string? StateCode { get; set; }
    public int CountryId { get; set; }
    public string CountryName { get; set; } = string.Empty;

    /// <summary>Drives the GST place-of-supply on the invoice.</summary>
    public string? GstStateCode { get; set; }

    public int CityCount { get; set; }
    public bool IsActive { get; set; } = true;

    public string DisplayName => StateName;
}

public class CityGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string CityName { get; set; } = string.Empty;
    public int StateId { get; set; }
    public string StateName { get; set; } = string.Empty;
    public string CountryName { get; set; } = string.Empty;
    public bool IsMetro { get; set; }
    public int ZipCodeCount { get; set; }
    public bool IsActive { get; set; } = true;

    public string DisplayName => CityName;
}

/// <summary>
/// Serviceability. This table is what decides whether checkout can accept an address
/// at all, and what the PDP PIN check answers.
/// </summary>
public class ZipCodeGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string Pincode { get; set; } = string.Empty;
    public string CityName { get; set; } = string.Empty;
    public string StateName { get; set; } = string.Empty;
    public bool IsServiceable { get; set; } = true;
    public bool CodAvailable { get; set; } = true;
    public int StandardDeliveryDays { get; set; } = 6;
    public int? ExpressDeliveryDays { get; set; }
    public string? ZoneName { get; set; }
    public bool IsActive { get; set; } = true;

    public string DisplayName => Pincode;
}

public class BrandGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string BrandName { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string? LogoUrl { get; set; }
    public string? Description { get; set; }
    public int ProductCount { get; set; }
    public bool IsFeatured { get; set; }
    public bool IsActive { get; set; } = true;

    public string DisplayName => BrandName;
}

/// <summary>
/// A product attribute and its values. These become the PLP facets and the PDP option
/// selectors, which is why <see cref="IsFilterable"/> and <see cref="DisplayType"/>
/// matter far beyond this screen.
/// </summary>
public class AttributeGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string AttributeName { get; set; } = string.Empty;
    public string AttributeCode { get; set; } = string.Empty;

    /// <summary>Swatch, Pill, Dropdown or Text — decides how the PDP renders the option.</summary>
    public string DisplayType { get; set; } = "Pill";

    /// <summary>When true it appears as a filter group on the PLP rail.</summary>
    public bool IsFilterable { get; set; } = true;

    public bool IsRequired { get; set; }
    public int ValueCount { get; set; }
    public int UsedByProductCount { get; set; }
    public bool IsActive { get; set; } = true;

    public string DisplayName => AttributeName;
}

/// <summary>Generic lookup list — the Master screen manages several of these by type.</summary>
public class MasterGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string MasterType { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Code { get; set; }
    public string? Description { get; set; }
    public int SortOrder { get; set; }
    public bool IsSystem { get; set; }
    public bool IsActive { get; set; } = true;

    public string DisplayName => Name;
}

public class WarehouseGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string WarehouseName { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string State { get; set; } = string.Empty;
    public string Pincode { get; set; } = string.Empty;
    public string? ContactPerson { get; set; }
    public string? Phone { get; set; }
    public int SkuCount { get; set; }
    public bool IsDefault { get; set; }
    public bool IsActive { get; set; } = true;

    public string DisplayName => WarehouseName;
}

public class SupplierGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string SupplierName { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public string? ContactPerson { get; set; }
    public string? Phone { get; set; }
    public string? Email { get; set; }
    public string? Gstin { get; set; }
    public string City { get; set; } = string.Empty;
    public decimal OutstandingAmount { get; set; }
    public int PurchaseOrderCount { get; set; }
    public bool IsActive { get; set; } = true;

    public string DisplayName => SupplierName;
}

public class CourierGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string CourierName { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public string? LogoUrl { get; set; }
    public bool SupportsCod { get; set; } = true;
    public bool SupportsReversePickup { get; set; } = true;
    public string? TrackingUrlTemplate { get; set; }
    public int ActiveShipmentCount { get; set; }
    public decimal OnTimePercent { get; set; }
    public bool IsActive { get; set; } = true;

    public string DisplayName => CourierName;
}

/// <summary>Storefront navigation. Written here, rendered in the header and footer.</summary>
public class MenuGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;

    /// <summary>Header, MegaMenu, Footer or Mobile.</summary>
    public string Location { get; set; } = "Header";

    public string? Url { get; set; }
    public int? ParentId { get; set; }
    public string? ParentTitle { get; set; }
    public int SortOrder { get; set; }
    public int ChildCount { get; set; }
    public bool OpensInNewTab { get; set; }
    public bool IsActive { get; set; } = true;

    public string DisplayName => Title;
}

public class FaqGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string Question { get; set; } = string.Empty;
    public string Answer { get; set; } = string.Empty;

    /// <summary>Help centre topic, or a product id when it is a PDP FAQ.</summary>
    public string Topic { get; set; } = string.Empty;

    public int SortOrder { get; set; }
    public int HelpfulCount { get; set; }
    public int NotHelpfulCount { get; set; }
    public bool IsActive { get; set; } = true;

    public string DisplayName => Question;
}

public class BlogCategoryGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int PostCount { get; set; }
    public bool IsActive { get; set; } = true;

    public string DisplayName => Name;
}

public class BlogAuthorGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string? Bio { get; set; }
    public string? PhotoUrl { get; set; }
    public string? Email { get; set; }
    public int PostCount { get; set; }
    public bool IsActive { get; set; } = true;

    public string DisplayName => Name;
}
