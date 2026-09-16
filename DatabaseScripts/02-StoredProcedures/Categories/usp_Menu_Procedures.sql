/* =============================================================================
   usp_Menu_Procedures.sql — Storefront Menu Management Stored Procedures
   ============================================================================= */

SET NOCOUNT ON;
GO

-- 1. Menu Grid List (Search, Location Filter, Sort, Pagination)
CREATE OR ALTER PROCEDURE dbo.usp_Menu_GridList
    @SearchText            NVARCHAR(200) = NULL,
    @Location              VARCHAR(32)   = NULL,
    @ParentId              INT           = NULL,
    @Status                INT           = NULL,
    @SortColumn            VARCHAR(50)   = 'SortOrder',
    @SortOrder             VARCHAR(4)    = 'ASC',
    @PageSize              INT           = 25,
    @PageIndex             INT           = 1,
    @TotalRecords          INT OUTPUT,
    @TotalFilteredRecords  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @SearchText = NULLIF(LTRIM(RTRIM(@SearchText)), '');
    SET @Location = NULLIF(LTRIM(RTRIM(@Location)), '');
    SET @PageSize = CASE WHEN @PageSize <= 0 THEN 25 ELSE @PageSize END;
    SET @PageIndex = CASE WHEN @PageIndex <= 0 THEN 1 ELSE @PageIndex END;

    SELECT @TotalRecords = COUNT(1)
    FROM dbo.Menus
    WHERE IsDeleted = 0;

    ;WITH Filtered AS
    (
        SELECT  m.Id,
                m.ParentId,
                ParentTitle         = p.Title,
                m.Title,
                m.Location,
                m.Url,
                m.LinkType,
                m.LinkEntityId,
                m.IconName,
                m.Badge,
                m.SortOrder,
                m.OpensInNewTab,
                m.IsActive,
                CreatedOn           = m.CreatedAt,
                m.UpdatedAt,
                ChildCount          = (SELECT COUNT(1) FROM dbo.Menus ch WHERE ch.ParentId = m.Id AND ch.IsDeleted = 0)
        FROM    dbo.Menus m
        LEFT JOIN dbo.Menus p ON p.Id = m.ParentId AND p.IsDeleted = 0
        WHERE   m.IsDeleted = 0
          AND  (@Location IS NULL OR @Location = 'All' OR m.Location = @Location)
          AND  (@ParentId IS NULL OR m.ParentId = @ParentId)
          AND  (@Status IS NULL OR @Status = -1 OR m.IsActive = @Status)
          AND  (@SearchText IS NULL OR (
                m.Title LIKE '%' + @SearchText + '%' OR
                ISNULL(m.Url, '') LIKE '%' + @SearchText + '%' OR
                ISNULL(m.Location, '') LIKE '%' + @SearchText + '%' OR
                ISNULL(p.Title, '') LIKE '%' + @SearchText + '%'
          ))
    )
    SELECT @TotalFilteredRecords = COUNT(1) FROM Filtered;

    ;WITH Filtered AS
    (
        SELECT  m.Id,
                m.ParentId,
                ParentTitle         = p.Title,
                m.Title,
                m.Location,
                m.Url,
                m.LinkType,
                m.LinkEntityId,
                m.IconName,
                m.Badge,
                m.Description,
                m.SortOrder,
                m.OpensInNewTab,
                m.IsActive,
                CreatedOn           = m.CreatedAt,
                m.UpdatedAt,
                ChildCount          = (SELECT COUNT(1) FROM dbo.Menus ch WHERE ch.ParentId = m.Id AND ch.IsDeleted = 0)
        FROM    dbo.Menus m
        LEFT JOIN dbo.Menus p ON p.Id = m.ParentId AND p.IsDeleted = 0
        WHERE   m.IsDeleted = 0
          AND  (@Location IS NULL OR @Location = 'All' OR m.Location = @Location)
          AND  (@ParentId IS NULL OR m.ParentId = @ParentId)
          AND  (@Status IS NULL OR @Status = -1 OR m.IsActive = @Status)
          AND  (@SearchText IS NULL OR (
                m.Title LIKE '%' + @SearchText + '%' OR
                ISNULL(m.Url, '') LIKE '%' + @SearchText + '%' OR
                ISNULL(m.Location, '') LIKE '%' + @SearchText + '%' OR
                ISNULL(p.Title, '') LIKE '%' + @SearchText + '%'
          ))
    )
    SELECT *
    FROM Filtered
    ORDER BY
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'SortOrder' THEN SortOrder END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'SortOrder' THEN SortOrder END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'Title'     THEN Title END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'Title'     THEN Title END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'Location'  THEN Location END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'Location'  THEN Location END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'CreatedOn' THEN CreatedOn END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'CreatedOn' THEN CreatedOn END DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO

