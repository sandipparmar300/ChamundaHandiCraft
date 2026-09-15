/* =============================================================================
   usp_Review_RecalculateProductRating
   -----------------------------------------------------------------------------
   Rebuilds the rating figures a product page renders.

   Specs:
     Review.txt §18  "Average product ratings update automatically after approval."
     Review.txt §8   the five-bar rating distribution
     Product Detail.txt §8  average, distribution and verified-purchase share

   Writes to two places, both caches of dbo.Reviews:
     dbo.Products.AverageRating / ReviewCount  - already existed, used by the
       product grid, PLP sorting and the "Highest Rated" sort option.
     dbo.ProductRatingSummaries                - the histogram, added in
       15_Reviews.sql because a GROUP BY per PDP view does not scale.

   Only Status = 1 (Approved) counts. A pending or rejected review must never
   move the number a shopper sees.

   Call after: approve, reject, hide, restore, edit-rating, delete. Cheap enough
   to call unconditionally; @ProductId NULL rebuilds everything (recovery path).
   ============================================================================= */

SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Review_RecalculateProductRating
    @ProductId  INT = NULL      -- NULL = rebuild every product
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        /* Aggregate once into a temp table, then drive both writes from it -
           two passes over Reviews would be wasteful and could disagree if a
           review were approved between them. */
        CREATE TABLE #Agg
        (
            ProductId       INT             NOT NULL PRIMARY KEY,
            ReviewCount     INT             NOT NULL,
            AverageRating   DECIMAL(18,4)   NOT NULL,
            VerifiedCount   INT             NOT NULL,
            Star1Count      INT             NOT NULL,
            Star2Count      INT             NOT NULL,
            Star3Count      INT             NOT NULL,
            Star4Count      INT             NOT NULL,
            Star5Count      INT             NOT NULL,
            RecommendCount  INT             NOT NULL,
            LastReviewOn    DATETIME2(3)    NULL
        );

        INSERT INTO #Agg
        (
            ProductId, ReviewCount, AverageRating, VerifiedCount,
            Star1Count, Star2Count, Star3Count, Star4Count, Star5Count,
            RecommendCount, LastReviewOn
        )
        SELECT
            r.ProductId,
            COUNT(*),
            ROUND(AVG(CAST(r.Rating AS DECIMAL(18,4))), 4),
            SUM(CASE WHEN r.IsVerifiedPurchase = 1 THEN 1 ELSE 0 END),
            SUM(CASE WHEN r.Rating = 1 THEN 1 ELSE 0 END),
            SUM(CASE WHEN r.Rating = 2 THEN 1 ELSE 0 END),
            SUM(CASE WHEN r.Rating = 3 THEN 1 ELSE 0 END),
            SUM(CASE WHEN r.Rating = 4 THEN 1 ELSE 0 END),
            SUM(CASE WHEN r.Rating = 5 THEN 1 ELSE 0 END),
            SUM(CASE WHEN r.RecommendsProduct = 1 THEN 1 ELSE 0 END),
            MAX(r.SubmittedOn)
        FROM   dbo.Reviews AS r
        WHERE  r.Status = 1                       -- Approved only
          AND  r.IsDeleted = 0
          AND  (@ProductId IS NULL OR r.ProductId = @ProductId)
        GROUP  BY r.ProductId;

        /* ------------------------------------------------------------------
           Products with approved reviews.
           ------------------------------------------------------------------ */
        MERGE dbo.ProductRatingSummaries AS tgt
        USING #Agg AS src
           ON tgt.ProductId = src.ProductId
        WHEN MATCHED THEN
            UPDATE SET
                AverageRating  = src.AverageRating,
                ReviewCount    = src.ReviewCount,
                VerifiedCount  = src.VerifiedCount,
                Star1Count     = src.Star1Count,
                Star2Count     = src.Star2Count,
                Star3Count     = src.Star3Count,
                Star4Count     = src.Star4Count,
                Star5Count     = src.Star5Count,
                RecommendCount = src.RecommendCount,
                LastReviewOn   = src.LastReviewOn,
                RecalculatedAt = SYSUTCDATETIME()
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (ProductId, AverageRating, ReviewCount, VerifiedCount,
                    Star1Count, Star2Count, Star3Count, Star4Count, Star5Count,
                    RecommendCount, LastReviewOn, RecalculatedAt)
            VALUES (src.ProductId, src.AverageRating, src.ReviewCount, src.VerifiedCount,
                    src.Star1Count, src.Star2Count, src.Star3Count, src.Star4Count, src.Star5Count,
                    src.RecommendCount, src.LastReviewOn, SYSUTCDATETIME());

        UPDATE p
        SET    p.AverageRating = a.AverageRating,
               p.ReviewCount   = a.ReviewCount,
               p.UpdatedAt     = SYSUTCDATETIME()
        FROM   dbo.Products AS p
        JOIN   #Agg AS a ON a.ProductId = p.Id;

        /* ------------------------------------------------------------------
           Products whose last approved review has just gone away. Without this
           a product that had its only review rejected would keep showing 5.0.
           ------------------------------------------------------------------ */
        UPDATE s
        SET    s.AverageRating  = 0,
               s.ReviewCount    = 0,
               s.VerifiedCount  = 0,
               s.Star1Count     = 0,
               s.Star2Count     = 0,
               s.Star3Count     = 0,
               s.Star4Count     = 0,
               s.Star5Count     = 0,
               s.RecommendCount = 0,
               s.LastReviewOn   = NULL,
               s.RecalculatedAt = SYSUTCDATETIME()
        FROM   dbo.ProductRatingSummaries AS s
        WHERE  NOT EXISTS (SELECT 1 FROM #Agg AS a WHERE a.ProductId = s.ProductId)
          AND  (@ProductId IS NULL OR s.ProductId = @ProductId);

        UPDATE p
        SET    p.AverageRating = 0,
               p.ReviewCount   = 0,
               p.UpdatedAt     = SYSUTCDATETIME()
        FROM   dbo.Products AS p
        WHERE  NOT EXISTS (SELECT 1 FROM #Agg AS a WHERE a.ProductId = p.Id)
          AND  (@ProductId IS NULL OR p.Id = @ProductId)
          AND  (p.ReviewCount <> 0 OR p.AverageRating <> 0);

        DROP TABLE #Agg;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
