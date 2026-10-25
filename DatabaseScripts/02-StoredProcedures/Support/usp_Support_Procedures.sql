/* =============================================================================
   usp_Support_Procedures.sql
   Stored procedures for Support Tickets:
     1. dbo.usp_SupportTicket_GridList
     2. dbo.usp_SupportTicket_GetById
     3. dbo.usp_SupportTicket_Save
     4. dbo.usp_SupportTicket_Delete
     5. dbo.usp_SupportTicket_UpdateStatus
   ============================================================================= */

SET NOCOUNT ON;
GO

/* 1. GridList */
CREATE OR ALTER PROCEDURE dbo.usp_SupportTicket_GridList
    @SearchText           NVARCHAR(200)   = NULL,
    @IsActive             BIT             = NULL,
    @SortColumn           VARCHAR(64)     = 'CreatedAt',
    @SortOrder            VARCHAR(4)      = 'DESC',
    @PageSize             INT             = 25,
    @PageIndex            INT             = 1,
    @TotalRecords         INT             OUTPUT,
    @TotalFilteredRecords INT             OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @PageSize  IS NULL OR @PageSize  < 1 SET @PageSize  = 25;
    IF @PageIndex IS NULL OR @PageIndex < 1 SET @PageIndex = 1;
    IF @SortOrder IS NULL OR @SortOrder NOT IN ('ASC','DESC') SET @SortOrder = 'DESC';
    SET @SearchText = NULLIF(LTRIM(RTRIM(ISNULL(@SearchText, N''))), N'');

    SELECT @TotalRecords = COUNT(*) FROM dbo.SupportTickets WHERE IsDeleted = 0;

    ;WITH Filtered AS
    (
        SELECT
            t.Id,
            t.TicketNumber,
            t.Subject,
            Topic = ISNULL(t.Source, N'General Query'),
            CustomerName = t.RequesterName,
            RequesterEmail = t.RequesterEmail,
            RequesterPhone = t.RequesterPhone,
            OrderNumber = CASE WHEN t.OrderId IS NOT NULL THEN N'ORD-' + CAST(t.OrderId AS NVARCHAR(20)) ELSE NULL END,
            t.Status,
            Priority = CASE t.Priority
                WHEN 1 THEN 'Low'
                WHEN 3 THEN 'High'
                WHEN 4 THEN 'Urgent'
                ELSE 'Normal' END,
            AssignedTo = t.AssignedToName,
            OpenedOn = t.SubmittedOn,
            LastReplyOn = t.LastMessageOn,
            t.MessageCount,
            t.CreatedAt,
            t.UpdatedAt,
            t.IsActive
        FROM dbo.SupportTickets t
        WHERE t.IsDeleted = 0
          AND (@IsActive IS NULL OR t.IsActive = @IsActive)
          AND (@SearchText IS NULL
               OR t.TicketNumber LIKE N'%' + @SearchText + N'%'
               OR t.Subject LIKE N'%' + @SearchText + N'%'
               OR t.RequesterName LIKE N'%' + @SearchText + N'%'
               OR t.RequesterEmail LIKE N'%' + @SearchText + N'%'
               OR t.AssignedToName LIKE N'%' + @SearchText + N'%')
    )
    SELECT @TotalFilteredRecords = COUNT(*) FROM Filtered;

    ;WITH Filtered AS
    (
        SELECT
            t.Id,
            t.TicketNumber,
            t.Subject,
            Topic = ISNULL(t.Source, N'General Query'),
            CustomerName = t.RequesterName,
            RequesterEmail = t.RequesterEmail,
            RequesterPhone = t.RequesterPhone,
            OrderNumber = CASE WHEN t.OrderId IS NOT NULL THEN N'ORD-' + CAST(t.OrderId AS NVARCHAR(20)) ELSE NULL END,
            t.Status,
            Priority = CASE t.Priority
                WHEN 1 THEN 'Low'
                WHEN 3 THEN 'High'
                WHEN 4 THEN 'Urgent'
                ELSE 'Normal' END,
            AssignedTo = t.AssignedToName,
            OpenedOn = t.SubmittedOn,
            LastReplyOn = t.LastMessageOn,
            t.MessageCount,
            t.CreatedAt,
            t.UpdatedAt,
            t.IsActive
        FROM dbo.SupportTickets t
        WHERE t.IsDeleted = 0
          AND (@IsActive IS NULL OR t.IsActive = @IsActive)
          AND (@SearchText IS NULL
               OR t.TicketNumber LIKE N'%' + @SearchText + N'%'
               OR t.Subject LIKE N'%' + @SearchText + N'%'
               OR t.RequesterName LIKE N'%' + @SearchText + N'%'
               OR t.RequesterEmail LIKE N'%' + @SearchText + N'%'
               OR t.AssignedToName LIKE N'%' + @SearchText + N'%')
    )
    SELECT *
    FROM Filtered
    ORDER BY
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'TicketNumber' THEN TicketNumber END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'TicketNumber' THEN TicketNumber END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'CustomerName' THEN CustomerName END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'CustomerName' THEN CustomerName END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'Subject'      THEN Subject END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'Subject'      THEN Subject END DESC,
        CASE WHEN @SortOrder = 'ASC'  AND @SortColumn = 'CreatedAt'    THEN CreatedAt END ASC,
        CASE WHEN @SortOrder = 'DESC' AND @SortColumn = 'CreatedAt'    THEN CreatedAt END DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO

