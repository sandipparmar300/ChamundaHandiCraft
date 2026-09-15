/* =============================================================================
   2026-08-12_02_ContentVersioning.sql
   -----------------------------------------------------------------------------
   Adds version history for CMS pages.

   Why this was missing
   --------------------
   The first pass treated content versioning as a future enhancement. Re-reading
   the specs, it is not:

     CMS.txt §19  "Version History - Every page stores Previous Versions,
                   Published Versions, Draft Versions.
                   Actions: Compare Versions, Restore Version, View Changes"
     CMS.txt §21  BUSINESS RULE: "Version history must be retained for all
                   content updates."
     CMS.txt §25  Acceptance: "Version history enables rollback to previous
                   content."
     Static Pages.txt §14  "Static pages should support version history."

   That is a stated business rule and an acceptance criterion, not a roadmap
   item. dbo.CmsPages holds only the current body, so an edit was destroying the
   previous text with no way back.

   Design
   ------
   One row per saved revision, holding the full body rather than a diff. Legal
   pages are the whole point of this feature - a privacy policy that was live on
   a given date must be reproducible exactly, and reconstructing it by replaying
   diffs is a liability. CMS pages are small and edited rarely, so full copies
   cost almost nothing.

   Blog post versioning is deliberately NOT added: Blog.txt §23 lists "Version
   history and rollback" under Enterprise Features (future), unlike CMS.txt
   where it is a business rule.
   ============================================================================= */

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.CmsPageVersions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CmsPageVersions
    (
        Id              BIGINT          IDENTITY(1,1) NOT NULL,
        CmsPageId       INT             NOT NULL,
        /* Monotonic per page, starting at 1. Assigned by the service inside the
           same transaction as the page update. */
        VersionNumber   INT             NOT NULL,

        /* Full snapshot of everything an editor can change. */
        Title           NVARCHAR(300)   NOT NULL,
        Slug            VARCHAR(300)    NOT NULL,
        BodyHtml        NVARCHAR(MAX)   NULL,
        Template        NVARCHAR(100)   NULL,
        /* SEO for this route at the time, copied from dbo.SeoMetas so a restore
           puts the metadata back too. */
        MetaTitle       NVARCHAR(300)   NULL,
        MetaDescription NVARCHAR(500)   NULL,

        /* ContentStatus the page held when this revision was saved. */
        Status          TINYINT         NOT NULL CONSTRAINT DF_CmsPageVersions_Status DEFAULT (0),
        /* True for the revision that was live. Lets "compare against published"
           work without guessing which row that was. */
        WasPublished    BIT             NOT NULL CONSTRAINT DF_CmsPageVersions_WasPublished DEFAULT (0),
        PublishedOn     DATETIME2(3)    NULL,

        /* CMS.txt §19 "View Changes" - the editor's note for this revision. */
        ChangeNote      NVARCHAR(500)   NULL,
        /* Set when this revision was created by restoring an older one, so the
           audit trail shows a rollback rather than an ordinary edit. */
        RestoredFromVersion INT         NULL,

        CreatedAt       DATETIME2(3)    NOT NULL CONSTRAINT DF_CmsPageVersions_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy       INT             NULL,
        CreatedByName   NVARCHAR(200)   NULL,

        CONSTRAINT PK_CmsPageVersions PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_CmsPageVersions_CmsPages FOREIGN KEY (CmsPageId) REFERENCES dbo.CmsPages (Id),
        CONSTRAINT CK_CmsPageVersions_VersionNumber CHECK (VersionNumber > 0)
    );

    /* One row per (page, version). Also the "next version number" lookup. */
    CREATE UNIQUE INDEX UX_CmsPageVersions_PageVersion
        ON dbo.CmsPageVersions (CmsPageId, VersionNumber DESC);

    /* The history panel: newest first for one page. */
    CREATE INDEX IX_CmsPageVersions_Page
        ON dbo.CmsPageVersions (CmsPageId, CreatedAt DESC)
        INCLUDE (VersionNumber, Title, Status, WasPublished, CreatedByName, ChangeNote);

    /* "What was live on this date?" - the legal-compliance query. */
    CREATE INDEX IX_CmsPageVersions_Published
        ON dbo.CmsPageVersions (CmsPageId, PublishedOn DESC)
        WHERE WasPublished = 1;
END
GO

/* -----------------------------------------------------------------------------
   Seed version 1 for any page that already exists, so history is never empty
   and a restore always has a floor. Idempotent: only inserts where the page has
   no versions at all.
   ----------------------------------------------------------------------------- */
INSERT INTO dbo.CmsPageVersions
    (CmsPageId, VersionNumber, Title, Slug, BodyHtml, Template,
     Status, WasPublished, PublishedOn, ChangeNote, CreatedAt, CreatedBy, CreatedByName)
SELECT  p.Id,
        1,
        p.Title,
        p.Slug,
        p.BodyHtml,
        p.Template,
        p.Status,
        CASE WHEN p.Status = 1 THEN 1 ELSE 0 END,
        p.PublishedOn,
        N'Initial version captured when content versioning was introduced.',
        ISNULL(p.UpdatedAt, p.CreatedAt),
        ISNULL(p.UpdatedBy, p.CreatedBy),
        NULL
FROM    dbo.CmsPages AS p
WHERE   p.IsDeleted = 0
  AND   NOT EXISTS (SELECT 1 FROM dbo.CmsPageVersions AS v WHERE v.CmsPageId = p.Id);
GO
