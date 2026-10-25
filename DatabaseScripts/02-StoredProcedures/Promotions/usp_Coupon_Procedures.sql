/* =============================================================================
   usp_Coupon_Procedures.sql
   Stored procedures for Coupons:
     1. dbo.usp_Coupon_GridList
     2. dbo.usp_Coupon_GetById
     3. dbo.usp_Coupon_Save
     4. dbo.usp_Coupon_Delete
     5. dbo.usp_Coupon_UpdateStatus
   ============================================================================= */

SET NOCOUNT ON;
GO

/* 1. GridList */
CREATE OR ALTER PROCEDURE dbo.usp_Coupon_GridList
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

    SELECT @TotalRecords = COUNT(*) FROM dbo.Coupons WHERE IsDeleted = 0;

    ;WITH Filtered AS
    (
        SELECT
            c.Id,
            c.Code,
            c.Title,
            c.Description,
            c.DiscountType,
            c.DiscountValue,
            c.MaxDiscount,
            c.MinimumOrderValue,
            c.StartsOn,
            c.ExpiresOn,
            c.UsageCount,
            c.TotalUsageLimit,
            c.TotalDiscountGiven,
            c.Status,
            c.IsPublic,
            c.CreatedAt,
            c.UpdatedAt,
            c.IsActive
        FROM dbo.Coupons c
        WHERE c.IsDeleted = 0
          AND (@IsActive IS NULL OR c.IsActive = @IsActive)
          AND (@SearchText IS NULL
               OR c.Code LIKE '%' + @SearchText + '%'
               OR c.Title LIKE N'%' + @SearchText + N'%'
               OR c.Description LIKE N'%' + @SearchText + N'%')
    )
    SELECT @TotalFilteredRecords = COUNT(*) FROM Filtered;

    ;WITH Filtered AS
    (
        SELECT
            c.Id,
            c.Code,
            c.Title,
            c.Description,
            c.DiscountType,
            c.DiscountValue,
            c.MaxDiscount,
            c.MinimumOrderValue,
            c.StartsOn,
            c.ExpiresOn,
            c.UsageCount,
            c.TotalUsageLimit,
            c.TotalDiscountGiven,
            c.Status,
            c.IsPublic,
            c.CreatedAt,
            c.UpdatedAt,
            c.IsActive
        FROM dbo.Coupons c
        WHERE c.IsDeleted = 0
          AND (@IsActive IS NULL OR c.IsActive = @IsActive)
          AND (@SearchText IS NULL
               OR c.Code LIKE '%' + @SearchText + '%'
               OR c.Title LIKE N'%' + @SearchText + N'%'
               OR c.Description LIKE N'%' + @SearchText + N'%')
    )
    SELECT *
    FROM Filtered
    ORDER BY
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'Code'          THEN Code END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'Code'          THEN Code END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'Title'         THEN Title END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'Title'         THEN Title END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'DiscountValue' THEN DiscountValue END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'DiscountValue' THEN DiscountValue END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'StartsOn'      THEN StartsOn END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'StartsOn'      THEN StartsOn END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'ExpiresOn'     THEN ExpiresOn END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'ExpiresOn'     THEN ExpiresOn END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'CreatedAt'     THEN CreatedAt END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'CreatedAt'     THEN CreatedAt END DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO

/* 2. GetById */
CREATE OR ALTER PROCEDURE dbo.usp_Coupon_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.Id,
        c.Code,
        c.Title,
        c.Description,
        c.DiscountType,
        c.DiscountValue,
        c.MaxDiscount,
        c.MinimumOrderValue,
        c.BuyQuantity,
        c.GetQuantity,
        c.StartsOn,
        c.ExpiresOn,
        c.TotalUsageLimit,
        c.PerCustomerLimit,
        c.UsageCount,
        c.TotalDiscountGiven,
        c.IsPublic,
        c.FirstOrderOnly,
        c.IsStackable,
        c.Status,
        c.CreatedAt,
        c.UpdatedAt,
        c.IsActive
    FROM dbo.Coupons c
    WHERE c.Id = @Id AND c.IsDeleted = 0;
END
GO

