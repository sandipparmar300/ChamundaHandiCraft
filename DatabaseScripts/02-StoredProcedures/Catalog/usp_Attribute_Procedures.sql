/* =============================================================================
   usp_Attribute_Procedures.sql
   -----------------------------------------------------------------------------
   Stored procedures for Module 03 - Product Attributes & Values.
   Tables: dbo.ProductAttributes, dbo.ProductAttributeValues
   ============================================================================= */

SET NOCOUNT ON;
GO

-- 1. GridList
CREATE OR ALTER PROCEDURE dbo.usp_Attribute_GridList
    @SearchText             NVARCHAR(200)   = NULL,
    @IsActive               BIT             = NULL,
    @IsFilterable           BIT             = NULL,
    @IsVariantDefining      BIT             = NULL,
    @SortColumn             VARCHAR(64)     = 'SortOrder',
    @SortOrder              VARCHAR(4)      = 'ASC',
    @PageSize               INT             = 25,
    @PageIndex              INT             = 1,
    @TotalRecords           INT             OUTPUT,
    @TotalFilteredRecords   INT             OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @PageSize  IS NULL OR @PageSize  < 1 SET @PageSize  = 25;
    IF @PageIndex IS NULL OR @PageIndex < 1 SET @PageIndex = 1;
    IF @SortOrder IS NULL OR @SortOrder NOT IN ('ASC','DESC') SET @SortOrder = 'ASC';

    SET @SearchText = NULLIF(LTRIM(RTRIM(ISNULL(@SearchText, N''))), N'');

    SELECT @TotalRecords = COUNT(*)
    FROM   dbo.ProductAttributes
    WHERE  IsDeleted = 0;

    ;WITH Filtered AS
    (
        SELECT  a.Id,
                a.AttributeName,
                a.AttributeCode,
                a.DisplayType,
                a.IsFilterable,
                a.IsRequired,
                a.IsVariantDefining,
                a.SortOrder,
                a.IsActive,
                a.CreatedAt,
                a.UpdatedAt,
                ValueCount = (SELECT COUNT(1) FROM dbo.ProductAttributeValues v WHERE v.AttributeId = a.Id AND v.IsDeleted = 0),
                UsedByProductCount = (SELECT COUNT(DISTINCT m.ProductId) FROM dbo.ProductAttributeMappings m WHERE m.AttributeId = a.Id)
        FROM    dbo.ProductAttributes AS a
        WHERE   a.IsDeleted = 0
          AND  (@IsActive           IS NULL OR a.IsActive           = @IsActive)
          AND  (@IsFilterable       IS NULL OR a.IsFilterable       = @IsFilterable)
          AND  (@IsVariantDefining  IS NULL OR a.IsVariantDefining  = @IsVariantDefining)
          AND  (@SearchText         IS NULL
                OR a.AttributeName LIKE N'%' + @SearchText + N'%'
                OR a.AttributeCode LIKE '%' + @SearchText + '%')
    )
    SELECT @TotalFilteredRecords = COUNT(*) FROM Filtered;

    ;WITH Filtered AS
    (
        SELECT  a.Id,
                a.AttributeName,
                a.AttributeCode,
                a.DisplayType,
                a.IsFilterable,
                a.IsRequired,
                a.IsVariantDefining,
                a.SortOrder,
                a.IsActive,
                a.CreatedAt,
                a.UpdatedAt,
                ValueCount = (SELECT COUNT(1) FROM dbo.ProductAttributeValues v WHERE v.AttributeId = a.Id AND v.IsDeleted = 0),
                UsedByProductCount = (SELECT COUNT(DISTINCT m.ProductId) FROM dbo.ProductAttributeMappings m WHERE m.AttributeId = a.Id)
        FROM    dbo.ProductAttributes AS a
        WHERE   a.IsDeleted = 0
          AND  (@IsActive           IS NULL OR a.IsActive           = @IsActive)
          AND  (@IsFilterable       IS NULL OR a.IsFilterable       = @IsFilterable)
          AND  (@IsVariantDefining  IS NULL OR a.IsVariantDefining  = @IsVariantDefining)
          AND  (@SearchText         IS NULL
                OR a.AttributeName LIKE N'%' + @SearchText + N'%'
                OR a.AttributeCode LIKE '%' + @SearchText + '%')
    )
    SELECT  Id,
            AttributeName,
            AttributeCode,
            DisplayType,
            IsFilterable,
            IsRequired,
            IsVariantDefining,
            SortOrder,
            IsActive,
            CreatedAt,
            UpdatedAt,
            ValueCount,
            UsedByProductCount
    FROM    Filtered
    ORDER BY
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'AttributeName' THEN AttributeName END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'AttributeName' THEN AttributeName END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'AttributeCode' THEN AttributeCode END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'AttributeCode' THEN AttributeCode END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'ValueCount' THEN ValueCount END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'ValueCount' THEN ValueCount END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'SortOrder' THEN SortOrder END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'SortOrder' THEN SortOrder END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'CreatedAt' THEN CreatedAt END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'CreatedAt' THEN CreatedAt END DESC,
        SortOrder ASC, Id ASC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO

