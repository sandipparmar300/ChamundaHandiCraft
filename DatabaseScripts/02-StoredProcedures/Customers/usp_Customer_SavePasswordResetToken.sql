CREATE OR ALTER PROCEDURE dbo.usp_Customer_SavePasswordResetToken
    @Destination NVARCHAR(256),
    @Channel TINYINT, -- 0 = Email, 1 = SMS
    @TokenHash CHAR(64),
    @ExpiresAt DATETIME2,
    @CustomerId INT OUTPUT,
    @FullName NVARCHAR(200) OUTPUT,
    @Email NVARCHAR(256) OUTPUT,
    @Success BIT OUTPUT,
    @ErrorMessage NVARCHAR(400) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @CustomerId = 0;
    SET @FullName = NULL;
    SET @Email = NULL;
    SET @Success = 0;
    SET @ErrorMessage = NULL;

    SET @Destination = LTRIM(RTRIM(@Destination));

    -- Check that customer exists
    SELECT TOP 1
        @CustomerId = Id,
        @FullName = FullName,
        @Email = Email
    FROM dbo.Customers 
    WHERE (Email = LOWER(@Destination) OR Phone = @Destination)
      AND IsDeleted = 0;

    IF @CustomerId = 0 OR @CustomerId IS NULL
    BEGIN
        -- Security note: Return success=0 internally, but caller can show neutral message
        SET @ErrorMessage = 'No account found with this email or mobile number.';
        RETURN;
    END

    -- Expire previous unconsumed reset tokens for this destination
    UPDATE dbo.CustomerOtps
    SET ConsumedAt = GETUTCDATE()
    WHERE Destination = @Destination
      AND Purpose = 'PasswordReset'
      AND ConsumedAt IS NULL;

    -- Insert OTP/Token
    INSERT INTO dbo.CustomerOtps
    (
        Destination,
        Channel,
        Purpose,
        CodeHash,
        ExpiresAt,
        AttemptCount,
        CreatedAt
    )
    VALUES
    (
        @Destination,
        @Channel,
        'PasswordReset',
        @TokenHash,
        @ExpiresAt,
        0,
        GETUTCDATE()
    );

    SET @Success = 1;
END
GO
