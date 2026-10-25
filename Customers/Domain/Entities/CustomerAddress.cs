using ChamundaHandicraft.Helper.Enums;

namespace Customers.Domain.Entities;

public class CustomerAddress
{
    public int Id { get; set; }
    public int CustomerId { get; set; }
    public byte LabelType { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string? AlternatePhone { get; set; }
    public string Line1 { get; set; } = string.Empty;
    public string? Line2 { get; set; }
    public string? Landmark { get; set; }
    public int? CityId { get; set; }
    public int? StateId { get; set; }
    public int? CountryId { get; set; }
    public string CityName { get; set; } = string.Empty;
    public string StateName { get; set; } = string.Empty;
    public string CountryName { get; set; } = "India";
    public string Pincode { get; set; } = string.Empty;
    public bool IsDefault { get; set; }
    public DateTime CreatedAt { get; set; }
    public int? CreatedBy { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }
    public bool IsActive { get; set; } = true;
    public bool IsDeleted { get; set; }

    public int TotalCount { get; set; }

    public AddressType Label => (AddressType)LabelType;
}