-- 2. Menu GetById
CREATE OR ALTER PROCEDURE dbo.usp_Menu_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  m.Id,
            m.ParentId,
            ParentTitle         = p.Title,
            m.Title,
            m.Location,
            m.Url,
            m.LinkType,
            m.LinkEntityId,
            m.IconName,
            m.Badge,
            m.Description,
            m.SortOrder,
            m.OpensInNewTab,
            m.IsActive,
            CreatedOn           = m.CreatedAt,
            m.UpdatedAt,
            ChildCount          = (SELECT COUNT(1) FROM dbo.Menus ch WHERE ch.ParentId = m.Id AND ch.IsDeleted = 0)
    FROM    dbo.Menus m
    LEFT JOIN dbo.Menus p ON p.Id = m.ParentId AND p.IsDeleted = 0
    WHERE   m.Id = @Id AND m.IsDeleted = 0;
END
GO

-- 3. Menu Save (Insert / Update)
CREATE OR ALTER PROCEDURE dbo.usp_Menu_Save
    @Id             INT             = 0,
    @ParentId       INT             = NULL,
    @Title          NVARCHAR(200),
    @Location       VARCHAR(32)     = 'Header',
    @Url            NVARCHAR(500)   = NULL,
    @LinkType       VARCHAR(32)     = NULL,
    @LinkEntityId   INT             = NULL,
    @IconName       VARCHAR(64)     = NULL,
    @Badge          NVARCHAR(50)    = NULL,
    @Description    NVARCHAR(500)   = NULL,
    @SortOrder      INT             = 0,
    @OpensInNewTab  BIT             = 0,
    @IsActive       BIT             = 1,
    @AdminUserId    INT             = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @ParentId <= 0 SET @ParentId = NULL;
    IF @Id > 0 AND @ParentId = @Id SET @ParentId = NULL;
    IF @Location IS NULL OR LTRIM(RTRIM(@Location)) = '' SET @Location = 'Header';

    BEGIN TRANSACTION;

    IF @Id > 0
    BEGIN
        UPDATE dbo.Menus
        SET    ParentId      = @ParentId,
               Title         = @Title,
               Location      = @Location,
               Url           = @Url,
               LinkType      = @LinkType,
               LinkEntityId  = @LinkEntityId,
               IconName      = @IconName,
               Badge         = @Badge,
               Description   = @Description,
               SortOrder     = @SortOrder,
               OpensInNewTab = @OpensInNewTab,
               IsActive      = @IsActive,
               UpdatedAt     = SYSUTCDATETIME(),
               UpdatedBy     = @AdminUserId
        WHERE  Id = @Id AND IsDeleted = 0;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.Menus
        (
            ParentId, Title, Location, Url, LinkType, LinkEntityId,
            IconName, Badge, Description, SortOrder, OpensInNewTab,
            CreatedAt, CreatedBy, IsActive, IsDeleted
        )
        VALUES
        (
            @ParentId, @Title, @Location, @Url, @LinkType, @LinkEntityId,
            @IconName, @Badge, @Description, @SortOrder, @OpensInNewTab,
            SYSUTCDATETIME(), @AdminUserId, @IsActive, 0
        );

        SET @Id = SCOPE_IDENTITY();
    END

    COMMIT TRANSACTION;

    SELECT @Id AS Id;
END
GO

-- 4. Menu Delete (Soft Delete)
CREATE OR ALTER PROCEDURE dbo.usp_Menu_Delete
    @Id          INT,
    @AdminUserId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;

    -- Also soft delete direct children if any
    UPDATE dbo.Menus
    SET    IsDeleted = 1,
           IsActive  = 0,
           UpdatedAt = SYSUTCDATETIME(),
           UpdatedBy = @AdminUserId
    WHERE  Id = @Id OR ParentId = @Id;

    COMMIT TRANSACTION;

    SELECT CAST(1 AS BIT) AS Success;
END
GO

-- 5. Menu Update Status
CREATE OR ALTER PROCEDURE dbo.usp_Menu_UpdateStatus
    @Id          INT,
    @IsActive    BIT,
    @AdminUserId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Menus
    SET    IsActive  = @IsActive,
           UpdatedAt = SYSUTCDATETIME(),
           UpdatedBy = @AdminUserId
    WHERE  Id = @Id AND IsDeleted = 0;

    SELECT CAST(1 AS BIT) AS Success;
END
GO

-- 6. Menu Lookup (For parent menu selectors)
CREATE OR ALTER PROCEDURE dbo.usp_Menu_Lookup
    @Location VARCHAR(32) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  Id,
            Name = Title,
            ParentId
    FROM    dbo.Menus
    WHERE   IsActive = 1 AND IsDeleted = 0
      AND  (@Location IS NULL OR @Location = 'All' OR Location = @Location)
    ORDER BY SortOrder ASC, Title ASC;
END
GO
