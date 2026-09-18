using System.ComponentModel.DataAnnotations;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace ChamundaHandicraft.Helper.ViewModel.Admin;

#region 1. Warehouse

public class WarehouseSaveRequest
{
    public int Id { get; set; }

    [Required(ErrorMessage = "Warehouse name is required.")]
    [StringLength(150, ErrorMessage = "Warehouse name cannot exceed 150 characters.")]
    [Display(Name = "Warehouse Name")]
    public string WarehouseName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Warehouse code is required.")]
    [StringLength(50, ErrorMessage = "Warehouse code cannot exceed 50 characters.")]
    [RegularExpression(@"^[A-Za-z0-9\-_]+$", ErrorMessage = "Code can only contain letters, numbers, hyphens and underscores.")]
    [Display(Name = "Warehouse Code")]
    public string Code { get; set; } = string.Empty;

    [Display(Name = "Contact Person")]
    [StringLength(100, ErrorMessage = "Contact person cannot exceed 100 characters.")]
    public string? ContactPerson { get; set; }

    [EmailAddress(ErrorMessage = "Please enter a valid email address.")]
    [StringLength(150, ErrorMessage = "Email cannot exceed 150 characters.")]
    public string? Email { get; set; }

    [Phone(ErrorMessage = "Please enter a valid phone number.")]
    [StringLength(20, ErrorMessage = "Phone cannot exceed 20 characters.")]
    public string? Phone { get; set; }

    [Display(Name = "Address Line 1")]
    [StringLength(250, ErrorMessage = "Address Line 1 cannot exceed 250 characters.")]
    public string? AddressLine1 { get; set; }

    [Display(Name = "Address Line 2")]
    [StringLength(250, ErrorMessage = "Address Line 2 cannot exceed 250 characters.")]
    public string? AddressLine2 { get; set; }

    [StringLength(100, ErrorMessage = "City cannot exceed 100 characters.")]
    public string? City { get; set; }

    [Display(Name = "State")]
    public int? StateId { get; set; }

    [Display(Name = "State Name")]
    public string? StateName { get; set; }

    [Display(Name = "Country")]
    public int? CountryId { get; set; }

    [Display(Name = "Pincode / Postal Code")]
    [StringLength(20, ErrorMessage = "Pincode cannot exceed 20 characters.")]
    public string? Pincode { get; set; }

    [Display(Name = "Default Warehouse")]
    public bool IsDefault { get; set; }

    [Display(Name = "Fulfillment Center")]
    public bool IsFulfillmentCenter { get; set; } = true;

    [Display(Name = "Status")]
    public bool IsActive { get; set; } = true;

    [StringLength(500, ErrorMessage = "Notes cannot exceed 500 characters.")]
    public string? Notes { get; set; }
}

public class WarehouseDetailViewModel
{
    public int Id { get; set; }
    public string WarehouseName { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public string? ContactPerson { get; set; }
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? AddressLine1 { get; set; }
    public string? AddressLine2 { get; set; }
    public string? City { get; set; }
    public int? StateId { get; set; }
    public string? StateName { get; set; }
    public int? CountryId { get; set; }
    public string? CountryName { get; set; }
    public string? Pincode { get; set; }
    public bool IsDefault { get; set; }
    public bool IsFulfillmentCenter { get; set; }
    public bool IsActive { get; set; }
    public string? Notes { get; set; }
    public int TotalStockItems { get; set; }
    public int TotalOnHandUnits { get; set; }
    public DateTime CreatedOn { get; set; }
    public DateTime? UpdatedOn { get; set; }
}

#endregion

#region 2. Supplier

public class SupplierSaveRequest
{
    public int Id { get; set; }

    [Required(ErrorMessage = "Supplier name is required.")]
    [StringLength(200, ErrorMessage = "Supplier name cannot exceed 200 characters.")]
    [Display(Name = "Supplier Name")]
    public string SupplierName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Supplier code is required.")]
    [StringLength(50, ErrorMessage = "Supplier code cannot exceed 50 characters.")]
    [RegularExpression(@"^[A-Za-z0-9\-_]+$", ErrorMessage = "Code can only contain letters, numbers, hyphens and underscores.")]
    [Display(Name = "Supplier Code")]
    public string Code { get; set; } = string.Empty;

