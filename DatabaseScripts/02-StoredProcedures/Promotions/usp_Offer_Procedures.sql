/* =============================================================================
   usp_Offer_Procedures.sql
   Stored procedures for Offers / Flash Sales:
     1. dbo.usp_Offer_GridList
     2. dbo.usp_Offer_GetById
     3. dbo.usp_Offer_Save
     4. dbo.usp_Offer_Delete
     5. dbo.usp_Offer_UpdateStatus
   ============================================================================= */

SET NOCOUNT ON;
GO

/* 1. GridList */
CREATE OR ALTER PROCEDURE dbo.usp_Offer_GridList
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

    SELECT @TotalRecords = COUNT(*) FROM dbo.Offers WHERE IsDeleted = 0;

    ;WITH Filtered AS
    (
        SELECT
            o.Id,
            o.Name,
            o.OfferType,
            o.DiscountPercent,
            o.StartsOn,
            o.EndsOn,
            ProductCount = 0,
            o.OrdersInfluenced,
            o.RevenueInfluenced,
            o.CreatedAt,
            o.UpdatedAt,
            o.IsActive
        FROM dbo.Offers o
        WHERE o.IsDeleted = 0
          AND (@IsActive IS NULL OR o.IsActive = @IsActive)
          AND (@SearchText IS NULL
               OR o.Name LIKE N'%' + @SearchText + N'%'
               OR o.OfferType LIKE '%' + @SearchText + '%')
    )
    SELECT @TotalFilteredRecords = COUNT(*) FROM Filtered;

    ;WITH Filtered AS
    (
        SELECT
            o.Id,
            o.Name,
            o.OfferType,
            o.DiscountPercent,
            o.StartsOn,
            o.EndsOn,
            ProductCount = 0,
            o.OrdersInfluenced,
            o.RevenueInfluenced,
            o.CreatedAt,
            o.UpdatedAt,
            o.IsActive
        FROM dbo.Offers o
        WHERE o.IsDeleted = 0
          AND (@IsActive IS NULL OR o.IsActive = @IsActive)
          AND (@SearchText IS NULL
               OR o.Name LIKE N'%' + @SearchText + N'%'
               OR o.OfferType LIKE '%' + @SearchText + '%')
    )
    SELECT *
    FROM Filtered
    ORDER BY
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'Name'            THEN Name END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'Name'            THEN Name END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'DiscountPercent' THEN DiscountPercent END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'DiscountPercent' THEN DiscountPercent END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'StartsOn'        THEN StartsOn END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'StartsOn'        THEN StartsOn END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'EndsOn'          THEN EndsOn END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'EndsOn'          THEN EndsOn END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'CreatedAt'       THEN CreatedAt END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'CreatedAt'       THEN CreatedAt END DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO

/* 2. GetById */
CREATE OR ALTER PROCEDURE dbo.usp_Offer_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        o.Id,
        o.Name,
        OfferName = o.Name,
        o.OfferType,
        o.Description,
        o.DiscountType,
        o.DiscountPercent,
        DiscountValue = CAST(o.DiscountPercent AS DECIMAL(18,2)),
        o.DiscountAmount,
        o.ComboPrice,
        o.StartsOn,
        ValidFrom = o.StartsOn,
        o.EndsOn,
        ValidTo = o.EndsOn,
        o.BannerMediaId,
        Priority = o.SortOrder,
        o.SortOrder,
        o.OrdersInfluenced,
        o.RevenueInfluenced,
        o.CreatedAt,
        o.UpdatedAt,
        o.IsActive
    FROM dbo.Offers o
    WHERE o.Id = @Id AND o.IsDeleted = 0;
END
GO

/* 3. Save (Insert / Update) */
CREATE OR ALTER PROCEDURE dbo.usp_Offer_Save
    @Id              INT             = 0,
    @Name            NVARCHAR(200),
    @OfferType       VARCHAR(50)     = 'Flash Sale',
    @Description     NVARCHAR(1000)  = NULL,
    @DiscountPercent INT             = 0,
    @StartsOn        DATETIME2       = NULL,
    @EndsOn          DATETIME2       = NULL,
    @SortOrder       INT             = 0,
    @IsActive        BIT             = 1,
    @LoggedInUserId  INT             = NULL,
    @NewId           INT             OUTPUT,
    @ErrorMessage    NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    SET @Name = LTRIM(RTRIM(ISNULL(@Name, N'')));
    IF @Name = N''
    BEGIN
        SET @ErrorMessage = N'Offer Name is required.';
        RETURN;
    END

    IF @StartsOn IS NULL
        SET @StartsOn = SYSUTCDATETIME();

    IF @EndsOn IS NULL
        SET @EndsOn = DATEADD(DAY, 7, @StartsOn);

    IF @Id = 0
    BEGIN
        INSERT INTO dbo.Offers
        (
            Name, OfferType, Description, DiscountType, DiscountPercent,
            StartsOn, EndsOn, SortOrder, OrdersInfluenced, RevenueInfluenced,
            CreatedAt, CreatedBy, IsActive, IsDeleted
        )
        VALUES
        (
            @Name, ISNULL(NULLIF(@OfferType, ''), 'Flash Sale'), @Description, 0, @DiscountPercent,
            @StartsOn, @EndsOn, @SortOrder, 0, 0,
            SYSUTCDATETIME(), @LoggedInUserId, @IsActive, 0
        );

        SET @NewId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.Offers
        SET
            Name = @Name,
            OfferType = ISNULL(NULLIF(@OfferType, ''), OfferType),
            Description = @Description,
            DiscountPercent = @DiscountPercent,
            StartsOn = @StartsOn,
            EndsOn = @EndsOn,
            SortOrder = @SortOrder,
            IsActive = @IsActive,
            UpdatedAt = SYSUTCDATETIME(),
            UpdatedBy = @LoggedInUserId
        WHERE Id = @Id AND IsDeleted = 0;

        SET @NewId = @Id;
    END
END
GO

/* 4. Delete */
CREATE OR ALTER PROCEDURE dbo.usp_Offer_Delete
    @Id             INT,
    @LoggedInUserId INT           = NULL,
    @Success        BIT           OUTPUT,
    @ErrorMessage   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Success = 0;
    SET @ErrorMessage = NULL;

    IF NOT EXISTS (SELECT 1 FROM dbo.Offers WHERE Id = @Id AND IsDeleted = 0)
    BEGIN
        SET @ErrorMessage = N'Offer not found.';
        RETURN;
    END

    UPDATE dbo.Offers
    SET
        IsDeleted = 1,
        IsActive = 0,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @LoggedInUserId
    WHERE Id = @Id;

    SET @Success = 1;
END
GO

/* 5. UpdateStatus */
CREATE OR ALTER PROCEDURE dbo.usp_Offer_UpdateStatus
    @Id             INT,
    @IsActive       BIT,
    @LoggedInUserId INT           = NULL,
    @Success        BIT           OUTPUT,
    @ErrorMessage   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Success = 0;
    SET @ErrorMessage = NULL;

    IF NOT EXISTS (SELECT 1 FROM dbo.Offers WHERE Id = @Id AND IsDeleted = 0)
    BEGIN
        SET @ErrorMessage = N'Offer not found.';
        RETURN;
    END

    UPDATE dbo.Offers
    SET
        IsActive = @IsActive,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @LoggedInUserId
    WHERE Id = @Id AND IsDeleted = 0;

    SET @Success = 1;
END
GO
