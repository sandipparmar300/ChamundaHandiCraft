CREATE OR ALTER PROCEDURE dbo.usp_Customer_VerifyMobileOtp
    @CustomerId INT,
    @Mobile VARCHAR(24),
    @CodeHash CHAR(64),
    @MasterHash CHAR(64) = NULL,
    @Success BIT OUTPUT,
    @ErrorMessage NVARCHAR(400) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Success = 0;
    SET @ErrorMessage = NULL;

    SET @Mobile = LTRIM(RTRIM(@Mobile));
    IF @Mobile IS NULL OR LEN(@Mobile) < 10
    BEGIN
        SET @ErrorMessage = 'A valid mobile number is required.';
        RETURN;
    END

    -- Clean mobile format
    DECLARE @CleanMobile VARCHAR(24);
    SET @CleanMobile = REPLACE(REPLACE(REPLACE(@Mobile, ' ', ''), '-', ''), '+91', '');

    -- Resolve customer id if not explicitly passed
    IF @CustomerId IS NULL OR @CustomerId <= 0
    BEGIN
        SELECT TOP 1 @CustomerId = Id
        FROM dbo.Customers
        WHERE (Phone = @Mobile OR Phone = @CleanMobile OR Phone LIKE '%' + @CleanMobile)
          AND IsDeleted = 0;
    END

    IF @CustomerId IS NULL OR @CustomerId <= 0
    BEGIN
        SET @ErrorMessage = 'No customer account found for this mobile number.';
        RETURN;
    END

    -- Find latest active OTP for this destination
    DECLARE @OtpId BIGINT = NULL;
    DECLARE @StoredHash CHAR(64) = NULL;
    DECLARE @ExpiresAt DATETIME2 = NULL;
    DECLARE @Attempts INT = 0;

    SELECT TOP 1
        @OtpId = Id,
        @StoredHash = CodeHash,
        @ExpiresAt = ExpiresAt,
        @Attempts = AttemptCount
    FROM dbo.CustomerOtps
    WHERE (Destination = @Mobile OR Destination = @CleanMobile OR Destination LIKE '%' + @CleanMobile)
      AND Purpose = 'VerifyMobile'
      AND ConsumedAt IS NULL
    ORDER BY Id DESC;

    -- Master demo code check (allows instant verification with standard dev code or matching hash)
    IF @MasterHash IS NOT NULL AND @CodeHash = @MasterHash
    BEGIN
        IF @OtpId IS NOT NULL
        BEGIN
            UPDATE dbo.CustomerOtps SET ConsumedAt = GETUTCDATE() WHERE Id = @OtpId;
        END

        UPDATE dbo.Customers
        SET Phone = @Mobile,
            MobileVerified = 1,
            UpdatedAt = GETUTCDATE()
        WHERE Id = @CustomerId;

        SET @Success = 1;
        RETURN;
    END

    IF @OtpId IS NULL OR @ExpiresAt < GETUTCDATE()
    BEGIN
        SET @ErrorMessage = 'No valid verification code was requested or the code has expired. Please request a new code.';
        RETURN;
    END

    IF @Attempts >= 5
    BEGIN
        SET @ErrorMessage = 'Too many failed attempts. Please request a new verification code.';
        RETURN;
    END

    IF @StoredHash <> @CodeHash
    BEGIN
        UPDATE dbo.CustomerOtps
        SET AttemptCount = AttemptCount + 1
        WHERE Id = @OtpId;

        SET @ErrorMessage = 'Invalid verification code. Please check and try again.';
        RETURN;
    END

    -- Mark OTP consumed
    UPDATE dbo.CustomerOtps
    SET ConsumedAt = GETUTCDATE()
    WHERE Id = @OtpId;

    -- Update Customer record
    UPDATE dbo.Customers
    SET Phone = @Mobile,
        MobileVerified = 1,
        UpdatedAt = GETUTCDATE()
    WHERE Id = @CustomerId;

    SET @Success = 1;
END
GO