    [Display(Name = "Contact Person")]
    [StringLength(100, ErrorMessage = "Contact person cannot exceed 100 characters.")]
    public string? ContactPerson { get; set; }

    [EmailAddress(ErrorMessage = "Please enter a valid email address.")]
    [StringLength(150, ErrorMessage = "Email cannot exceed 150 characters.")]
    public string? Email { get; set; }

    [Phone(ErrorMessage = "Please enter a valid phone number.")]
    [StringLength(20, ErrorMessage = "Phone cannot exceed 20 characters.")]
    public string? Phone { get; set; }

    [Display(Name = "Address Line 1")]
    [StringLength(250, ErrorMessage = "Address Line 1 cannot exceed 250 characters.")]
    public string? AddressLine1 { get; set; }

    [Display(Name = "Address Line 2")]
    [StringLength(250, ErrorMessage = "Address Line 2 cannot exceed 250 characters.")]
    public string? AddressLine2 { get; set; }

    [StringLength(100, ErrorMessage = "City cannot exceed 100 characters.")]
    public string? City { get; set; }

    [Display(Name = "State")]
    public int? StateId { get; set; }

    [Display(Name = "State Name")]
    public string? StateName { get; set; }

    [Display(Name = "Country")]
    public int? CountryId { get; set; }

    [Display(Name = "Pincode")]
    [StringLength(20, ErrorMessage = "Pincode cannot exceed 20 characters.")]
    public string? Pincode { get; set; }

    [Display(Name = "GSTIN / Tax ID")]
    [StringLength(20, ErrorMessage = "GSTIN cannot exceed 20 characters.")]
    public string? Gstin { get; set; }

    [Display(Name = "PAN Number")]
    [StringLength(20, ErrorMessage = "PAN cannot exceed 20 characters.")]
    public string? Pan { get; set; }

    [Display(Name = "Payment Terms (Days)")]
    [Range(0, 365, ErrorMessage = "Payment terms must be between 0 and 365 days.")]
    public int PaymentTermsDays { get; set; } = 30;

    [Display(Name = "Opening Balance")]
    [Range(0, 100000000, ErrorMessage = "Opening balance must be greater than or equal to 0.")]
    public decimal OpeningBalance { get; set; } = 0.00m;

    [Display(Name = "Outstanding Amount")]
    public decimal OutstandingAmount { get; set; } = 0.00m;

    [Display(Name = "Bank Name")]
    [StringLength(100, ErrorMessage = "Bank name cannot exceed 100 characters.")]
    public string? BankName { get; set; }

    [Display(Name = "Account Number")]
    [StringLength(50, ErrorMessage = "Account number cannot exceed 50 characters.")]
    public string? AccountNumber { get; set; }

    [Display(Name = "IFSC / Branch Code")]
    [StringLength(20, ErrorMessage = "IFSC code cannot exceed 20 characters.")]
    public string? IfscCode { get; set; }

    [Display(Name = "Status")]
    public bool IsActive { get; set; } = true;

    [StringLength(500, ErrorMessage = "Notes cannot exceed 500 characters.")]
    public string? Notes { get; set; }
}

public class SupplierDetailViewModel
{
    public int Id { get; set; }
    public string SupplierName { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public string? ContactPerson { get; set; }
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? AddressLine1 { get; set; }
    public string? AddressLine2 { get; set; }
    public string? City { get; set; }
    public int? StateId { get; set; }
    public string? StateName { get; set; }
    public int? CountryId { get; set; }
    public string? CountryName { get; set; }
    public string? Pincode { get; set; }
    public string? Gstin { get; set; }
    public string? Pan { get; set; }
    public int PaymentTermsDays { get; set; }
    public decimal OpeningBalance { get; set; }
    public decimal OutstandingAmount { get; set; }
    public string? BankName { get; set; }
    public string? AccountNumber { get; set; }
    public string? IfscCode { get; set; }
    public bool IsActive { get; set; }
    public string? Notes { get; set; }
    public int PurchaseOrderCount { get; set; }
    public DateTime CreatedOn { get; set; }
    public DateTime? UpdatedOn { get; set; }
}

#endregion

#region 3. Stock / Inventory

public class StockSaveRequest
{
    public long Id { get; set; }

