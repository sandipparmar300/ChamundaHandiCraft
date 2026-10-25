-- Seed Customer Email Templates into dbo.NotificationTemplates
IF NOT EXISTS (SELECT 1 FROM dbo.NotificationTemplates WHERE TemplateCode = 'CustomerPasswordReset')
BEGIN
    INSERT INTO dbo.NotificationTemplates
    (
        TemplateCode,
        Name,
        Channel,
        Category,
        Subject,
        PreviewText,
        BodyText,
        BodyHtml,
        LanguageCode,
        IsSystem,
        CreatedAt,
        IsActive,
        IsDeleted
    )
    VALUES
    (
        'CustomerPasswordReset',
        'Customer Password Reset Email',
        0, -- Email
        'Auth',
        'Reset Your Password — {{CompanyName}}',
        'Follow this link to reset your password.',
        'Hello {{RecipientName}}, Click here to reset your password: {{ResetUrl}}',
        NULL, -- Falls back to file or reads from file
        'en',
        1,
        GETUTCDATE(),
        1,
        0
    );
END

IF NOT EXISTS (SELECT 1 FROM dbo.NotificationTemplates WHERE TemplateCode = 'CustomerWelcome')
BEGIN
    INSERT INTO dbo.NotificationTemplates
    (
        TemplateCode,
        Name,
        Channel,
        Category,
        Subject,
        PreviewText,
        BodyText,
        BodyHtml,
        LanguageCode,
        IsSystem,
        CreatedAt,
        IsActive,
        IsDeleted
    )
    VALUES
    (
        'CustomerWelcome',
        'Customer Onboarding Welcome Email',
        0, -- Email
        'Auth',
        'Welcome to {{CompanyName}} — 50 Welcome Points Inside!',
        'Welcome to Chamunda Handicraft! 50 points have been credited to your balance.',
        'Welcome to {{CompanyName}}, {{RecipientName}}! We have credited {{RewardPoints}} points to your account.',
        NULL, -- Falls back to file or reads from file
        'en',
        1,
        GETUTCDATE(),
        1,
        0
    );
END
GO
