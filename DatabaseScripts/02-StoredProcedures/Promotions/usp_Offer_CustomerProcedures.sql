SET NOCOUNT ON;
GO

/* =============================================================================
   dbo.usp_Offer_GetFlashSale
   Returns active Flash Sale offer with server-anchored ends time.
   ============================================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_Offer_GetFlashSale
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
            o.Id,
            o.Name,
            o.OfferType,
            o.Description,
            o.DiscountPercent,
            o.StartsOn,
            o.EndsOn,
            o.IsActive
    FROM    dbo.Offers o
    WHERE   o.IsDeleted = 0
      AND   o.IsActive = 1
      AND   (o.OfferType = 'Flash Sale' OR o.OfferType = '0')
      AND   (o.StartsOn IS NULL OR o.StartsOn <= GETDATE())
      AND   (o.EndsOn IS NULL OR o.EndsOn >= GETDATE())
    ORDER BY o.EndsOn ASC;
END
GO