/* 3. Save (Insert / Update) */
CREATE OR ALTER PROCEDURE dbo.usp_Coupon_Save
    @Id                INT             = 0,
    @Code              VARCHAR(50),
    @Title             NVARCHAR(200),
    @Description       NVARCHAR(1000)  = NULL,
    @DiscountType      TINYINT         = 0,
    @DiscountValue     DECIMAL(18,2)   = 0,
    @MaxDiscount       DECIMAL(18,2)   = NULL,
    @MinimumOrderValue DECIMAL(18,2)   = NULL,
    @StartsOn          DATETIME2       = NULL,
    @ExpiresOn         DATETIME2       = NULL,
    @TotalUsageLimit   INT             = NULL,
    @PerCustomerLimit  INT             = 1,
    @IsPublic          BIT             = 1,
    @Status            TINYINT         = 1,
    @IsActive          BIT             = 1,
    @LoggedInUserId    INT             = NULL,
    @NewId             INT             OUTPUT,
    @ErrorMessage      NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    SET @Code = UPPER(LTRIM(RTRIM(ISNULL(@Code, ''))));
    SET @Title = LTRIM(RTRIM(ISNULL(@Title, N'')));

    IF @Code = ''
    BEGIN
        SET @ErrorMessage = N'Coupon Code is required.';
        RETURN;
    END

    IF @Title = N''
    BEGIN
        SET @Title = @Code;
    END

    -- Unique Code check
    IF EXISTS (SELECT 1 FROM dbo.Coupons WHERE Code = @Code AND Id <> @Id AND IsDeleted = 0)
    BEGIN
        SET @ErrorMessage = N'Coupon code already exists: ' + @Code;
        RETURN;
    END

    IF @StartsOn IS NULL
        SET @StartsOn = SYSUTCDATETIME();

    IF @Id = 0
    BEGIN
        INSERT INTO dbo.Coupons
        (
            Code, Title, Description, DiscountType, DiscountValue,
            MaxDiscount, MinimumOrderValue, StartsOn, ExpiresOn,
            TotalUsageLimit, PerCustomerLimit, UsageCount, TotalDiscountGiven,
            IsPublic, FirstOrderOnly, IsStackable, Status,
            CreatedAt, CreatedBy, IsActive, IsDeleted
        )
        VALUES
        (
            @Code, @Title, @Description, @DiscountType, @DiscountValue,
            @MaxDiscount, @MinimumOrderValue, @StartsOn, @ExpiresOn,
            @TotalUsageLimit, @PerCustomerLimit, 0, 0,
            @IsPublic, 0, 0, @Status,
            SYSUTCDATETIME(), @LoggedInUserId, @IsActive, 0
        );

        SET @NewId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.Coupons
        SET
            Code = @Code,
            Title = @Title,
            Description = @Description,
            DiscountType = @DiscountType,
            DiscountValue = @DiscountValue,
            MaxDiscount = @MaxDiscount,
            MinimumOrderValue = @MinimumOrderValue,
            StartsOn = @StartsOn,
            ExpiresOn = @ExpiresOn,
            TotalUsageLimit = @TotalUsageLimit,
            PerCustomerLimit = @PerCustomerLimit,
            IsPublic = @IsPublic,
            Status = @Status,
            IsActive = @IsActive,
            UpdatedAt = SYSUTCDATETIME(),
            UpdatedBy = @LoggedInUserId
        WHERE Id = @Id AND IsDeleted = 0;

        SET @NewId = @Id;
    END
END
GO

/* 4. Delete */
CREATE OR ALTER PROCEDURE dbo.usp_Coupon_Delete
    @Id             INT,
    @LoggedInUserId INT           = NULL,
    @Success        BIT           OUTPUT,
    @ErrorMessage   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Success = 0;
    SET @ErrorMessage = NULL;

    IF NOT EXISTS (SELECT 1 FROM dbo.Coupons WHERE Id = @Id AND IsDeleted = 0)
    BEGIN
        SET @ErrorMessage = N'Coupon not found.';
        RETURN;
    END

    UPDATE dbo.Coupons
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
CREATE OR ALTER PROCEDURE dbo.usp_Coupon_UpdateStatus
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

    IF NOT EXISTS (SELECT 1 FROM dbo.Coupons WHERE Id = @Id AND IsDeleted = 0)
    BEGIN
        SET @ErrorMessage = N'Coupon not found.';
        RETURN;
    END

    UPDATE dbo.Coupons
    SET
        IsActive = @IsActive,
        Status = CASE WHEN @IsActive = 1 THEN 1 ELSE 2 END, -- 1 = Active, 2 = Paused
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @LoggedInUserId
    WHERE Id = @Id AND IsDeleted = 0;

    SET @Success = 1;
END
GO
