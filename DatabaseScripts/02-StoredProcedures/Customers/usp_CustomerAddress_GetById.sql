CREATE OR ALTER PROCEDURE dbo.usp_CustomerAddress_GetById
    @AddressId INT,
    @CustomerId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
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
    WHERE Id = @AddressId
      AND CustomerId = @CustomerId
      AND IsDeleted = 0;
END
GO
