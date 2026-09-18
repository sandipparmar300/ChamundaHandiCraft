/* =============================================================================
   usp_Supplier_Procedures.sql
   Stored procedures for Supplier Management:
     1. dbo.usp_Supplier_GridList
     2. dbo.usp_Supplier_GetById
     3. dbo.usp_Supplier_Save
     4. dbo.usp_Supplier_Delete
     5. dbo.usp_Supplier_UpdateStatus
     6. dbo.usp_Supplier_Lookup
   ============================================================================= */

SET NOCOUNT ON;
GO

/* 1. GridList */
CREATE OR ALTER PROCEDURE dbo.usp_Supplier_GridList
    @SearchText           NVARCHAR(200)   = NULL,
    @IsActive             BIT             = NULL,
    @SortColumn           VARCHAR(64)     = 'CreatedAt',
    @SortOrder            VARCHAR(4)      = 'DESC',
    @PageSize             INT             = 25,
    @PageIndex            INT             = 1,
    @TotalRecords         INT             OUTPUT,
    @TotalFilteredRecords INT             OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @PageSize  IS NULL OR @PageSize  < 1 SET @PageSize  = 25;
    IF @PageIndex IS NULL OR @PageIndex < 1 SET @PageIndex = 1;
    IF @SortOrder IS NULL OR @SortOrder NOT IN ('ASC','DESC') SET @SortOrder = 'DESC';
    SET @SearchText = NULLIF(LTRIM(RTRIM(ISNULL(@SearchText, N''))), N'');

    SELECT @TotalRecords = COUNT(*) FROM dbo.Suppliers WHERE IsDeleted = 0;

    ;WITH Filtered AS
    (
        SELECT
            s.Id,
            s.SupplierName,
            s.Code,
            s.ContactPerson,
            s.Phone,
            s.Email,
            s.Gstin,
            s.CityName AS City,
            s.StateName AS State,
            s.PaymentTermsDays,
            s.OutstandingAmount,
            s.IsActive,
            s.CreatedAt,
            PurchaseOrderCount = (SELECT COUNT(*) FROM dbo.PurchaseOrders po WHERE po.SupplierId = s.Id AND po.IsDeleted = 0)
        FROM dbo.Suppliers s
        WHERE s.IsDeleted = 0
          AND (@IsActive IS NULL OR s.IsActive = @IsActive)
          AND (@SearchText IS NULL
               OR s.SupplierName LIKE N'%' + @SearchText + N'%'
               OR s.Code LIKE N'%' + @SearchText + N'%'
               OR s.ContactPerson LIKE N'%' + @SearchText + N'%'
               OR s.Phone LIKE N'%' + @SearchText + N'%'
               OR s.Email LIKE N'%' + @SearchText + N'%'
               OR s.Gstin LIKE N'%' + @SearchText + N'%'
               OR s.CityName LIKE N'%' + @SearchText + N'%')
    )
    SELECT @TotalFilteredRecords = COUNT(*) FROM Filtered;

    ;WITH Filtered AS
    (
        SELECT
            s.Id,
            s.SupplierName,
            s.Code,
            s.ContactPerson,
            s.Phone,
            s.Email,
            s.Gstin,
            s.CityName AS City,
            s.StateName AS State,
            s.PaymentTermsDays,
            s.OutstandingAmount,
            s.IsActive,
            s.CreatedAt,
            PurchaseOrderCount = (SELECT COUNT(*) FROM dbo.PurchaseOrders po WHERE po.SupplierId = s.Id AND po.IsDeleted = 0)
        FROM dbo.Suppliers s
        WHERE s.IsDeleted = 0
          AND (@IsActive IS NULL OR s.IsActive = @IsActive)
          AND (@SearchText IS NULL
               OR s.SupplierName LIKE N'%' + @SearchText + N'%'
               OR s.Code LIKE N'%' + @SearchText + N'%'
               OR s.ContactPerson LIKE N'%' + @SearchText + N'%'
               OR s.Phone LIKE N'%' + @SearchText + N'%'
               OR s.Email LIKE N'%' + @SearchText + N'%'
               OR s.Gstin LIKE N'%' + @SearchText + N'%'
               OR s.CityName LIKE N'%' + @SearchText + N'%')
    )
    SELECT *
    FROM Filtered
    ORDER BY
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'SupplierName'      THEN SupplierName END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'SupplierName'      THEN SupplierName END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'Code'              THEN Code END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'Code'              THEN Code END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'ContactPerson'     THEN ContactPerson END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'ContactPerson'     THEN ContactPerson END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'City'              THEN City END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'City'              THEN City END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'OutstandingAmount' THEN OutstandingAmount END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'OutstandingAmount' THEN OutstandingAmount END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'CreatedAt'         THEN CreatedAt END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'CreatedAt'         THEN CreatedAt END DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO

