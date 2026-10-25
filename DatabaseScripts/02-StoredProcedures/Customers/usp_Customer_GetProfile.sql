CREATE OR ALTER PROCEDURE dbo.usp_Customer_GetProfile
    @CustomerId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        Id,
        FullName,
        Email,
        Phone,
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
        LastOrderOn,
        RewardPointBalance,
        RewardTier,
        RegisteredOn,
        LastLoginOn,
        CreatedAt,
        UpdatedAt,
        IsActive
    FROM dbo.Customers
    WHERE Id = @CustomerId
      AND IsDeleted = 0;
END
GO
