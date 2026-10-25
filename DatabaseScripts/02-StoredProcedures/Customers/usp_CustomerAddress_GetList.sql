CREATE OR ALTER PROCEDURE dbo.usp_CustomerAddress_GetList
    @CustomerId INT,
    @Search NVARCHAR(100) = NULL,
    @SortBy VARCHAR(50) = NULL,
    @SortDescending BIT = 0,
    @Page INT = 1,
    @PageSize INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    SET @Page = CASE WHEN @Page < 1 THEN 1 ELSE @Page END;
    SET @PageSize = CASE WHEN @PageSize < 1 THEN 20 WHEN @PageSize > 100 THEN 100 ELSE @PageSize END;
    SET @Search = NULLIF(LTRIM(RTRIM(@Search)), '');

    DECLARE @Offset INT = (@Page - 1) * @PageSize;

    -- Query filtered list
    WITH FilteredAddresses AS (
        SELECT
            Id,
            CustomerId,
            LabelType,
            FullName,
            Phone,
            AlternatePhone,
            Line1,
            Line2,
            Landmark,
            CityName,
            StateName,
            CountryName,
            Pincode,
            IsDefault,
            CreatedAt,
            UpdatedAt
        FROM dbo.CustomerAddresses
        WHERE CustomerId = @CustomerId
          AND IsDeleted = 0
          AND (
              @Search IS NULL OR
              FullName LIKE '%' + @Search + '%' OR
              Phone LIKE '%' + @Search + '%' OR
              Line1 LIKE '%' + @Search + '%' OR
              Line2 LIKE '%' + @Search + '%' OR
              Landmark LIKE '%' + @Search + '%' OR
              CityName LIKE '%' + @Search + '%' OR
              StateName LIKE '%' + @Search + '%' OR
              Pincode LIKE '%' + @Search + '%'
          )
    )
    SELECT
        Id,
        CustomerId,
        LabelType,
        FullName,
        Phone,
        AlternatePhone,
        Line1,
        Line2,
        Landmark,
        CityName,
        StateName,
        CountryName,
        Pincode,
        IsDefault,
        CreatedAt,
        UpdatedAt,
        COUNT(*) OVER() AS TotalCount
    FROM FilteredAddresses
    ORDER BY
        IsDefault DESC,
        CASE WHEN @SortBy = 'FullName' AND @SortDescending = 0 THEN FullName END ASC,
        CASE WHEN @SortBy = 'FullName' AND @SortDescending = 1 THEN FullName END DESC,
        CASE WHEN @SortBy = 'City' AND @SortDescending = 0 THEN CityName END ASC,
        CASE WHEN @SortBy = 'City' AND @SortDescending = 1 THEN CityName END DESC,
        CreatedAt DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO
