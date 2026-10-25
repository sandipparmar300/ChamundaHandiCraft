CREATE OR ALTER PROCEDURE dbo.usp_CustomerAddress_Delete
    @AddressId INT,
    @CustomerId INT,
    @Success BIT OUTPUT,
    @ErrorMessage NVARCHAR(400) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Success = 0;
    SET @ErrorMessage = NULL;

    DECLARE @WasDefault BIT = 0;

    SELECT @WasDefault = IsDefault
    FROM dbo.CustomerAddresses
    WHERE Id = @AddressId
      AND CustomerId = @CustomerId
      AND IsDeleted = 0;

    IF @@ROWCOUNT = 0
    BEGIN
        SET @ErrorMessage = 'Address not found or already deleted.';
        RETURN;
    END

    -- Soft delete
    UPDATE dbo.CustomerAddresses
    SET IsDeleted = 1,
        IsDefault = 0,
        UpdatedAt = GETUTCDATE()
    WHERE Id = @AddressId
      AND CustomerId = @CustomerId;

    -- If the deleted address was default, promote the newest remaining address to default
    IF @WasDefault = 1
    BEGIN
        DECLARE @NextDefaultId INT;
        SELECT TOP 1 @NextDefaultId = Id
        FROM dbo.CustomerAddresses
        WHERE CustomerId = @CustomerId
          AND IsDeleted = 0
        ORDER BY CreatedAt DESC;

        IF @NextDefaultId IS NOT NULL
        BEGIN
            UPDATE dbo.CustomerAddresses
            SET IsDefault = 1,
                UpdatedAt = GETUTCDATE()
            WHERE Id = @NextDefaultId;
        END
    END

    SET @Success = 1;
END
GO