    [Required(ErrorMessage = "Product selection is required.")]
    [Range(1, int.MaxValue, ErrorMessage = "Please select a valid product.")]
    [Display(Name = "Product")]
    public int ProductId { get; set; }

    [Display(Name = "Variant")]
    public int? VariantId { get; set; }

    [Required(ErrorMessage = "Warehouse selection is required.")]
    [Range(1, int.MaxValue, ErrorMessage = "Please select a valid warehouse.")]
    [Display(Name = "Warehouse")]
    public int WarehouseId { get; set; }

    [Required(ErrorMessage = "On Hand Quantity is required.")]
    [Range(0, 1000000, ErrorMessage = "On Hand Quantity must be 0 or greater.")]
    [Display(Name = "On Hand Quantity")]
    public int OnHand { get; set; }

    [Range(0, 100000, ErrorMessage = "Low Stock Threshold must be 0 or greater.")]
    [Display(Name = "Low Stock Threshold")]
    public int LowStockThreshold { get; set; } = 5;

    [Display(Name = "Bin / Shelf Location")]
    [StringLength(100, ErrorMessage = "Bin location cannot exceed 100 characters.")]
    public string? BinLocation { get; set; }

    [Display(Name = "Notes / Reason")]
    [StringLength(500, ErrorMessage = "Notes cannot exceed 500 characters.")]
    public string? Notes { get; set; }
}

public class InventoryDetailViewModel
{
    public long Id { get; set; }
    public int ProductId { get; set; }
    public int? VariantId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string Sku { get; set; } = string.Empty;
    public string? Barcode { get; set; }
    public int WarehouseId { get; set; }
    public string WarehouseName { get; set; } = string.Empty;
    public int OnHand { get; set; }
    public int Reserved { get; set; }
    public int Incoming { get; set; }
    public int Available { get; set; }
    public int LowStockThreshold { get; set; }
    public string? BinLocation { get; set; }
    public DateTime? LastCountedOn { get; set; }
    public decimal CostPrice { get; set; }
    public decimal Price { get; set; }
    public decimal Valuation => OnHand * CostPrice;
    public string StockState { get; set; } = "InStock";
    public DateTime CreatedOn { get; set; }
    public DateTime? UpdatedOn { get; set; }
    public List<InventoryTransactionViewModel> Ledger { get; set; } = new();
}

public class InventoryTransactionViewModel
{
    public long Id { get; set; }
    public string TransactionNumber { get; set; } = string.Empty;
    public string TransactionType { get; set; } = string.Empty;
    public int QuantityBefore { get; set; }
    public int QuantityChange { get; set; }
    public int QuantityAfter { get; set; }
    public decimal? UnitCost { get; set; }
    public decimal? TotalCost { get; set; }
    public string? ReferenceType { get; set; }
    public string? ReferenceNumber { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedOn { get; set; }
    public string? CreatedByName { get; set; }
}

public class InventoryKpiSummaryViewModel
{
    public int TotalSkus { get; set; }
    public int InStockCount { get; set; }
    public int LowStockCount { get; set; }
    public int OutOfStockCount { get; set; }
    public int TotalOnHandUnits { get; set; }
    public int TotalReservedUnits { get; set; }
    public int TotalIncomingUnits { get; set; }
    public decimal TotalValuation { get; set; }
}

#endregion

#region 4. Purchase Order

public class PurchaseOrderSaveRequest
{
    public int Id { get; set; }

    [Display(Name = "PO Number")]
    public string? PoNumber { get; set; }

    [Required(ErrorMessage = "Supplier is required.")]
    [Range(1, int.MaxValue, ErrorMessage = "Please select a valid supplier.")]
    [Display(Name = "Supplier")]
    public int SupplierId { get; set; }