-- Synonym for generic CRUD convention
CREATE OR ALTER PROCEDURE dbo.GridList_Attribute
    @SearchText             NVARCHAR(200)   = NULL,
    @IsActive               BIT             = NULL,
    @IsFilterable           BIT             = NULL,
    @IsVariantDefining      BIT             = NULL,
    @SortColumn             VARCHAR(64)     = 'SortOrder',
    @SortOrder              VARCHAR(4)      = 'ASC',
    @PageSize               INT             = 25,
    @PageIndex              INT             = 1,
    @TotalRecords           INT             OUTPUT,
    @TotalFilteredRecords   INT             OUTPUT
AS
BEGIN
    EXEC dbo.usp_Attribute_GridList
        @SearchText           = @SearchText,
        @IsActive             = @IsActive,
        @IsFilterable         = @IsFilterable,
        @IsVariantDefining    = @IsVariantDefining,
        @SortColumn           = @SortColumn,
        @SortOrder            = @SortOrder,
        @PageSize             = @PageSize,
        @PageIndex            = @PageIndex,
        @TotalRecords         = @TotalRecords OUTPUT,
        @TotalFilteredRecords = @TotalFilteredRecords OUTPUT;
END
GO

-- 2. GetById (Returns Attribute header + child Values)
CREATE OR ALTER PROCEDURE dbo.usp_Attribute_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Result set 1: Attribute header
    SELECT  a.Id,
            a.AttributeName,
            a.AttributeCode,
            a.DisplayType,
            a.IsFilterable,
            a.IsRequired,
            a.IsVariantDefining,
            a.SortOrder,
            a.IsActive,
            a.CreatedAt,
            a.CreatedBy,
            a.UpdatedAt,
            a.UpdatedBy,
            ValueCount = (SELECT COUNT(1) FROM dbo.ProductAttributeValues v WHERE v.AttributeId = a.Id AND v.IsDeleted = 0)
    FROM    dbo.ProductAttributes AS a
    WHERE   a.Id = @Id AND a.IsDeleted = 0;

    -- Result set 2: Attribute values
    SELECT  v.Id,
            v.AttributeId,
            v.Label,
            v.ValueCode,
            v.ColourHex,
            v.ImageUrl,
            v.SortOrder,
            v.IsActive
    FROM    dbo.ProductAttributeValues AS v
    WHERE   v.AttributeId = @Id AND v.IsDeleted = 0
    ORDER BY v.SortOrder ASC, v.Id ASC;
END
GO

