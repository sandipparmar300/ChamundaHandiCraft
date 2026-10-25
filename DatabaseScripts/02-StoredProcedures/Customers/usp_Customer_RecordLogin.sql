CREATE OR ALTER PROCEDURE dbo.usp_Customer_RecordLogin
    @CustomerId INT,
    @IpAddress VARCHAR(64) = NULL,
    @UserAgent NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Customers
    SET LastLoginOn = GETUTCDATE(),
        UpdatedAt = GETUTCDATE()
    WHERE Id = @CustomerId;

    -- Record session if needed
    IF @CustomerId > 0
    BEGIN
        INSERT INTO dbo.CustomerSessions
        (
            CustomerId,
            RefreshTokenHash,
            IssuedAt,
            ExpiresAt,
            IpAddress,
            UserAgent
        )
        VALUES
        (
            @CustomerId,
            CONVERT(CHAR(64), HASHBYTES('SHA2_256', CONCAT(@CustomerId, '|', GETUTCDATE(), '|', NEWID())), 2),
            GETUTCDATE(),
            DATEADD(DAY, 30, GETUTCDATE()),
            @IpAddress,
            @UserAgent
        );
    END
END
GO
