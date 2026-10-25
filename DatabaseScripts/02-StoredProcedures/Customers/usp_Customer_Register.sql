CREATE OR ALTER PROCEDURE dbo.usp_Customer_Register
    @FullName NVARCHAR(200),
    @Email NVARCHAR(256),
    @Phone VARCHAR(24) = NULL,
    @PasswordHash NVARCHAR(500),
    @GuestToken VARCHAR(64) = NULL,
    @NewCustomerId INT OUTPUT,
    @ErrorMessage NVARCHAR(400) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @NewCustomerId = 0;
    SET @ErrorMessage = NULL;

    -- Clean inputs
    SET @FullName = LTRIM(RTRIM(@FullName));
    SET @Email = LOWER(LTRIM(RTRIM(@Email)));
    SET @Phone = NULLIF(LTRIM(RTRIM(@Phone)), '');

    -- Validation
    IF @FullName IS NULL OR LEN(@FullName) < 2
    BEGIN
        SET @ErrorMessage = 'Full name must be at least 2 characters.';
        RETURN;
    END

    IF @Email IS NULL OR @Email NOT LIKE '%_@__%.__%'
    BEGIN
        SET @ErrorMessage = 'A valid email address is required.';
        RETURN;
    END

    -- Check unique Email
    IF EXISTS (SELECT 1 FROM dbo.Customers WHERE Email = @Email AND IsDeleted = 0)
    BEGIN
        SET @ErrorMessage = 'An account with this email address already exists. Please sign in instead.';
        RETURN;
    END

    -- Check unique Phone if provided
    IF @Phone IS NOT NULL AND EXISTS (SELECT 1 FROM dbo.Customers WHERE Phone = @Phone AND IsDeleted = 0)
    BEGIN
        SET @ErrorMessage = 'An account with this mobile number already exists. Please sign in instead.';
        RETURN;
    END

    -- Insert new customer
    INSERT INTO dbo.Customers
    (
        FullName,
        Email,
        Phone,
        PasswordHash,
        EmailVerified,
        MobileVerified,
        Status,
        OrderCount,
        LifetimeValue,
        RewardPointBalance,
        RewardTier,
        GuestToken,
        RegisteredOn,
        CreatedAt,
        IsActive,
        IsDeleted
    )
    VALUES
    (
        @FullName,
        @Email,
        @Phone,
        @PasswordHash,
        1, -- EmailVerified (auto-verified upon registration)
        0, -- MobileVerified
        1, -- Status: Active
        0, -- OrderCount
        0.00, -- LifetimeValue
        50, -- 50 Welcome reward points
        'Bronze',
        @GuestToken,
        GETUTCDATE(),
        GETUTCDATE(),
        1, -- IsActive
        0  -- IsDeleted
    );

    SET @NewCustomerId = SCOPE_IDENTITY();
END
GO
