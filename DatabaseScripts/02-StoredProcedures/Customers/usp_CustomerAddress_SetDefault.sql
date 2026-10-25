CREATE OR ALTER PROCEDURE dbo.usp_CustomerAddress_SetDefault
    @AddressId INT,
    @CustomerId INT,
    @Success BIT OUTPUT,
    @ErrorMessage NVARCHAR(400) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Success = 0;
    SET @ErrorMessage = NULL;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.CustomerAddresses
        WHERE Id = @AddressId
          AND CustomerId = @CustomerId
          AND IsDeleted = 0
    )
    BEGIN
        SET @ErrorMessage = 'Address not found or has been deleted.';
        RETURN;
    END

    -- Unset default for all addresses of customer
    UPDATE dbo.CustomerAddresses
    SET IsDefault = 0,
        UpdatedAt = GETUTCDATE()
    WHERE CustomerId = @CustomerId
      AND IsDeleted = 0;

    -- Set new default
    UPDATE dbo.CustomerAddresses
    SET IsDefault = 1,
        UpdatedAt = GETUTCDATE()
    WHERE Id = @AddressId
      AND CustomerId = @CustomerId;

    SET @Success = 1;
END
GO
