/* =============================================================================
   usp_AdminUser_RecordLoginAttempt
   -----------------------------------------------------------------------------
   Logs every sign-in attempt into dbo.LoginHistories and updates lockout /
   last-login status on dbo.AdminUsers.
   ============================================================================= */

SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_AdminUser_RecordLoginAttempt
    @AdminUserId        INT             = NULL,
    @AttemptedEmail     NVARCHAR(256)   = NULL,
    @IsSuccess          BIT,
    @FailureReason      NVARCHAR(200)   = NULL,
    @IpAddress          VARCHAR(64)     = NULL,
    @UserAgent          NVARCHAR(500)   = NULL,
    @MaxFailedAttempts  INT             = 5,
    @LockoutMinutes     INT             = 15
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Insert history record
    INSERT INTO dbo.LoginHistories
    (
        AdminUserId,
        AttemptedEmail,
        IsSuccess,
        FailureReason,
        IpAddress,
        UserAgent,
        AttemptedAt
    )
    VALUES
    (
        @AdminUserId,
        @AttemptedEmail,
        @IsSuccess,
        @FailureReason,
        @IpAddress,
        @UserAgent,
        SYSUTCDATETIME()
    );

    -- 2. Update AdminUser status if user exists
    IF @AdminUserId IS NOT NULL AND EXISTS (SELECT 1 FROM dbo.AdminUsers WHERE Id = @AdminUserId)
    BEGIN
        IF @IsSuccess = 1
        BEGIN
            UPDATE dbo.AdminUsers
            SET FailedLoginCount = 0,
                LockedOutUntil   = NULL,
                LastLoginOn      = SYSUTCDATETIME(),
                LastLoginIp      = @IpAddress
            WHERE Id = @AdminUserId;
        END
        ELSE
        BEGIN
            UPDATE dbo.AdminUsers
            SET FailedLoginCount = FailedLoginCount + 1,
                LockedOutUntil   = CASE 
                                     WHEN FailedLoginCount + 1 >= @MaxFailedAttempts 
                                     THEN DATEADD(MINUTE, @LockoutMinutes, SYSUTCDATETIME()) 
                                     ELSE LockedOutUntil 
                                   END
            WHERE Id = @AdminUserId;
        END
    END
END
GO
