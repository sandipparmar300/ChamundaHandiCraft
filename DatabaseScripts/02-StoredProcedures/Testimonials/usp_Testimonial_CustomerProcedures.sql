SET NOCOUNT ON;
GO

/* =============================================================================
   dbo.usp_Testimonial_GetFeatured
   Returns approved testimonials for storefront display.
   ============================================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_Testimonial_GetFeatured
    @Count INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Count)
            t.Id,
            t.CustomerName,
            t.Location,
            t.Quote,
            t.Rating,
            t.PhotoUrl,
            t.ShowOnHome,
            t.SortOrder,
            t.Status,
            t.CreatedAt,
            t.IsActive
    FROM    dbo.Testimonials t
    WHERE   t.IsDeleted = 0
      AND   t.IsActive = 1
      AND   t.Status = 2  -- Published / Approved
    ORDER BY t.ShowOnHome DESC, t.SortOrder ASC, t.CreatedAt DESC;
END
GO
