/* ============================================================================
   04_NotificationTemplates_Seed.sql — Seeds system email notification templates
   ============================================================================ */

IF NOT EXISTS (SELECT 1 FROM dbo.NotificationTemplates WHERE TemplateCode = 'AdminPasswordReset' AND Channel = 0)
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
        VariablesJson,
        LanguageCode,
        IsSystem,
        IsActive,
        IsDeleted
    )
    VALUES
    (
        'AdminPasswordReset',
        N'Admin Password Reset Email',
        0, -- Email
        'Auth',
        N'Password Reset Request — {{CompanyName}}',
        N'Reset your Chamunda Handicraft Admin account password',
        N'Hello {{RecipientName}}, Click the link to reset your password: {{ResetUrl}} (valid for {{ExpirationMinutes}} minutes).',
        N'<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <meta name="subject" content="Password Reset Request — {{CompanyName}}" />
    <style>
        body { margin: 0; padding: 0; background-color: #f4f6f8; font-family: Segoe UI, Tahoma, sans-serif; color: #334155; }
        .wrapper { width: 100%; background-color: #f4f6f8; padding: 40px 0; }
        .main-container { max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; border: 1px solid #e2e8f0; }
        .brand-header { background-color: #8E1F2F; padding: 32px 24px; text-align: center; }
        .brand-logo-text { color: #ffffff; font-size: 24px; font-weight: 700; text-transform: uppercase; margin: 0; }
        .brand-logo-sub { color: #F3C969; font-size: 11px; font-weight: 600; letter-spacing: 2px; text-transform: uppercase; margin-top: 4px; }
        .content-body { padding: 40px 36px; line-height: 1.65; font-size: 15px; color: #334155; }
        .greeting { font-size: 18px; font-weight: 700; color: #0f172a; margin-bottom: 16px; }
        .btn-container { text-align: center; margin: 32px 0; }
        .action-button { background-color: #8E1F2F; color: #ffffff !important; padding: 14px 34px; border-radius: 8px; text-decoration: none; font-weight: 600; font-size: 15px; display: inline-block; }
        .url-card { background-color: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 14px 16px; word-break: break-all; font-size: 13px; color: #64748b; margin: 20px 0; }
        .security-notice { background-color: #fff1f2; border-left: 4px solid #e11d48; padding: 14px 18px; border-radius: 4px; font-size: 13px; color: #9f1239; margin-top: 28px; }
        .footer { background-color: #f8fafc; padding: 24px 36px; border-top: 1px solid #e2e8f0; font-size: 12px; color: #94a3b8; text-align: center; }
    </style>
</head>
<body>
    <div class="wrapper">
        <div class="main-container">
            <div class="brand-header">
                <div class="brand-logo-text">{{CompanyName}}</div>
                <div class="brand-logo-sub">Admin Portal</div>
            </div>
            <div class="content-body">
                <div class="greeting">Hello {{RecipientName}},</div>
                <p>We received a request to reset the password for your administrator account on <strong>{{CompanyName}}</strong>.</p>
                <p>Click the button below to choose a new password:</p>
                <div class="btn-container">
                    <a href="{{ResetUrl}}" class="action-button" target="_blank" rel="noopener noreferrer">Reset My Password</a>
                </div>
                <p style="font-size: 13px; color: #64748b;">If the button above does not work, copy and paste this link into your browser:</p>
                <div class="url-card"><a href="{{ResetUrl}}" style="color: #8E1F2F;">{{ResetUrl}}</a></div>
                <div class="security-notice">
                    <strong>Security Notice:</strong> This password reset link is single-use and will expire in <strong>{{ExpirationMinutes}} minutes</strong>. If you did not request this change, please ignore this email.
                </div>
            </div>
            <div class="footer">
                &copy; {{CurrentYear}} {{CompanyName}}. All rights reserved.<br />
                Support: <a href="mailto:{{SupportEmail}}" style="color: #64748b;">{{SupportEmail}}</a>
            </div>
        </div>
    </div>
</body>
</html>',
        N'["RecipientName", "CompanyName", "ResetUrl", "ExpirationMinutes", "CurrentYear", "SupportEmail"]',
        'en',
        1, -- IsSystem
        1, -- IsActive
        0  -- IsDeleted
    );
END
GO