/* 2. GetById */
CREATE OR ALTER PROCEDURE dbo.usp_SupportTicket_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        t.Id,
        t.TicketNumber,
        t.Subject,
        Topic = ISNULL(t.Source, N'General Query'),
        CustomerName = t.RequesterName,
        RequesterName = t.RequesterName,
        RequesterEmail = t.RequesterEmail,
        RequesterPhone = t.RequesterPhone,
        Description = t.Description,
        OrderNumber = CASE WHEN t.OrderId IS NOT NULL THEN N'ORD-' + CAST(t.OrderId AS NVARCHAR(20)) ELSE NULL END,
        OrderId = t.OrderId,
        t.Status,
        Priority = CASE t.Priority
            WHEN 1 THEN 'Low'
            WHEN 3 THEN 'High'
            WHEN 4 THEN 'Urgent'
            ELSE 'Normal' END,
        PriorityValue = t.Priority,
        AssignedTo = t.AssignedToName,
        OpenedOn = t.SubmittedOn,
        LastReplyOn = t.LastMessageOn,
        t.MessageCount,
        t.ResolutionNote,
        t.CreatedAt,
        t.UpdatedAt,
        t.IsActive
    FROM dbo.SupportTickets t
    WHERE t.Id = @Id AND t.IsDeleted = 0;
END
GO

