SET NOCOUNT ON;
GO

/* =============================================================================
   dbo.usp_Settings_GetStorefrontConfig
   Returns active storefront-relevant settings for customer portal.
   ============================================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_Settings_GetStorefrontConfig
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  s.Section,
            s.SettingKey,
            s.SettingValue
    FROM    dbo.Settings s
    WHERE   s.IsDeleted = 0
      AND   s.IsActive = 1
      AND   s.Section IN ('contact', 'storefront', 'shipping', 'tax', 'orders', 'security');
END
GO
