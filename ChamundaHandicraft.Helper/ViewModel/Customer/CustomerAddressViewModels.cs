using System.ComponentModel.DataAnnotations;
using ChamundaHandicraft.Helper.Enums;

namespace ChamundaHandicraft.Helper.ViewModel.Customer;

/// <summary>
/// Address save / update request with full model validations.
/// </summary>
public class CustomerAddressSaveRequest
{
    public int Id { get; set; }

    public int CustomerId { get; set; }

    [Required(ErrorMessage = "Full name is required.")]
    [StringLength(100, MinimumLength = 2, ErrorMessage = "Full name must be between 2 and 100 characters.")]
    [Display(Name = "Full Name")]
    public string FullName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Mobile number is required.")]
    [RegularExpression(@"^[0-9\s]{10,14}$", ErrorMessage = "Please enter a valid 10-digit mobile number.")]
    [Display(Name = "Mobile Number")]
    public string Phone { get; set; } = string.Empty;

    [RegularExpression(@"^[0-9\s]{10,14}$", ErrorMessage = "Please enter a valid alternate mobile number.")]
    [Display(Name = "Alternate Mobile Number")]
    public string? AlternatePhone { get; set; }

    [Required(ErrorMessage = "Flat, house no., building is required.")]
    [StringLength(200, MinimumLength = 3, ErrorMessage = "Line 1 must be between 3 and 200 characters.")]
    [Display(Name = "Flat / Building")]
    public string Line1 { get; set; } = string.Empty;

    [Required(ErrorMessage = "Area, street, sector is required.")]
    [StringLength(200, MinimumLength = 3, ErrorMessage = "Line 2 must be between 3 and 200 characters.")]
    [Display(Name = "Area / Street")]
    public string Line2 { get; set; } = string.Empty;

    [StringLength(150)]
    [Display(Name = "Landmark")]
    public string? Landmark { get; set; }

    [Required(ErrorMessage = "City is required.")]
    [StringLength(100)]
    [Display(Name = "City")]
    public string City { get; set; } = string.Empty;

    [Required(ErrorMessage = "State is required.")]
    [StringLength(100)]
    [Display(Name = "State")]
    public string State { get; set; } = string.Empty;

    [Required(ErrorMessage = "Country is required.")]
    [StringLength(100)]
    [Display(Name = "Country")]
    public string Country { get; set; } = "India";

    [Required(ErrorMessage = "PIN code is required.")]
    [RegularExpression(@"^[1-9][0-9]{5}$", ErrorMessage = "Please enter a valid 6-digit Indian PIN code.")]
    [Display(Name = "PIN Code")]
    public string Pincode { get; set; } = string.Empty;

    [Display(Name = "Address Type")]
    public AddressType Label { get; set; } = AddressType.Home;

    [Display(Name = "Make this my default address")]
    public bool IsDefault { get; set; }
}

/// <summary>
/// Paged query request for customer address book with filter and sort.
/// </summary>
public class CustomerAddressListRequest
{
    public int CustomerId { get; set; }
    public string? Search { get; set; }
    public string? SortBy { get; set; }
    public bool SortDescending { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}