    [Required(ErrorMessage = "Warehouse is required.")]
    [Range(1, int.MaxValue, ErrorMessage = "Please select a destination warehouse.")]
    [Display(Name = "Destination Warehouse")]
    public int WarehouseId { get; set; }

    [Required(ErrorMessage = "Order date is required.")]
    [Display(Name = "Order Date")]
    public DateTime OrderDate { get; set; } = DateTime.Today;

    [Display(Name = "Expected Delivery Date")]
    public DateTime? ExpectedDate { get; set; }

    [Display(Name = "Payment Terms")]
    [StringLength(100, ErrorMessage = "Payment terms cannot exceed 100 characters.")]
    public string? PaymentTerms { get; set; }

    [Display(Name = "Notes / Instructions")]
    [StringLength(1000, ErrorMessage = "Notes cannot exceed 1000 characters.")]
    public string? Notes { get; set; }

    [Display(Name = "Sub Total")]
    public decimal SubTotal { get; set; }

    [Display(Name = "Tax Amount")]
    public decimal TaxAmount { get; set; }

    [Display(Name = "Shipping Amount")]
    public decimal ShippingAmount { get; set; }

    [Display(Name = "Discount Amount")]
    public decimal DiscountAmount { get; set; }

    [Display(Name = "Total Amount")]
    public decimal TotalAmount { get; set; }

    public string Status { get; set; } = "Draft";

    public List<PurchaseOrderLineRequest> Lines { get; set; } = new();
}

public class PurchaseOrderLineRequest
{
    public int Id { get; set; }

    [Required(ErrorMessage = "Product is required.")]
    [Range(1, int.MaxValue, ErrorMessage = "Select a product.")]
    public int ProductId { get; set; }

    public int? VariantId { get; set; }
    public string? Sku { get; set; }
    public string? ProductName { get; set; }

    [Required(ErrorMessage = "Quantity is required.")]
    [Range(1, 1000000, ErrorMessage = "Quantity must be at least 1.")]
    public int OrderedQuantity { get; set; } = 1;

    [Required(ErrorMessage = "Unit cost is required.")]
    [Range(0.01, 10000000, ErrorMessage = "Unit cost must be greater than 0.")]
    public decimal UnitCost { get; set; }

    public decimal TaxPercent { get; set; }
    public decimal TaxAmount { get; set; }
    public decimal LineTotal { get; set; }
    public string? Notes { get; set; }
}

public class PurchaseOrderDetailViewModel
{
    public int Id { get; set; }
    public string PoNumber { get; set; } = string.Empty;
    public int SupplierId { get; set; }
    public string SupplierName { get; set; } = string.Empty;
    public string? SupplierEmail { get; set; }
    public string? SupplierPhone { get; set; }
    public int WarehouseId { get; set; }
    public string WarehouseName { get; set; } = string.Empty;
    public DateTime OrderDate { get; set; }
    public DateTime? ExpectedDate { get; set; }
    public DateTime? ReceivedDate { get; set; }
    public string Status { get; set; } = "Draft";
    public string? PaymentTerms { get; set; }
    public string? Notes { get; set; }
    public decimal SubTotal { get; set; }
    public decimal TaxAmount { get; set; }
    public decimal ShippingAmount { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal TotalAmount { get; set; }
    public int LineCount { get; set; }
    public int QuantityOrdered { get; set; }
    public int QuantityReceived { get; set; }
    public DateTime CreatedOn { get; set; }
    public List<PurchaseOrderLineDetailViewModel> Lines { get; set; } = new();
}

public class PurchaseOrderLineDetailViewModel
{
    public int Id { get; set; }
    public int ProductId { get; set; }
    public int? VariantId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string Sku { get; set; } = string.Empty;
    public int QuantityOrdered { get; set; }
    public int QuantityReceived { get; set; }
    public decimal UnitCost { get; set; }
    public decimal TaxPercent { get; set; }
    public decimal TaxAmount { get; set; }
    public decimal LineTotal { get; set; }
    public string? Notes { get; set; }
    public bool IsFullyReceived => QuantityReceived >= QuantityOrdered;
}

public class PurchaseReceiveStockRequest
{
    [Required]
    public int PurchaseOrderId { get; set; }