/* 3. Save (Insert / Update) */
CREATE OR ALTER PROCEDURE dbo.usp_SupportTicket_Save
    @Id             INT             = 0,
    @TicketNumber   VARCHAR(50)     = NULL,
    @CustomerName   NVARCHAR(200)   = NULL,
    @RequesterName  NVARCHAR(200)   = NULL,
    @RequesterEmail NVARCHAR(256)   = NULL,
    @RequesterPhone VARCHAR(24)     = NULL,
    @Subject        NVARCHAR(500),
    @Topic          NVARCHAR(100)   = NULL,
    @Description    NVARCHAR(MAX)   = NULL,
    @Status         TINYINT         = 0,
    @Priority       VARCHAR(30)     = 'Normal',
    @AssignedTo     NVARCHAR(200)   = NULL,
    @OrderNumber    NVARCHAR(50)    = NULL,
    @IsActive       BIT             = 1,
    @LoggedInUserId INT             = NULL,
    @NewId          INT             OUTPUT,
    @ErrorMessage   NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    SET @Subject = LTRIM(RTRIM(ISNULL(@Subject, N'')));
    IF @Subject = N''
    BEGIN
        SET @ErrorMessage = N'Ticket Subject is required.';
        RETURN;
    END

    -- Resolve customer/requester name
    DECLARE @ActualName NVARCHAR(200) = COALESCE(NULLIF(LTRIM(RTRIM(@CustomerName)), N''), NULLIF(LTRIM(RTRIM(@RequesterName)), N''), N'Guest Customer');
    DECLARE @ActualDesc NVARCHAR(MAX) = COALESCE(NULLIF(LTRIM(RTRIM(@Description)), N''), @Subject);

    -- Priority map
    DECLARE @PriorityVal TINYINT = 2; -- Normal
    IF @Priority = '1' OR UPPER(@Priority) = 'LOW' SET @PriorityVal = 1;
    ELSE IF @Priority = '3' OR UPPER(@Priority) = 'HIGH' SET @PriorityVal = 3;
    ELSE IF @Priority = '4' OR UPPER(@Priority) = 'URGENT' SET @PriorityVal = 4;

    -- Ticket Number auto generate if blank
    SET @TicketNumber = NULLIF(LTRIM(RTRIM(@TicketNumber)), '');
    IF @TicketNumber IS NULL
    BEGIN
        SET @TicketNumber = 'TCK-' + FORMAT(SYSUTCDATETIME(), 'yyyyMMdd') + '-' + RIGHT(CAST(ABS(CHECKSUM(NEWID())) AS VARCHAR(10)), 4);
    END

    IF @Id = 0
    BEGIN
        INSERT INTO dbo.SupportTickets
        (
            TicketNumber, RequesterName, RequesterEmail, RequesterPhone,
            Subject, Description, Status, Priority, AssignedToName,
            Source, SubmittedOn, MessageCount, CreatedAt, CreatedBy,
            IsActive, IsDeleted
        )
        VALUES
        (
            @TicketNumber, @ActualName, @RequesterEmail, @RequesterPhone,
            @Subject, @ActualDesc, @Status, @PriorityVal, @AssignedTo,
            ISNULL(@Topic, 'Portal'), SYSUTCDATETIME(), 1, SYSUTCDATETIME(), @LoggedInUserId,
            @IsActive, 0
        );

        SET @NewId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.SupportTickets
        SET
            TicketNumber = ISNULL(@TicketNumber, TicketNumber),
            RequesterName = @ActualName,
            RequesterEmail = COALESCE(@RequesterEmail, RequesterEmail),
            RequesterPhone = COALESCE(@RequesterPhone, RequesterPhone),
            Subject = @Subject,
            Description = @ActualDesc,
            Status = @Status,
            Priority = @PriorityVal,
            AssignedToName = @AssignedTo,
            Source = COALESCE(@Topic, Source),
            IsActive = @IsActive,
            UpdatedAt = SYSUTCDATETIME(),
            UpdatedBy = @LoggedInUserId
        WHERE Id = @Id AND IsDeleted = 0;

        SET @NewId = @Id;
    END
END
GO

/* 4. Delete */
CREATE OR ALTER PROCEDURE dbo.usp_SupportTicket_Delete
    @Id             INT,
    @LoggedInUserId INT           = NULL,
    @Success        BIT           OUTPUT,
    @ErrorMessage   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Success = 0;
    SET @ErrorMessage = NULL;

    IF NOT EXISTS (SELECT 1 FROM dbo.SupportTickets WHERE Id = @Id AND IsDeleted = 0)
    BEGIN
        SET @ErrorMessage = N'Support ticket not found.';
        RETURN;
    END

    UPDATE dbo.SupportTickets
    SET
        IsDeleted = 1,
        IsActive = 0,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @LoggedInUserId
    WHERE Id = @Id;

    SET @Success = 1;
END
GO

/* 5. UpdateStatus */
CREATE OR ALTER PROCEDURE dbo.usp_SupportTicket_UpdateStatus
    @Id             INT,
    @IsActive       BIT,
    @LoggedInUserId INT           = NULL,
    @Success        BIT           OUTPUT,
    @ErrorMessage   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Success = 0;
    SET @ErrorMessage = NULL;

    IF NOT EXISTS (SELECT 1 FROM dbo.SupportTickets WHERE Id = @Id AND IsDeleted = 0)
    BEGIN
        SET @ErrorMessage = N'Support ticket not found.';
        RETURN;
    END

    UPDATE dbo.SupportTickets
    SET
        IsActive = @IsActive,
        Status = CASE WHEN @IsActive = 1 THEN 0 ELSE 4 END, -- 0 = Open, 4 = Closed
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @LoggedInUserId
    WHERE Id = @Id AND IsDeleted = 0;

    SET @Success = 1;
END
GO
