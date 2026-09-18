/* =============================================================================
   usp_StockTake_Procedures.sql
   Stored procedures for Stock Take Management:
     1. dbo.usp_StockTake_GridList
     2. dbo.usp_StockTake_GetById
     3. dbo.usp_StockTake_Save
     4. dbo.usp_StockTake_Delete
     5. dbo.usp_StockTake_UpdateStatus
   ============================================================================= */

SET NOCOUNT ON;
GO

/* 1. GridList */
CREATE OR ALTER PROCEDURE dbo.usp_StockTake_GridList
    @SearchText           NVARCHAR(200)   = NULL,
    @WarehouseId          INT             = NULL,
    @Status               VARCHAR(32)     = NULL,
    @SortColumn           VARCHAR(64)     = 'StartedOn',
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

    SELECT @TotalRecords = COUNT(*) FROM dbo.StockTakes WHERE IsDeleted = 0;

    ;WITH Filtered AS
    (
        SELECT
            st.Id,
            st.StockTakeNumber,
            st.WarehouseId,
            WarehouseName = ISNULL(w.WarehouseName, '—'),
            st.StartedOn,
            st.CompletedOn,
            st.Status,
            st.SkusCounted,
            st.DiscrepancyCount,
            st.DiscrepancyValue,
            st.Note,
            st.IsActive,
            st.CreatedAt,
            CreatedBy = ISNULL(u.FullName, 'Admin')
        FROM dbo.StockTakes st
        LEFT JOIN dbo.Warehouses w ON st.WarehouseId = w.Id
        LEFT JOIN dbo.AdminUsers u ON st.CreatedBy = u.Id
        WHERE st.IsDeleted = 0
          AND (@WarehouseId IS NULL OR st.WarehouseId = @WarehouseId)
          AND (@Status IS NULL OR st.Status = @Status)
          AND (@SearchText IS NULL
               OR st.StockTakeNumber LIKE N'%' + @SearchText + N'%'
               OR w.WarehouseName LIKE N'%' + @SearchText + N'%')
    )
    SELECT @TotalFilteredRecords = COUNT(*) FROM Filtered;

    ;WITH Filtered AS
    (
        SELECT
            st.Id,
            st.StockTakeNumber,
            st.WarehouseId,
            WarehouseName = ISNULL(w.WarehouseName, '—'),
            st.StartedOn,
            st.CompletedOn,
            st.Status,
            st.SkusCounted,
            st.DiscrepancyCount,
            st.DiscrepancyValue,
            st.Note,
            st.IsActive,
            st.CreatedAt,
            CreatedBy = ISNULL(u.FullName, 'Admin')
        FROM dbo.StockTakes st
        LEFT JOIN dbo.Warehouses w ON st.WarehouseId = w.Id
        LEFT JOIN dbo.AdminUsers u ON st.CreatedBy = u.Id
        WHERE st.IsDeleted = 0
          AND (@WarehouseId IS NULL OR st.WarehouseId = @WarehouseId)
          AND (@Status IS NULL OR st.Status = @Status)
          AND (@SearchText IS NULL
               OR st.StockTakeNumber LIKE N'%' + @SearchText + N'%'
               OR w.WarehouseName LIKE N'%' + @SearchText + N'%')
    )
    SELECT *
    FROM Filtered
    ORDER BY
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'StockTakeNumber' THEN StockTakeNumber END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'StockTakeNumber' THEN StockTakeNumber END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'WarehouseName'   THEN WarehouseName END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'WarehouseName'   THEN WarehouseName END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'StartedOn'       THEN StartedOn END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'StartedOn'       THEN StartedOn END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'Status'          THEN Status END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'Status'          THEN Status END DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO

/* 2. GetById */
CREATE OR ALTER PROCEDURE dbo.usp_StockTake_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        st.Id,
        st.StockTakeNumber,
        st.WarehouseId,
        WarehouseName = ISNULL(w.WarehouseName, '—'),
        st.StartedOn,
        st.CompletedOn,
        st.Status,
        st.SkusCounted,
        st.DiscrepancyCount,
        st.DiscrepancyValue,
        st.Note,
        st.IsActive,
        st.CreatedAt,
        st.UpdatedAt,
        CreatedBy = ISNULL(u.FullName, 'Admin')
    FROM dbo.StockTakes st
    LEFT JOIN dbo.Warehouses w ON st.WarehouseId = w.Id
    LEFT JOIN dbo.AdminUsers u ON st.CreatedBy = u.Id
    WHERE st.Id = @Id AND st.IsDeleted = 0;