    [Required(ErrorMessage = "Receive date is required.")]
    public DateTime ReceivedDate { get; set; } = DateTime.Today;

    public string? Notes { get; set; }

    public List<PurchaseReceiveLineItem> Items { get; set; } = new();
}

public class PurchaseReceiveLineItem
{
    public int LineId { get; set; }
    public int ProductId { get; set; }
    public int? VariantId { get; set; }
    public int QuantityToReceive { get; set; }
}

#endregion

#region 5. Stock Adjustment

public class StockAdjustmentSaveRequest
{
    public int Id { get; set; }

    [Display(Name = "Adjustment Number")]
    public string? AdjustmentNumber { get; set; }

    [Required(ErrorMessage = "Warehouse is required.")]
    [Range(1, int.MaxValue, ErrorMessage = "Select a warehouse.")]
    [Display(Name = "Warehouse")]
    public int WarehouseId { get; set; }

    [Required(ErrorMessage = "Product is required.")]
    [Range(1, int.MaxValue, ErrorMessage = "Select a product.")]
    [Display(Name = "Product")]
    public int ProductId { get; set; }

    [Display(Name = "Variant")]
    public int? VariantId { get; set; }

    [Required(ErrorMessage = "Adjustment reason is required.")]
    [Range(1, int.MaxValue, ErrorMessage = "Select an adjustment reason.")]
    [Display(Name = "Adjustment Reason")]
    public int? ReasonCodeId { get; set; }

    [Display(Name = "Reason")]
    public string? Reason { get; set; }

    [Display(Name = "Current Stock")]
    public int QuantityBefore { get; set; }

    [Required(ErrorMessage = "Quantity change is required.")]
    [Range(-1000000, 1000000, ErrorMessage = "Invalid quantity change.")]
    [Display(Name = "Quantity Change (+ / -)")]
    public int QuantityChange { get; set; }

    [Display(Name = "New Stock (After)")]
    public int QuantityAfter { get; set; }

    [Display(Name = "Notes / Remarks")]
    [StringLength(500, ErrorMessage = "Notes cannot exceed 500 characters.")]
    public string? Note { get; set; }
}

public class StockAdjustmentDetailViewModel
{
    public int Id { get; set; }
    public string AdjustmentNumber { get; set; } = string.Empty;
    public int WarehouseId { get; set; }
    public string WarehouseName { get; set; } = string.Empty;
    public int ProductId { get; set; }
    public int? VariantId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string Sku { get; set; } = string.Empty;
    public int? ReasonCodeId { get; set; }
    public string Reason { get; set; } = string.Empty;
    public int QuantityBefore { get; set; }
    public int QuantityChange { get; set; }
    public int QuantityAfter { get; set; }
    public string? Note { get; set; }
    public DateTime AdjustedOn { get; set; }
    public string? CreatedByName { get; set; }
}

#endregion

#region 6. Stock Transfer

public class StockTransferSaveRequest
{
    public int Id { get; set; }

    [Display(Name = "Transfer Number")]
    public string? TransferNumber { get; set; }

    [Required(ErrorMessage = "Source warehouse is required.")]
    [Range(1, int.MaxValue, ErrorMessage = "Select source warehouse.")]
    [Display(Name = "From Warehouse")]
    public int FromWarehouseId { get; set; }

    [Required(ErrorMessage = "Destination warehouse is required.")]
    [Range(1, int.MaxValue, ErrorMessage = "Select destination warehouse.")]
    [Display(Name = "To Warehouse")]
    public int ToWarehouseId { get; set; }

    [Required(ErrorMessage = "Transfer date is required.")]
    [Display(Name = "Transfer Date")]
    public DateTime TransferDate { get; set; } = DateTime.Today;

    [Display(Name = "Carrier / Logistics")]
    [StringLength(100, ErrorMessage = "Carrier cannot exceed 100 characters.")]
    public string? Carrier { get; set; }

