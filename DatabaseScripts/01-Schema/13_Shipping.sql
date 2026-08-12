/* =============================================================================
   13_Shipping.sql — Zones, Rates, Couriers, Shipments, TrackingEvents, Manifests
   -----------------------------------------------------------------------------
   Delivery is always quoted to the shopper as a date — "Get it by Wed, 12 Aug" —
   never as "3–5 business days". The date is computed from the zone's day counts
   plus the cut-off time, so it must be derivable from these tables alone.
   ============================================================================= */

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.ShippingZones', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ShippingZones
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        ZoneName            NVARCHAR(150)   NOT NULL,
        ZoneCode            VARCHAR(32)     NOT NULL,
        /* Plain-language summary shown in the admin grid — "Gujarat, Maharashtra". */
        Coverage            NVARCHAR(500)   NULL,
        GeoZoneId           INT             NULL,

        BaseRate            DECIMAL(18,2)   NOT NULL CONSTRAINT DF_ShippingZones_BaseRate DEFAULT (0),
        PerKgRate           DECIMAL(18,2)   NOT NULL CONSTRAINT DF_ShippingZones_PerKgRate DEFAULT (0),
        /* Order value above which shipping is free for this zone. */
        FreeAboveAmount     DECIMAL(18,2)   NOT NULL CONSTRAINT DF_ShippingZones_FreeAboveAmount DEFAULT (0),
        StandardDays        INT             NOT NULL CONSTRAINT DF_ShippingZones_StandardDays DEFAULT (6),
        ExpressDays         INT             NULL,
        ExpressSurcharge    DECIMAL(18,2)   NULL,
        CodAvailable        BIT             NOT NULL CONSTRAINT DF_ShippingZones_CodAvailable DEFAULT (1),
        CodFee              DECIMAL(18,2)   NOT NULL CONSTRAINT DF_ShippingZones_CodFee DEFAULT (0),
        /* Orders placed after this local time ship the next working day. */
        CutOffTime          TIME(0)         NULL,
        SortOrder           INT             NOT NULL CONSTRAINT DF_ShippingZones_SortOrder DEFAULT (0),

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_ShippingZones_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_ShippingZones_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_ShippingZones_IsDeleted DEFAULT (0),

        CONSTRAINT PK_ShippingZones PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_ShippingZones_Code UNIQUE (ZoneCode),
        CONSTRAINT FK_ShippingZones_GeoZones FOREIGN KEY (GeoZoneId) REFERENCES dbo.GeoZones (Id)
    );
END
GO

/* Which pincodes a zone covers. A pincode belongs to exactly one shipping zone,
   so a rate lookup can never return two answers. */
IF OBJECT_ID(N'dbo.ShippingZonePincodes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ShippingZonePincodes
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        ShippingZoneId  INT             NOT NULL,
        Pincode         VARCHAR(12)     NOT NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_ShippingZonePincodes_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,

        CONSTRAINT PK_ShippingZonePincodes PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_ShippingZonePincodes UNIQUE (Pincode),
        CONSTRAINT FK_ShippingZonePincodes_Zones FOREIGN KEY (ShippingZoneId) REFERENCES dbo.ShippingZones (Id)
    );

    CREATE INDEX IX_ShippingZonePincodes_Zone ON dbo.ShippingZonePincodes (ShippingZoneId);
END
GO

/* Weight-slab rate card. Overrides the zone's BaseRate/PerKgRate when a slab
   matches, which is how "flat ₹49 up to 500g" is expressed. */
IF OBJECT_ID(N'dbo.ShippingRates', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ShippingRates
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        ShippingZoneId      INT             NOT NULL,
        CourierId           INT             NULL,
        /* Standard|Express|SameDay */
        ServiceLevel        VARCHAR(32)     NOT NULL CONSTRAINT DF_ShippingRates_ServiceLevel DEFAULT ('Standard'),
        MinWeightGrams      DECIMAL(18,4)   NOT NULL CONSTRAINT DF_ShippingRates_MinWeight DEFAULT (0),
        MaxWeightGrams      DECIMAL(18,4)   NULL,
        MinOrderValue       DECIMAL(18,2)   NULL,
        MaxOrderValue       DECIMAL(18,2)   NULL,
        Rate                DECIMAL(18,2)   NOT NULL CONSTRAINT DF_ShippingRates_Rate DEFAULT (0),
        AdditionalPerKg     DECIMAL(18,2)   NOT NULL CONSTRAINT DF_ShippingRates_AdditionalPerKg DEFAULT (0),
        DeliveryDays        INT             NULL,

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_ShippingRates_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_ShippingRates_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_ShippingRates_IsDeleted DEFAULT (0),

        CONSTRAINT PK_ShippingRates PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_ShippingRates_Zones FOREIGN KEY (ShippingZoneId) REFERENCES dbo.ShippingZones (Id),
        CONSTRAINT CK_ShippingRates_WeightBand CHECK (MaxWeightGrams IS NULL OR MaxWeightGrams > MinWeightGrams)
    );

    CREATE INDEX IX_ShippingRates_Zone ON dbo.ShippingRates (ShippingZoneId, ServiceLevel, MinWeightGrams) WHERE IsDeleted = 0;
