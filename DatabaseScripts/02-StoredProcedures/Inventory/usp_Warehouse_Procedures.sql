/* =============================================================================
   usp_Warehouse_Procedures.sql
   Stored procedures for Warehouse Management:
     1. dbo.usp_Warehouse_GridList
     2. dbo.usp_Warehouse_GetById
     3. dbo.usp_Warehouse_Save
     4. dbo.usp_Warehouse_Delete
     5. dbo.usp_Warehouse_UpdateStatus
     6. dbo.usp_Warehouse_Lookup
   ============================================================================= */

SET NOCOUNT ON;
GO

/* 1. GridList */
CREATE OR ALTER PROCEDURE dbo.usp_Warehouse_GridList
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

    SELECT @TotalRecords = COUNT(*) FROM dbo.Warehouses WHERE IsDeleted = 0;

    ;WITH Filtered AS
    (
        SELECT
            w.Id,
            w.WarehouseName,
            w.Code,
            w.ContactPerson,
            w.Phone,
            w.Email,
            w.CityName AS City,
            w.StateName AS State,
            w.Pincode,
            w.IsDefault,
            w.IsActive,
            w.CreatedAt,
            SkuCount = (SELECT COUNT(DISTINCT s.ProductId) FROM dbo.InventoryStocks s WHERE s.WarehouseId = w.Id AND s.IsDeleted = 0)
        FROM dbo.Warehouses w
        WHERE w.IsDeleted = 0
          AND (@IsActive IS NULL OR w.IsActive = @IsActive)
          AND (@SearchText IS NULL
               OR w.WarehouseName LIKE N'%' + @SearchText + N'%'
               OR w.Code LIKE N'%' + @SearchText + N'%'
               OR w.ContactPerson LIKE N'%' + @SearchText + N'%'
               OR w.Phone LIKE N'%' + @SearchText + N'%'
               OR w.CityName LIKE N'%' + @SearchText + N'%')
    )
    SELECT @TotalFilteredRecords = COUNT(*) FROM Filtered;

    ;WITH Filtered AS
    (
        SELECT
            w.Id,
            w.WarehouseName,
            w.Code,
            w.ContactPerson,
            w.Phone,
            w.Email,
            w.CityName AS City,
            w.StateName AS State,
            w.Pincode,
            w.IsDefault,
            w.IsActive,
            w.CreatedAt,
            SkuCount = (SELECT COUNT(DISTINCT s.ProductId) FROM dbo.InventoryStocks s WHERE s.WarehouseId = w.Id AND s.IsDeleted = 0)
        FROM dbo.Warehouses w
        WHERE w.IsDeleted = 0
          AND (@IsActive IS NULL OR w.IsActive = @IsActive)
          AND (@SearchText IS NULL
               OR w.WarehouseName LIKE N'%' + @SearchText + N'%'
               OR w.Code LIKE N'%' + @SearchText + N'%'
               OR w.ContactPerson LIKE N'%' + @SearchText + N'%'
               OR w.Phone LIKE N'%' + @SearchText + N'%'
               OR w.CityName LIKE N'%' + @SearchText + N'%')
    )
    SELECT *
    FROM Filtered
    ORDER BY
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'WarehouseName' THEN WarehouseName END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'WarehouseName' THEN WarehouseName END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'Code'          THEN Code END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'Code'          THEN Code END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'City'          THEN City END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'City'          THEN City END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'SkuCount'      THEN SkuCount END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'SkuCount'      THEN SkuCount END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'CreatedAt'     THEN CreatedAt END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'CreatedAt'     THEN CreatedAt END DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO

/* 2. GetById */
CREATE OR ALTER PROCEDURE dbo.usp_Warehouse_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        w.Id,
        w.WarehouseName,
        w.Code,
        w.Line1,
        w.Line2,
        w.CityId,
        w.StateId,
        City = w.CityName,
        State = w.StateName,
        w.Pincode,
        w.ContactPerson,
        w.Phone,
        w.Email,
        w.IsDefault,
        w.IsActive,
        w.CreatedAt,
        w.UpdatedAt,
        SkuCount = (SELECT COUNT(DISTINCT s.ProductId) FROM dbo.InventoryStocks s WHERE s.WarehouseId = w.Id AND s.IsDeleted = 0),
        TotalStock = ISNULL((SELECT SUM(s.OnHand) FROM dbo.InventoryStocks s WHERE s.WarehouseId = w.Id AND s.IsDeleted = 0), 0),
        TotalReserved = ISNULL((SELECT SUM(s.Reserved) FROM dbo.InventoryStocks s WHERE s.WarehouseId = w.Id AND s.IsDeleted = 0), 0)
    FROM dbo.Warehouses w
    WHERE w.Id = @Id AND w.IsDeleted = 0;
END
GO