-- 3. Save (Header + Child values via JSON or TVP)
CREATE OR ALTER PROCEDURE dbo.usp_Attribute_Save
    @Id                 INT             = 0,
    @AttributeName      NVARCHAR(150),
    @AttributeCode      VARCHAR(64)     = NULL,
    @DisplayType        VARCHAR(24)     = 'Pill',
    @IsFilterable       BIT             = 1,
    @IsRequired         BIT             = 0,
    @IsVariantDefining  BIT             = 0,
    @SortOrder          INT             = 0,
    @IsActive           BIT             = 1,
    @ValuesJson         NVARCHAR(MAX)   = NULL, -- JSON array of values: [{"Id":0,"Label":"Red","ValueCode":"RED","ColourHex":"#FF0000","SortOrder":1}]
    @AdminUserId        INT             = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Generate code if empty
    IF @AttributeCode IS NULL OR LTRIM(RTRIM(@AttributeCode)) = ''
    BEGIN
        SET @AttributeCode = UPPER(REPLACE(REPLACE(LTRIM(RTRIM(@AttributeName)), ' ', '_'), '-', '_'));
    END

    -- Ensure unique attribute code
    IF EXISTS (SELECT 1 FROM dbo.ProductAttributes WHERE AttributeCode = @AttributeCode AND Id <> @Id AND IsDeleted = 0)
    BEGIN
        SET @AttributeCode = @AttributeCode + '_' + CAST(ABS(CHECKSUM(NEWID())) % 1000 AS VARCHAR(10));
    END

    BEGIN TRANSACTION;

    IF @Id > 0
    BEGIN
        UPDATE dbo.ProductAttributes
        SET    AttributeName      = @AttributeName,
               AttributeCode      = @AttributeCode,
               DisplayType        = @DisplayType,
               IsFilterable       = @IsFilterable,
               IsRequired         = @IsRequired,
               IsVariantDefining  = @IsVariantDefining,
               SortOrder          = @SortOrder,
               IsActive           = @IsActive,
               UpdatedAt          = SYSUTCDATETIME(),
               UpdatedBy          = @AdminUserId
        WHERE  Id = @Id AND IsDeleted = 0;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.ProductAttributes
        (
            AttributeName, AttributeCode, DisplayType, IsFilterable, IsRequired,
            IsVariantDefining, SortOrder, IsActive, CreatedAt, CreatedBy
        )
        VALUES
        (
            @AttributeName, @AttributeCode, @DisplayType, @IsFilterable, @IsRequired,
            @IsVariantDefining, @SortOrder, @IsActive, SYSUTCDATETIME(), @AdminUserId
        );

        SET @Id = SCOPE_IDENTITY();
    END

    -- Synchronize Attribute Values from JSON if provided
    IF @ValuesJson IS NOT NULL AND ISJSON(@ValuesJson) = 1
    BEGIN
        -- Parse incoming JSON values
        SELECT  ValueId   = ISNULL(JSON_VALUE(j.value, '$.Id'), 0),
                Label     = JSON_VALUE(j.value, '$.Label'),
                ValueCode = ISNULL(JSON_VALUE(j.value, '$.ValueCode'), LOWER(REPLACE(JSON_VALUE(j.value, '$.Label'), ' ', '-'))),
                ColourHex = JSON_VALUE(j.value, '$.ColourHex'),
                ImageUrl  = JSON_VALUE(j.value, '$.ImageUrl'),
                SortOrder = ISNULL(CAST(JSON_VALUE(j.value, '$.SortOrder') AS INT), 0),
                IsActive  = ISNULL(CAST(JSON_VALUE(j.value, '$.IsActive') AS BIT), 1)
        INTO    #IncomingValues
        FROM    OPENJSON(@ValuesJson) AS j
        WHERE   JSON_VALUE(j.value, '$.Label') IS NOT NULL AND LTRIM(RTRIM(JSON_VALUE(j.value, '$.Label'))) <> '';

        -- Soft delete existing values not in incoming list
        UPDATE  dbo.ProductAttributeValues
        SET     IsDeleted = 1,
                UpdatedAt = SYSUTCDATETIME(),
                UpdatedBy = @AdminUserId
        WHERE   AttributeId = @Id
          AND   Id NOT IN (SELECT ValueId FROM #IncomingValues WHERE ValueId > 0)
          AND   IsDeleted = 0;

        -- Update existing values
        UPDATE  v
        SET     v.Label     = src.Label,
                v.ValueCode = src.ValueCode,
                v.ColourHex = src.ColourHex,
                v.ImageUrl  = src.ImageUrl,
                v.SortOrder = src.SortOrder,
                v.IsActive  = src.IsActive,
                v.UpdatedAt = SYSUTCDATETIME(),
                v.UpdatedBy = @AdminUserId
        FROM    dbo.ProductAttributeValues AS v
        JOIN    #IncomingValues AS src ON src.ValueId = v.Id
        WHERE   v.AttributeId = @Id;

        -- Insert new values
        INSERT INTO dbo.ProductAttributeValues
        (
            AttributeId, Label, ValueCode, ColourHex, ImageUrl,
            SortOrder, IsActive, CreatedAt, CreatedBy
        )
        SELECT  @Id,
                src.Label,
                src.ValueCode,
                src.ColourHex,
                src.ImageUrl,
                src.SortOrder,
                src.IsActive,
                SYSUTCDATETIME(),
                @AdminUserId
        FROM    #IncomingValues AS src
        WHERE   src.ValueId = 0 OR NOT EXISTS (SELECT 1 FROM dbo.ProductAttributeValues WHERE Id = src.ValueId);

        DROP TABLE #IncomingValues;
    END

    COMMIT TRANSACTION;

    SELECT @Id AS Id;
END
GO

-- 4. Delete (Soft Delete Attribute and its values)
CREATE OR ALTER PROCEDURE dbo.usp_Attribute_Delete
    @Id          INT,
    @AdminUserId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;

    UPDATE dbo.ProductAttributes
    SET    IsDeleted = 1,
           UpdatedAt = SYSUTCDATETIME(),
           UpdatedBy = @AdminUserId
    WHERE  Id = @Id;

    UPDATE dbo.ProductAttributeValues
    SET    IsDeleted = 1,
           UpdatedAt = SYSUTCDATETIME(),
           UpdatedBy = @AdminUserId
    WHERE  AttributeId = @Id;

    COMMIT TRANSACTION;

    SELECT CAST(1 AS BIT) AS Success;
END
GO

-- 5. UpdateStatus
CREATE OR ALTER PROCEDURE dbo.usp_Attribute_UpdateStatus
    @Id          INT,
    @IsActive    BIT,
    @AdminUserId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.ProductAttributes
    SET    IsActive  = @IsActive,
           UpdatedAt = SYSUTCDATETIME(),
           UpdatedBy = @AdminUserId
    WHERE  Id = @Id AND IsDeleted = 0;

    SELECT CAST(1 AS BIT) AS Success;
END
GO

-- 6. Lookup
CREATE OR ALTER PROCEDURE dbo.usp_Attribute_GetLookup
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  Id,
            Name = AttributeName + ' (' + AttributeCode + ')'
    FROM    dbo.ProductAttributes
    WHERE   IsActive = 1 AND IsDeleted = 0
    ORDER   BY SortOrder ASC, AttributeName ASC;
END
GO