/* 2. GetById */
CREATE OR ALTER PROCEDURE dbo.usp_Supplier_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        s.Id,
        s.SupplierName,
        s.Code,
        s.ContactPerson,
        s.Phone,
        s.Email,
        s.Gstin,
        s.Line1,
        City = s.CityName,
        State = s.StateName,
        s.Pincode,
        s.PaymentTermsDays,
        s.OutstandingAmount,
        s.IsActive,
        s.CreatedAt,
        s.UpdatedAt,
        PurchaseOrderCount = (SELECT COUNT(*) FROM dbo.PurchaseOrders po WHERE po.SupplierId = s.Id AND po.IsDeleted = 0),
        TotalPurchased = ISNULL((SELECT SUM(po.TotalValue) FROM dbo.PurchaseOrders po WHERE po.SupplierId = s.Id AND po.IsDeleted = 0), 0)
    FROM dbo.Suppliers s
    WHERE s.Id = @Id AND s.IsDeleted = 0;
END
GO

/* 3. Save (Insert / Update) */
CREATE OR ALTER PROCEDURE dbo.usp_Supplier_Save
    @Id                INT             = 0,
    @SupplierName      NVARCHAR(200),
    @Code              VARCHAR(32),
    @ContactPerson     NVARCHAR(200)   = NULL,
    @Phone             VARCHAR(24)     = NULL,
    @Email             NVARCHAR(256)   = NULL,
    @Gstin             VARCHAR(20)     = NULL,
    @Line1             NVARCHAR(300)   = NULL,
    @City              NVARCHAR(150)   = NULL,
    @State             NVARCHAR(150)   = NULL,
    @Pincode           VARCHAR(12)     = NULL,
    @PaymentTermsDays  INT             = 30,
    @IsActive          BIT             = 1,
    @LoggedInUserId    INT             = NULL,
    @NewId             INT             OUTPUT,
    @ErrorMessage      NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    SET @SupplierName = LTRIM(RTRIM(@SupplierName));
    SET @Code = UPPER(LTRIM(RTRIM(@Code)));

    IF ISNULL(@SupplierName, N'') = N''
    BEGIN
        SET @ErrorMessage = N'Supplier Name is required.';
        RETURN;
    END

    IF ISNULL(@Code, N'') = N''
    BEGIN
        SET @ErrorMessage = N'Supplier Code is required.';
        RETURN;
    END

    -- Unique Code check
    IF EXISTS (SELECT 1 FROM dbo.Suppliers WHERE Code = @Code AND Id <> @Id AND IsDeleted = 0)
    BEGIN
        SET @ErrorMessage = N'Supplier code already exists: ' + @Code;
        RETURN;
    END

    IF @Id = 0
    BEGIN
        INSERT INTO dbo.Suppliers
        (
            SupplierName, Code, ContactPerson, Phone, Email, Gstin, Line1,
            CityName, StateName, Pincode, PaymentTermsDays, OutstandingAmount,
            IsActive, CreatedAt, CreatedBy
        )
        VALUES
        (
            @SupplierName, @Code, @ContactPerson, @Phone, @Email, @Gstin, @Line1,
            @City, @State, @Pincode, ISNULL(@PaymentTermsDays, 30), 0,
            @IsActive, SYSUTCDATETIME(), @LoggedInUserId
        );

        SET @NewId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.Suppliers
        SET
            SupplierName = @SupplierName,
            Code = @Code,
            ContactPerson = @ContactPerson,
            Phone = @Phone,
            Email = @Email,
            Gstin = @Gstin,
            Line1 = @Line1,
            CityName = @City,
            StateName = @State,
            Pincode = @Pincode,
            PaymentTermsDays = ISNULL(@PaymentTermsDays, 30),
            IsActive = @IsActive,
            UpdatedAt = SYSUTCDATETIME(),
            UpdatedBy = @LoggedInUserId
        WHERE Id = @Id AND IsDeleted = 0;

        SET @NewId = @Id;
    END
END
GO

/* 4. Delete */
CREATE OR ALTER PROCEDURE dbo.usp_Supplier_Delete
    @Id             INT,
    @LoggedInUserId INT           = NULL,
    @ErrorMessage   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    IF EXISTS (SELECT 1 FROM dbo.PurchaseOrders WHERE SupplierId = @Id AND Status IN ('Draft','Sent','PartiallyReceived') AND IsDeleted = 0)
    BEGIN
        SET @ErrorMessage = N'Cannot delete supplier with active open purchase orders.';
        RETURN;
    END

    UPDATE dbo.Suppliers
    SET
        IsDeleted = 1,
        IsActive = 0,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @LoggedInUserId
    WHERE Id = @Id;
END
GO

/* 5. UpdateStatus */
CREATE OR ALTER PROCEDURE dbo.usp_Supplier_UpdateStatus
    @Id             INT,
    @IsActive       BIT,
    @LoggedInUserId INT           = NULL,
    @ErrorMessage   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    UPDATE dbo.Suppliers
    SET
        IsActive = @IsActive,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @LoggedInUserId
    WHERE Id = @Id AND IsDeleted = 0;
END
GO

/* 6. Lookup */
CREATE OR ALTER PROCEDURE dbo.usp_Supplier_Lookup
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id,
        SupplierName AS Name,
        Code
    FROM dbo.Suppliers
    WHERE IsActive = 1 AND IsDeleted = 0
    ORDER BY SupplierName ASC;
END
GO