    [Display(Name = "Tracking / Consignment Number")]
    [StringLength(100, ErrorMessage = "Tracking number cannot exceed 100 characters.")]
    public string? TrackingNumber { get; set; }

    [Display(Name = "Notes")]
    [StringLength(500, ErrorMessage = "Notes cannot exceed 500 characters.")]
    public string? Notes { get; set; }

    public string Status { get; set; } = "Draft";

    public List<StockTransferLineRequest> Lines { get; set; } = new();
}

public class StockTransferLineRequest
{
    public int Id { get; set; }

    [Required(ErrorMessage = "Product is required.")]
    [Range(1, int.MaxValue, ErrorMessage = "Select a product.")]
    public int ProductId { get; set; }

    public int? VariantId { get; set; }
    public string? Sku { get; set; }
    public string? ProductName { get; set; }

    [Required(ErrorMessage = "Transfer quantity is required.")]
    [Range(1, 1000000, ErrorMessage = "Quantity must be at least 1.")]
    public int Quantity { get; set; } = 1;

    public string? Notes { get; set; }
}

public class StockTransferDetailViewModel
{
    public int Id { get; set; }
    public string TransferNumber { get; set; } = string.Empty;
    public int FromWarehouseId { get; set; }
    public string FromWarehouseName { get; set; } = string.Empty;
    public int ToWarehouseId { get; set; }
    public string ToWarehouseName { get; set; } = string.Empty;
    public DateTime TransferDate { get; set; }
    public DateTime? ShippedDate { get; set; }
    public DateTime? ReceivedDate { get; set; }
    public string Status { get; set; } = "Draft";
    public string? Carrier { get; set; }
    public string? TrackingNumber { get; set; }
    public string? Notes { get; set; }
    public int TotalQuantity { get; set; }
    public int LineCount { get; set; }
    public DateTime CreatedOn { get; set; }
    public List<StockTransferLineDetailViewModel> Lines { get; set; } = new();
}

public class StockTransferLineDetailViewModel
{
    public int Id { get; set; }
    public int ProductId { get; set; }
    public int? VariantId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string Sku { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public string? Notes { get; set; }
}

#endregion

#region 7. Stock Rate / Valuation

public class StockRateGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id => ProductId;
    public int ProductId { get; set; }
    public int? VariantId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string Sku { get; set; } = string.Empty;
    public string? Barcode { get; set; }
    public int OnHand { get; set; }
    public int Reserved { get; set; }
    public int Available { get; set; }
    public decimal CostPrice { get; set; }
    public decimal Price { get; set; }
    public decimal Mrp { get; set; }
    public decimal Valuation { get; set; }
    public decimal MarginAmount { get; set; }
    public decimal MarginPercent { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public bool IsActive => OnHand > 0;
    public string DisplayName => ProductName;
}

public class StockRateSaveRequest
{
    [Required]
    [Range(1, int.MaxValue, ErrorMessage = "Product is required.")]
    public int ProductId { get; set; }

    public int? VariantId { get; set; }

    [Required(ErrorMessage = "Cost price is required.")]
    [Range(0, 10000000, ErrorMessage = "Cost price cannot be negative.")]
    [Display(Name = "Cost Price (INR)")]
    public decimal CostPrice { get; set; }

    [Required(ErrorMessage = "Selling price is required.")]
    [Range(0, 10000000, ErrorMessage = "Selling price cannot be negative.")]
    [Display(Name = "Selling Price (INR)")]
    public decimal Price { get; set; }

    [Required(ErrorMessage = "MRP is required.")]
    [Range(0, 10000000, ErrorMessage = "MRP cannot be negative.")]
    [Display(Name = "MRP (INR)")]
    public decimal Mrp { get; set; }
}

public class StockRateDetailViewModel
{
    public int ProductId { get; set; }
    public int? VariantId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string Sku { get; set; } = string.Empty;
    public string? Barcode { get; set; }
    public decimal CostPrice { get; set; }
    public decimal Price { get; set; }
    public decimal Mrp { get; set; }
    public int TotalOnHand { get; set; }
}

#endregion