END
GO

/* 3. Save */
CREATE OR ALTER PROCEDURE dbo.usp_StockTake_Save
    @Id                  INT             = 0,
    @StockTakeNumber     VARCHAR(32)     = NULL,
    @WarehouseId         INT             = NULL,
    @StartedOn           DATETIME2(3)    = NULL,
    @CompletedOn         DATETIME2(3)    = NULL,
    @Status              VARCHAR(32)     = 'In Progress',
    @SkusCounted         INT             = 0,
    @DiscrepancyCount    INT             = 0,
    @DiscrepancyValue    DECIMAL(18,2)   = 0,
    @Note                NVARCHAR(1000)  = NULL,
    @IsActive            BIT             = 1,
    @LoggedInUserId      INT             = NULL,
    @NewId               INT             OUTPUT,
    @ErrorMessage        NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    IF @WarehouseId IS NULL OR @WarehouseId <= 0
    BEGIN
        SELECT TOP 1 @WarehouseId = Id FROM dbo.Warehouses WHERE IsDeleted = 0 ORDER BY IsDefault DESC, Id ASC;
    END

    IF @WarehouseId IS NULL
    BEGIN
        SET @ErrorMessage = N'A warehouse is required for the stock take.';
        RETURN;
    END

    IF @StartedOn IS NULL
        SET @StartedOn = SYSUTCDATETIME();

    IF @Id > 0
    BEGIN
        UPDATE dbo.StockTakes
        SET
            WarehouseId = ISNULL(@WarehouseId, WarehouseId),
            StartedOn = @StartedOn,
            CompletedOn = @CompletedOn,
            Status = ISNULL(@Status, Status),
            SkusCounted = @SkusCounted,
            DiscrepancyCount = @DiscrepancyCount,
            DiscrepancyValue = @DiscrepancyValue,
            Note = @Note,
            IsActive = @IsActive,
            UpdatedAt = SYSUTCDATETIME(),
            UpdatedBy = @LoggedInUserId
        WHERE Id = @Id;

        SET @NewId = @Id;
        RETURN;
    END

    -- Generate Stock Take Number if null
    IF @StockTakeNumber IS NULL OR LTRIM(RTRIM(@StockTakeNumber)) = ''
    BEGIN
        DECLARE @NextNum INT = ISNULL((SELECT MAX(Id) FROM dbo.StockTakes), 0) + 1;
        SET @StockTakeNumber = 'STK-' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) + '-' + RIGHT('0000' + CAST(@NextNum AS VARCHAR(10)), 4);
    END

    INSERT INTO dbo.StockTakes
    (
        StockTakeNumber, WarehouseId, StartedOn, CompletedOn,
        Status, SkusCounted, DiscrepancyCount, DiscrepancyValue,
        Note, IsActive, CreatedAt, CreatedBy
    )
    VALUES
    (
        @StockTakeNumber, @WarehouseId, @StartedOn, @CompletedOn,
        ISNULL(@Status, 'In Progress'), @SkusCounted, @DiscrepancyCount, @DiscrepancyValue,
        @Note, @IsActive, SYSUTCDATETIME(), @LoggedInUserId
    );

    SET @NewId = SCOPE_IDENTITY();
END
GO

/* 4. Delete */
CREATE OR ALTER PROCEDURE dbo.usp_StockTake_Delete
    @Id             INT,
    @LoggedInUserId INT           = NULL,
    @ErrorMessage   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    UPDATE dbo.StockTakes
    SET
        IsDeleted = 1,
        IsActive = 0,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @LoggedInUserId
    WHERE Id = @Id;
END
GO

/* 5. UpdateStatus */
CREATE OR ALTER PROCEDURE dbo.usp_StockTake_UpdateStatus
    @Id             INT,
    @NewStatus      VARCHAR(32),
    @LoggedInUserId INT           = NULL,
    @ErrorMessage   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    UPDATE dbo.StockTakes
    SET
        Status = @NewStatus,
        CompletedOn = CASE WHEN @NewStatus = 'Completed' THEN SYSUTCDATETIME() ELSE CompletedOn END,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @LoggedInUserId
    WHERE Id = @Id;
END
GO
