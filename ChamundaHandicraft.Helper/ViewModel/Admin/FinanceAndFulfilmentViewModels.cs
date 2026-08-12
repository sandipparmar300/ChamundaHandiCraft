using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Common;

namespace ChamundaHandicraft.Helper.ViewModel.Admin;

#region Payments & finance

public class PaymentGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string TransactionId { get; set; } = string.Empty;
    public string OrderNumber { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public PaymentMethod Method { get; set; }
    public PaymentStatus Status { get; set; }
    public string? GatewayName { get; set; }
    public string? GatewayReference { get; set; }
    public DateTime PaidOn { get; set; }
    public decimal GatewayFee { get; set; }

    /// <summary>What actually reaches the bank account after the gateway takes its cut.</summary>
    public decimal NetAmount => Amount - GatewayFee;

    public bool IsActive => Status is PaymentStatus.Paid or PaymentStatus.Authorised;
    public string DisplayName => TransactionId;
}

public class RefundGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string RefundNumber { get; set; } = string.Empty;
    public string OrderNumber { get; set; } = string.Empty;
    public string? RmaNumber { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public PaymentMethod OriginalMethod { get; set; }
    public string Status { get; set; } = "Pending";
    public string? Reason { get; set; }
    public DateTime RequestedOn { get; set; }
    public DateTime? CompletedOn { get; set; }

    /// <summary>The reference the customer quotes when their bank hasn't shown it.</summary>
    public string? GatewayReference { get; set; }

    public bool RequiresApproval { get; set; }

    public bool IsActive => Status != "Rejected";
    public string DisplayName => RefundNumber;
}

public class SettlementGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string SettlementId { get; set; } = string.Empty;
    public DateTime SettledOn { get; set; }
    public decimal GrossAmount { get; set; }
    public decimal Fees { get; set; }
    public decimal Refunds { get; set; }
    public decimal NetAmount { get; set; }
    public int TransactionCount { get; set; }
    public string? BankReference { get; set; }
    public string Status { get; set; } = "Settled";

    public bool IsActive => true;
    public string DisplayName => SettlementId;
}

/// <summary>
/// A chargeback or gateway dispute. Time-critical — missing the evidence window loses
/// the money automatically, so the grid leads with the deadline.
/// </summary>
public class DisputeGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string DisputeId { get; set; } = string.Empty;
    public string OrderNumber { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Reason { get; set; } = string.Empty;
    public string Status { get; set; } = "Open";
    public DateTime RaisedOn { get; set; }
    public DateTime EvidenceDueOn { get; set; }

    public int DaysToRespond => Math.Max(0, (EvidenceDueOn.Date - DateTime.Today).Days);
    public bool IsUrgent => DaysToRespond <= 2 && Status == "Open";

    public bool IsActive => Status == "Open";
    public string DisplayName => DisputeId;
}

public class InvoiceGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string InvoiceNumber { get; set; } = string.Empty;
    public string OrderNumber { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string? CustomerGstin { get; set; }
    public DateTime InvoiceDate { get; set; }
    public decimal TaxableValue { get; set; }
    public decimal Cgst { get; set; }
    public decimal Sgst { get; set; }
    public decimal Igst { get; set; }
    public decimal Total { get; set; }
    public string PlaceOfSupply { get; set; } = string.Empty;
    public string? PdfUrl { get; set; }

    public bool IsActive => true;
    public string DisplayName => InvoiceNumber;
}

#endregion

#region Shipping & fulfilment

