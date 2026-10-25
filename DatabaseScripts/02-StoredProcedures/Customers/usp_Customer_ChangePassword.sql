CREATE OR ALTER PROCEDURE dbo.usp_Customer_ChangePassword
    @CustomerId INT,
    @NewPasswordHash NVARCHAR(500),
    @SignOutOthers BIT = 1,
    @Success BIT OUTPUT,
    @ErrorMessage NVARCHAR(400) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Success = 0;
    SET @ErrorMessage = NULL;

    UPDATE dbo.Customers
    SET PasswordHash = @NewPasswordHash,
        UpdatedAt = GETUTCDATE()
    WHERE Id = @CustomerId
      AND IsDeleted = 0;

    IF @@ROWCOUNT = 0
    BEGIN
        SET @ErrorMessage = 'Customer account not found.';
        RETURN;
    END

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
