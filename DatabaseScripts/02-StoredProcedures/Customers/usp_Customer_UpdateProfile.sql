CREATE OR ALTER PROCEDURE dbo.usp_Customer_UpdateProfile
    @CustomerId INT,
    @FullName NVARCHAR(200),
    @Phone VARCHAR(24) = NULL,
    @Gender VARCHAR(16) = NULL,
    @DateOfBirth DATE = NULL,
    @Gstin VARCHAR(20) = NULL,
    @Success BIT OUTPUT,
    @ErrorMessage NVARCHAR(400) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Success = 0;
    SET @ErrorMessage = NULL;

    SET @FullName = LTRIM(RTRIM(@FullName));
    SET @Phone = NULLIF(LTRIM(RTRIM(@Phone)), '');
    SET @Gender = NULLIF(LTRIM(RTRIM(@Gender)), '');
    SET @Gstin = NULLIF(UPPER(LTRIM(RTRIM(@Gstin))), '');

    IF @FullName IS NULL OR LEN(@FullName) < 2
    BEGIN
        SET @ErrorMessage = 'Full name must be at least 2 characters.';
        RETURN;
    END

    -- Check if another customer is using this phone
    IF @Phone IS NOT NULL AND EXISTS (
        SELECT 1 FROM dbo.Customers
        WHERE Phone = @Phone
          AND Id <> @CustomerId
          AND IsDeleted = 0
    )
    BEGIN
        SET @ErrorMessage = 'This mobile number is already registered to another account.';
        RETURN;
    END

    UPDATE dbo.Customers
    SET FullName = @FullName,
        Phone = @Phone,
        Gender = @Gender,
        DateOfBirth = @DateOfBirth,
        Gstin = @Gstin,
        UpdatedAt = GETUTCDATE()
    WHERE Id = @CustomerId
      AND IsDeleted = 0;

    IF @@ROWCOUNT = 0
    BEGIN
        SET @ErrorMessage = 'Customer account not found.';
        RETURN;
    END

    SET @Success = 1;
END
GO