public class ShipmentGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string AwbNumber { get; set; } = string.Empty;
    public string OrderNumber { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string CourierName { get; set; } = string.Empty;
    public ShipmentStatus Status { get; set; }
    public DateTime? PickedUpOn { get; set; }
    public DateTime? DeliveredOn { get; set; }
    public DateTime? PromisedBy { get; set; }
    public string DestinationCity { get; set; } = string.Empty;
    public string DestinationPincode { get; set; } = string.Empty;
    public decimal WeightKg { get; set; }
    public decimal ShippingCost { get; set; }
    public string? LabelUrl { get; set; }

    /// <summary>Past its promised date and not yet delivered.</summary>
    public bool IsBreachingSla =>
        PromisedBy is not null && Status != ShipmentStatus.Delivered && PromisedBy < DateTime.Today;

    public bool IsActive => Status != ShipmentStatus.Rto;
    public string DisplayName => AwbNumber;
}

/// <summary>A shipping zone and its rate card. Decides what checkout charges.</summary>
public class ShippingZoneGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string ZoneName { get; set; } = string.Empty;
    public string Coverage { get; set; } = string.Empty;
    public decimal BaseRate { get; set; }
    public decimal PerKgRate { get; set; }
    public decimal FreeAboveAmount { get; set; }
    public int StandardDays { get; set; }
    public int? ExpressDays { get; set; }
    public decimal? ExpressSurcharge { get; set; }
    public bool CodAvailable { get; set; } = true;
    public decimal CodFee { get; set; }
    public int PincodeCount { get; set; }
    public bool IsActive { get; set; } = true;

    public string DisplayName => ZoneName;
}

#endregion

#region Inventory operations

public class PurchaseOrderGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string PoNumber { get; set; } = string.Empty;
    public string SupplierName { get; set; } = string.Empty;
    public DateTime OrderedOn { get; set; }
    public DateTime? ExpectedOn { get; set; }
    public DateTime? ReceivedOn { get; set; }
    public int LineCount { get; set; }
    public int QuantityOrdered { get; set; }
    public int QuantityReceived { get; set; }
    public decimal TotalValue { get; set; }
    public string Status { get; set; } = "Draft";
    public string? WarehouseName { get; set; }

    public bool IsFullyReceived => QuantityReceived >= QuantityOrdered && QuantityOrdered > 0;
    public bool IsActive => Status != "Cancelled";
    public string DisplayName => PoNumber;
}

/// <summary>
/// A manual stock correction. Every adjustment needs a reason — an unexplained
/// quantity change is how shrinkage hides.
/// </summary>
public class StockAdjustmentGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string AdjustmentNumber { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public string Sku { get; set; } = string.Empty;
    public string WarehouseName { get; set; } = string.Empty;
    public int QuantityBefore { get; set; }
    public int QuantityChange { get; set; }
    public int QuantityAfter { get; set; }
    public string Reason { get; set; } = string.Empty;
    public string? Note { get; set; }
    public DateTime AdjustedOn { get; set; }

    public bool IsIncrease => QuantityChange > 0;
    public bool IsActive => true;
    public string DisplayName => AdjustmentNumber;
}

public class StockTakeGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string StockTakeNumber { get; set; } = string.Empty;
    public string WarehouseName { get; set; } = string.Empty;
    public DateTime StartedOn { get; set; }
    public DateTime? CompletedOn { get; set; }
    public int SkusCounted { get; set; }
    public int DiscrepancyCount { get; set; }
    public decimal DiscrepancyValue { get; set; }
    public string Status { get; set; } = "In Progress";

    public bool IsActive => Status != "Cancelled";
    public string DisplayName => StockTakeNumber;
}

public class StockTransferGridItem : AuditableViewModel, IAdminGridRow
{
    public int Id { get; set; }
    public string TransferNumber { get; set; } = string.Empty;
    public string FromWarehouse { get; set; } = string.Empty;
    public string ToWarehouse { get; set; } = string.Empty;
    public int SkuCount { get; set; }
    public int TotalQuantity { get; set; }
    public DateTime InitiatedOn { get; set; }
    public DateTime? ReceivedOn { get; set; }
    public string Status { get; set; } = "In Transit";

    public bool IsActive => Status != "Cancelled";
    public string DisplayName => TransferNumber;
}

#endregion
