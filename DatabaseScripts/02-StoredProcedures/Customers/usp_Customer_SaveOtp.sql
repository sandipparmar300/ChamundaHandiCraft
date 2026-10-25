CREATE OR ALTER PROCEDURE dbo.usp_Customer_SaveOtp
    @Destination NVARCHAR(256),
    @Channel TINYINT, -- 0 = Email, 1 = SMS
    @Purpose VARCHAR(48),
    @CodeHash CHAR(64),
    @ExpiresAt DATETIME2
AS
BEGIN
    SET NOCOUNT ON;

    -- Invalidate older unconsumed OTPs for same destination and purpose
    UPDATE dbo.CustomerOtps
    SET ConsumedAt = GETUTCDATE()
    WHERE Destination = @Destination
      AND Purpose = @Purpose
      AND ConsumedAt IS NULL;

    -- Insert new OTP
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
        @Purpose,
        @CodeHash,
        @ExpiresAt,
        0,
        GETUTCDATE()
    );
END
GO
