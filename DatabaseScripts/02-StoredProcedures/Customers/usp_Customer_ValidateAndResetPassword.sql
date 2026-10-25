CREATE OR ALTER PROCEDURE dbo.usp_Customer_ValidateAndResetPassword
    @TokenHash CHAR(64),
    @NewPasswordHash NVARCHAR(500),
    @SignOutOthers BIT = 1,
    @Success BIT OUTPUT,
    @ErrorMessage NVARCHAR(400) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Success = 0;
    SET @ErrorMessage = NULL;

    DECLARE @OtpId BIGINT;
    DECLARE @Destination NVARCHAR(256);
    DECLARE @ExpiresAt DATETIME2;
    DECLARE @ConsumedAt DATETIME2;
    DECLARE @CustomerId INT;

    SELECT TOP 1
        @OtpId = Id,
        @Destination = Destination,
        @ExpiresAt = ExpiresAt,
        @ConsumedAt = ConsumedAt
    FROM dbo.CustomerOtps
    WHERE CodeHash = @TokenHash
      AND Purpose = 'PasswordReset'
    ORDER BY Id DESC;

    IF @OtpId IS NULL
    BEGIN
        SET @ErrorMessage = 'Invalid or expired password reset link.';
        RETURN;
    END

    IF @ConsumedAt IS NOT NULL
    BEGIN
        SET @ErrorMessage = 'This password reset link has already been used. Please request a new one.';
        RETURN;
    END

    IF @ExpiresAt < GETUTCDATE()
    BEGIN
        SET @ErrorMessage = 'This password reset link has expired. Please request a new one.';
        RETURN;
    END

    -- Find matching customer
    SELECT TOP 1 @CustomerId = Id
    FROM dbo.Customers
    WHERE (Email = LOWER(@Destination) OR Phone = @Destination)
      AND IsDeleted = 0;

    IF @CustomerId IS NULL
    BEGIN
        SET @ErrorMessage = 'Account not found.';
        RETURN;
    END

    -- Update Password
    UPDATE dbo.Customers
    SET PasswordHash = @NewPasswordHash,
        UpdatedAt = GETUTCDATE()
    WHERE Id = @CustomerId;

    -- Mark token as consumed
    UPDATE dbo.CustomerOtps
    SET ConsumedAt = GETUTCDATE()
    WHERE Id = @OtpId;

    -- Sign out of other sessions if requested
    IF @SignOutOthers = 1
    BEGIN
        UPDATE dbo.CustomerSessions
        SET RevokedAt = GETUTCDATE()
        WHERE CustomerId = @CustomerId
          AND RevokedAt IS NULL;
    END

    SET @Success = 1;
END
GO
