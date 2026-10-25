CREATE OR ALTER PROCEDURE dbo.usp_Customer_Authenticate
    @Identifier NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    SET @Identifier = LTRIM(RTRIM(@Identifier));

    SELECT TOP 1
        Id,
        FullName,
        Email,
        Phone,
        PasswordHash,
        EmailVerified,
        MobileVerified,
        Gender,
        DateOfBirth,
        AvatarUrl,
        Gstin,
        Status,
        BlockedReason,
        OrderCount,
        LifetimeValue,
        RewardPointBalance,
        RewardTier,
        RegisteredOn,
        LastLoginOn,
        IsActive,
        IsDeleted
    FROM dbo.Customers
    WHERE (Email = LOWER(@Identifier) OR Phone = @Identifier)
      AND IsDeleted = 0;
END
GO
