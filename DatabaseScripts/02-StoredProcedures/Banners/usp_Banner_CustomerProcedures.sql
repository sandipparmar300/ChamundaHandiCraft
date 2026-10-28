SET NOCOUNT ON;
GO

/* =============================================================================
   dbo.usp_Banner_GetByPlacement
   Returns active, scheduled banners for a specific placement (e.g. 0 = HomeHero).
   ============================================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_Banner_GetByPlacement
    @Placement INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  b.Id,
            b.Placement,
            b.Eyebrow,
            b.Heading,
            b.SubHeading,
            b.ImageUrl,
            b.MobileImageUrl,
            b.ImageAlt,
            b.PrimaryCtaLabel,
            b.PrimaryCtaUrl,
            b.SecondaryCtaLabel,
            b.SecondaryCtaUrl,
            b.SortOrder,
            b.Status,
            b.IsActive,
            b.StartsOn,
            b.EndsOn,
            b.ImpressionCount,
            b.ClickCount,
            b.CreatedAt,
            b.UpdatedAt
    FROM    dbo.Banners b
    WHERE   b.IsDeleted = 0
      AND   b.IsActive = 1
      AND   b.Placement = @Placement
      AND   (b.StartsOn IS NULL OR b.StartsOn <= GETDATE())
      AND   (b.EndsOn IS NULL OR b.EndsOn >= GETDATE())
    ORDER BY b.SortOrder ASC, b.Id ASC;
END
GO