/* 3. Save (Insert / Update) */
CREATE OR ALTER PROCEDURE dbo.usp_Warehouse_Save
    @Id             INT             = 0,
    @WarehouseName  NVARCHAR(200),
    @Code           VARCHAR(32),
    @Line1          NVARCHAR(300)   = NULL,
    @Line2          NVARCHAR(300)   = NULL,
    @City           NVARCHAR(150)   = NULL,
    @State          NVARCHAR(150)   = NULL,
    @Pincode        VARCHAR(12)     = NULL,
    @ContactPerson  NVARCHAR(200)   = NULL,
    @Phone          VARCHAR(24)     = NULL,
    @Email          NVARCHAR(256)   = NULL,
    @IsDefault      BIT             = 0,
    @IsActive       BIT             = 1,
    @LoggedInUserId INT             = NULL,
    @NewId          INT             OUTPUT,
    @ErrorMessage   NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    SET @WarehouseName = LTRIM(RTRIM(@WarehouseName));
    SET @Code = UPPER(LTRIM(RTRIM(@Code)));

    IF ISNULL(@WarehouseName, N'') = N''
    BEGIN
        SET @ErrorMessage = N'Warehouse Name is required.';
        RETURN;
    END

    IF ISNULL(@Code, N'') = N''
    BEGIN
        SET @ErrorMessage = N'Warehouse Code is required.';
        RETURN;
    END

    -- Unique Code check
    IF EXISTS (SELECT 1 FROM dbo.Warehouses WHERE Code = @Code AND Id <> @Id AND IsDeleted = 0)
    BEGIN
        SET @ErrorMessage = N'Warehouse code already exists: ' + @Code;
        RETURN;
    END

    -- If marking as default, unset other defaults
    IF @IsDefault = 1
    BEGIN
        UPDATE dbo.Warehouses SET IsDefault = 0 WHERE IsDefault = 1 AND Id <> @Id;
    END
    ELSE
    BEGIN
        -- If currently default and trying to uncheck, ensure at least one default exists
        IF @Id > 0 AND EXISTS (SELECT 1 FROM dbo.Warehouses WHERE Id = @Id AND IsDefault = 1)
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.Warehouses WHERE Id <> @Id AND IsDefault = 1 AND IsDeleted = 0)
            BEGIN
                SET @IsDefault = 1; -- Keep as default
            END
        END
    END

    IF @Id = 0
    BEGIN
        INSERT INTO dbo.Warehouses
        (
            WarehouseName, Code, Line1, Line2, CityName, StateName, Pincode,
            ContactPerson, Phone, Email, IsDefault, IsActive, CreatedAt, CreatedBy
        )
        VALUES
        (
            @WarehouseName, @Code, @Line1, @Line2, @City, @State, @Pincode,
            @ContactPerson, @Phone, @Email, @IsDefault, @IsActive, SYSUTCDATETIME(), @LoggedInUserId
        );

        SET @NewId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.Warehouses
        SET
            WarehouseName = @WarehouseName,
            Code = @Code,
            Line1 = @Line1,
            Line2 = @Line2,
            CityName = @City,
            StateName = @State,
            Pincode = @Pincode,
            ContactPerson = @ContactPerson,
            Phone = @Phone,
            Email = @Email,
            IsDefault = @IsDefault,
            IsActive = @IsActive,
            UpdatedAt = SYSUTCDATETIME(),
            UpdatedBy = @LoggedInUserId
        WHERE Id = @Id AND IsDeleted = 0;

        SET @NewId = @Id;
    END
END
GO

/* 4. Delete */
CREATE OR ALTER PROCEDURE dbo.usp_Warehouse_Delete
    @Id             INT,
    @LoggedInUserId INT           = NULL,
    @ErrorMessage   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    IF EXISTS (SELECT 1 FROM dbo.Warehouses WHERE Id = @Id AND IsDefault = 1)
    BEGIN
        SET @ErrorMessage = N'Cannot delete the primary default warehouse.';
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM dbo.InventoryStocks WHERE WarehouseId = @Id AND OnHand > 0 AND IsDeleted = 0)
    BEGIN
        SET @ErrorMessage = N'Cannot delete warehouse with active on-hand stock. Transfer or adjust stock first.';
        RETURN;
    END

    UPDATE dbo.Warehouses
    SET
        IsDeleted = 1,
        IsActive = 0,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @LoggedInUserId
    WHERE Id = @Id;
END
GO

/* 5. UpdateStatus */
CREATE OR ALTER PROCEDURE dbo.usp_Warehouse_UpdateStatus
    @Id             INT,
    @IsActive       BIT,
    @LoggedInUserId INT           = NULL,
    @ErrorMessage   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    IF @IsActive = 0 AND EXISTS (SELECT 1 FROM dbo.Warehouses WHERE Id = @Id AND IsDefault = 1)
    BEGIN
        SET @ErrorMessage = N'Cannot deactivate the primary default warehouse.';
        RETURN;
    END

    UPDATE dbo.Warehouses
    SET
        IsActive = @IsActive,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @LoggedInUserId
    WHERE Id = @Id AND IsDeleted = 0;
END
GO

/* 6. Lookup */
CREATE OR ALTER PROCEDURE dbo.usp_Warehouse_Lookup
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id,
        WarehouseName AS Name,
        Code,
        IsDefault
    FROM dbo.Warehouses
    WHERE IsActive = 1 AND IsDeleted = 0
    ORDER BY IsDefault DESC, WarehouseName ASC;
END
GO