END
GO

IF OBJECT_ID(N'dbo.Couriers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Couriers
    (
        Id                      INT             IDENTITY(1,1) NOT NULL,
        CourierName             NVARCHAR(150)   NOT NULL,
        Code                    VARCHAR(32)     NOT NULL,
        LogoUrl                 NVARCHAR(1000)  NULL,
        SupportsCod             BIT             NOT NULL CONSTRAINT DF_Couriers_SupportsCod DEFAULT (1),
        SupportsReversePickup   BIT             NOT NULL CONSTRAINT DF_Couriers_SupportsReverse DEFAULT (1),
        /* {0} is substituted with the AWB — the customer's tracking link. */
        TrackingUrlTemplate     NVARCHAR(500)   NULL,
        SupportPhone            VARCHAR(24)     NULL,
        IntegrationId           INT             NULL,
        /* Performance, maintained from delivered shipments against their promise. */
        ActiveShipmentCount     INT             NOT NULL CONSTRAINT DF_Couriers_ActiveShipmentCount DEFAULT (0),
        OnTimePercent           DECIMAL(18,4)   NOT NULL CONSTRAINT DF_Couriers_OnTimePercent DEFAULT (0),
        SortOrder               INT             NOT NULL CONSTRAINT DF_Couriers_SortOrder DEFAULT (0),

        CreatedAt               DATETIME2(3)    NOT NULL CONSTRAINT DF_Couriers_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy               INT             NULL,
        UpdatedAt               DATETIME2(3)    NULL,
        UpdatedBy               INT             NULL,
        IsActive                BIT             NOT NULL CONSTRAINT DF_Couriers_IsActive  DEFAULT (1),
        IsDeleted               BIT             NOT NULL CONSTRAINT DF_Couriers_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Couriers PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_Couriers_Code UNIQUE (Code),
        CONSTRAINT FK_Couriers_Integrations FOREIGN KEY (IntegrationId) REFERENCES dbo.Integrations (Id)
    );
END
GO

IF OBJECT_ID(N'dbo.FK_ShippingRates_Couriers', N'F') IS NULL
    ALTER TABLE dbo.ShippingRates
        ADD CONSTRAINT FK_ShippingRates_Couriers FOREIGN KEY (CourierId) REFERENCES dbo.Couriers (Id);
GO

IF OBJECT_ID(N'dbo.Shipments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Shipments
    (
        Id                  INT             IDENTITY(1,1) NOT NULL,
        AwbNumber           VARCHAR(64)     NOT NULL,
        OrderId             INT             NOT NULL,
        CourierId           INT             NULL,
        CourierName         NVARCHAR(150)   NULL,
        WarehouseId         INT             NULL,
        ManifestId          INT             NULL,

        /* ShipmentStatus: 0 NotShipped, 1 LabelGenerated, 2 PickedUp, 3 InTransit,
           4 OutForDelivery, 5 Delivered, 6 Failed, 7 Rto */
        Status              TINYINT         NOT NULL CONSTRAINT DF_Shipments_Status DEFAULT (0),
        ServiceLevel        VARCHAR(32)     NOT NULL CONSTRAINT DF_Shipments_ServiceLevel DEFAULT ('Standard'),
        IsReversePickup     BIT             NOT NULL CONSTRAINT DF_Shipments_IsReversePickup DEFAULT (0),
        ReturnRequestId     INT             NULL,

        DestinationCity     NVARCHAR(150)   NULL,
        DestinationPincode  VARCHAR(12)     NULL,
        WeightKg            DECIMAL(18,4)   NOT NULL CONSTRAINT DF_Shipments_WeightKg DEFAULT (0),
        /* Volumetric weight; couriers bill on whichever is greater. */
        VolumetricWeightKg  DECIMAL(18,4)   NULL,
        ShippingCost        DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Shipments_ShippingCost DEFAULT (0),
        CodAmount           DECIMAL(18,2)   NOT NULL CONSTRAINT DF_Shipments_CodAmount DEFAULT (0),

        LabelUrl            NVARCHAR(1000)  NULL,
        /* The promise. IsBreachingSla is PromisedBy < today and not delivered. */
        PromisedBy          DATETIME2(3)    NULL,
        PickedUpOn          DATETIME2(3)    NULL,
        DeliveredOn         DATETIME2(3)    NULL,
        FailureReason       NVARCHAR(500)   NULL,
        AttemptCount        INT             NOT NULL CONSTRAINT DF_Shipments_AttemptCount DEFAULT (0),

        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_Shipments_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy           INT             NULL,
        UpdatedAt           DATETIME2(3)    NULL,
        UpdatedBy           INT             NULL,
        IsActive            BIT             NOT NULL CONSTRAINT DF_Shipments_IsActive  DEFAULT (1),
        IsDeleted           BIT             NOT NULL CONSTRAINT DF_Shipments_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Shipments PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_Shipments_Awb UNIQUE (AwbNumber),
        CONSTRAINT FK_Shipments_Orders     FOREIGN KEY (OrderId)         REFERENCES dbo.Orders (Id),
        CONSTRAINT FK_Shipments_Couriers   FOREIGN KEY (CourierId)       REFERENCES dbo.Couriers (Id),
        CONSTRAINT FK_Shipments_Warehouses FOREIGN KEY (WarehouseId)     REFERENCES dbo.Warehouses (Id),
        CONSTRAINT FK_Shipments_Returns    FOREIGN KEY (ReturnRequestId) REFERENCES dbo.ReturnRequests (Id)
    );

    CREATE INDEX IX_Shipments_Order  ON dbo.Shipments (OrderId)              WHERE IsDeleted = 0;
    CREATE INDEX IX_Shipments_Status ON dbo.Shipments (Status, PromisedBy)   WHERE IsDeleted = 0;
END
GO

/* Which order lines are in which parcel — a split shipment has one row per line
   per parcel, so a partially delivered order tells the truth. */
IF OBJECT_ID(N'dbo.ShipmentItems', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ShipmentItems
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        ShipmentId      INT             NOT NULL,
        OrderItemId     BIGINT          NOT NULL,
        Quantity        INT             NOT NULL,

        CONSTRAINT PK_ShipmentItems PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_ShipmentItems UNIQUE (ShipmentId, OrderItemId),
        CONSTRAINT FK_ShipmentItems_Shipments  FOREIGN KEY (ShipmentId)  REFERENCES dbo.Shipments (Id),
        CONSTRAINT FK_ShipmentItems_OrderItems FOREIGN KEY (OrderItemId) REFERENCES dbo.OrderItems (Id),
        CONSTRAINT CK_ShipmentItems_Quantity CHECK (Quantity > 0)
    );
END
GO

/* The tracking timeline the customer sees on /track/{orderNumber}. Written by
   the courier webhook; ExternalEventId keeps a retried callback idempotent. */
IF OBJECT_ID(N'dbo.ShipmentTrackingEvents', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ShipmentTrackingEvents
    (
        Id                  BIGINT          IDENTITY(1,1) NOT NULL,
        ShipmentId          INT             NOT NULL,
        /* ShipmentStatus value this event moved the parcel to. */
        Status              TINYINT         NOT NULL,
        StatusText          NVARCHAR(200)   NOT NULL,
        Location            NVARCHAR(200)   NULL,
        Remarks             NVARCHAR(500)   NULL,
        OccurredAt          DATETIME2(3)    NOT NULL,
        ExternalEventId     VARCHAR(128)    NULL,
        CreatedAt           DATETIME2(3)    NOT NULL CONSTRAINT DF_ShipmentTrackingEvents_CreatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_ShipmentTrackingEvents PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_ShipmentTrackingEvents_Shipments FOREIGN KEY (ShipmentId) REFERENCES dbo.Shipments (Id)
    );

    CREATE INDEX IX_ShipmentTrackingEvents_Shipment ON dbo.ShipmentTrackingEvents (ShipmentId, OccurredAt);
    CREATE UNIQUE INDEX UX_ShipmentTrackingEvents_External ON dbo.ShipmentTrackingEvents (ShipmentId, ExternalEventId)
        WHERE ExternalEventId IS NOT NULL;
END
GO

/* A day's handover to a courier. */
IF OBJECT_ID(N'dbo.Manifests', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Manifests
    (
        Id              INT             IDENTITY(1,1) NOT NULL,
        ManifestNumber  VARCHAR(32)     NOT NULL,
        CourierId       INT             NULL,
        WarehouseId     INT             NULL,
        PickupDate      DATE            NOT NULL,
        ShipmentCount   INT             NOT NULL CONSTRAINT DF_Manifests_ShipmentCount DEFAULT (0),
        /* Draft|Handed Over|Closed */
        Status          VARCHAR(32)     NOT NULL CONSTRAINT DF_Manifests_Status DEFAULT ('Draft'),
        PdfUrl          NVARCHAR(1000)  NULL,
        HandedOverOn    DATETIME2(3)    NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_Manifests_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        UpdatedAt       DATETIME2(3)    NULL,
        UpdatedBy       INT             NULL,
        IsActive        BIT             NOT NULL CONSTRAINT DF_Manifests_IsActive  DEFAULT (1),
        IsDeleted       BIT             NOT NULL CONSTRAINT DF_Manifests_IsDeleted DEFAULT (0),

        CONSTRAINT PK_Manifests PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_Manifests_Number UNIQUE (ManifestNumber),
        CONSTRAINT FK_Manifests_Couriers   FOREIGN KEY (CourierId)   REFERENCES dbo.Couriers (Id),
        CONSTRAINT FK_Manifests_Warehouses FOREIGN KEY (WarehouseId) REFERENCES dbo.Warehouses (Id)
    );
END
GO

IF OBJECT_ID(N'dbo.FK_Shipments_Manifests', N'F') IS NULL
    ALTER TABLE dbo.Shipments
        ADD CONSTRAINT FK_Shipments_Manifests FOREIGN KEY (ManifestId) REFERENCES dbo.Manifests (Id);
GO
