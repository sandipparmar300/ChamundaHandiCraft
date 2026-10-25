CREATE OR ALTER PROCEDURE dbo.usp_CustomerAddress_Save
    @Id INT = 0,
    @CustomerId INT,
    @LabelType TINYINT = 0, -- 0=Home, 1=Work, 2=Other
    @FullName NVARCHAR(200),
    @Phone VARCHAR(24),
    @AlternatePhone VARCHAR(24) = NULL,
    @Line1 NVARCHAR(300),
    @Line2 NVARCHAR(300) = NULL,
    @Landmark NVARCHAR(200) = NULL,
    @CityName NVARCHAR(150),
    @StateName NVARCHAR(150),
    @CountryName NVARCHAR(150) = 'India',
    @Pincode VARCHAR(12),
    @IsDefault BIT = 0,
    @NewAddressId INT OUTPUT,
    @ErrorMessage NVARCHAR(400) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @NewAddressId = 0;
    SET @ErrorMessage = NULL;

    -- Clean inputs
    SET @FullName = LTRIM(RTRIM(@FullName));
    SET @Phone = LTRIM(RTRIM(@Phone));
    SET @AlternatePhone = NULLIF(LTRIM(RTRIM(@AlternatePhone)), '');
    SET @Line1 = LTRIM(RTRIM(@Line1));
    SET @Line2 = NULLIF(LTRIM(RTRIM(@Line2)), '');
    SET @Landmark = NULLIF(LTRIM(RTRIM(@Landmark)), '');
    SET @CityName = LTRIM(RTRIM(@CityName));
    SET @StateName = LTRIM(RTRIM(@StateName));
    SET @CountryName = COALESCE(NULLIF(LTRIM(RTRIM(@CountryName)), ''), 'India');
    SET @Pincode = LTRIM(RTRIM(@Pincode));

    -- Basic Validations
    IF @CustomerId <= 0
    BEGIN
        SET @ErrorMessage = 'Invalid customer identifier.';
        RETURN;
    END

    IF @FullName IS NULL OR LEN(@FullName) < 2
    BEGIN
        SET @ErrorMessage = 'Full name must be at least 2 characters.';
        RETURN;
    END

    IF @Phone IS NULL OR LEN(@Phone) < 10
    BEGIN
        SET @ErrorMessage = 'A valid 10-digit mobile number is required.';
        RETURN;
    END

    IF @Line1 IS NULL OR LEN(@Line1) < 3
    BEGIN
        SET @ErrorMessage = 'Street address / Flat number is required.';
        RETURN;
    END

    IF @Pincode IS NULL OR LEN(@Pincode) < 6
    BEGIN
        SET @ErrorMessage = 'A valid PIN code is required.';
        RETURN;
    END

    -- If customer has no active addresses, make this one default automatically
    IF NOT EXISTS (SELECT 1 FROM dbo.CustomerAddresses WHERE CustomerId = @CustomerId AND IsDeleted = 0 AND Id <> @Id)
    BEGIN
        SET @IsDefault = 1;
    END

    -- If this address is set to default, unset default on all other addresses
    IF @IsDefault = 1
    BEGIN
        UPDATE dbo.CustomerAddresses
        SET IsDefault = 0,
            UpdatedAt = GETUTCDATE()
        WHERE CustomerId = @CustomerId
          AND IsDeleted = 0
          AND Id <> @Id;
    END

    IF @Id > 0
    BEGIN
        -- Update existing address
        UPDATE dbo.CustomerAddresses
        SET LabelType = @LabelType,
            FullName = @FullName,
            Phone = @Phone,
            AlternatePhone = @AlternatePhone,
            Line1 = @Line1,
            Line2 = @Line2,
            Landmark = @Landmark,
            CityName = @CityName,
            StateName = @StateName,
            CountryName = @CountryName,
            Pincode = @Pincode,
            IsDefault = @IsDefault,
            UpdatedAt = GETUTCDATE()
        WHERE Id = @Id
          AND CustomerId = @CustomerId
          AND IsDeleted = 0;

        IF @@ROWCOUNT = 0
        BEGIN
            SET @ErrorMessage = 'Address not found or already deleted.';
            RETURN;
        END

        SET @NewAddressId = @Id;
    END
    ELSE
    BEGIN
        -- Insert new address
        INSERT INTO dbo.CustomerAddresses
        (
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
            IsActive,
            IsDeleted
        )
        VALUES
        (
            @CustomerId,
            @LabelType,
            @FullName,
            @Phone,
            @AlternatePhone,
            @Line1,
            @Line2,
            @Landmark,
            @CityName,
            @StateName,
            @CountryName,
            @Pincode,
            @IsDefault,
            GETUTCDATE(),
            1,
            0
        );

        SET @NewAddressId = SCOPE_IDENTITY();
    END
END
GO
