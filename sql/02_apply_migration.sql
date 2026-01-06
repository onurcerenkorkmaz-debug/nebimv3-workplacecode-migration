/*
    02_apply_migration.sql
    ----------------------
    Purpose:
      - Inserts missing WorkplaceCode master records (cdWorkplace, cdWorkplaceDesc)
      - Applies WorkplaceCode migration (Old -> New) across dependent tables
      - Runs safely within TRY/CATCH + TRANSACTION

    Notes:
      - Replace placeholders (NEW_CODE / OLD_CODE, descriptions, etc.)
      - Paste/append the generated UPDATE statements (from 01_generate_updates.sql output)
        into the marked section below.

    Safety:
      - Always test in a non-production environment first.
      - Take backup before running in production.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

--------------------------------------------------------------------------------
-- 0) Parameters (CHANGE THESE)
--------------------------------------------------------------------------------
DECLARE @OldWorkplaceCode NVARCHAR(20) = N'OLD_CODE';
DECLARE @NewWorkplaceCode NVARCHAR(20) = N'NEW_CODE';

-- Optional: master data attributes for the NEW workplace (adjust as needed)
DECLARE @NewWorkplaceTypeCode NVARCHAR(10) = N'';   -- example placeholder
DECLARE @NewWorkplaceDesc_TR  NVARCHAR(250) = N'New Workplace (TR)'; 
DECLARE @NewWorkplaceDesc_EN  NVARCHAR(250) = N'New Workplace (EN)';

--------------------------------------------------------------------------------
-- 1) Pre-checks (recommended)
--------------------------------------------------------------------------------
IF @OldWorkplaceCode IS NULL OR LTRIM(RTRIM(@OldWorkplaceCode)) = N''
BEGIN
    RAISERROR('OldWorkplaceCode cannot be empty.', 16, 1);
    RETURN;
END;

IF @NewWorkplaceCode IS NULL OR LTRIM(RTRIM(@NewWorkplaceCode)) = N''
BEGIN
    RAISERROR('NewWorkplaceCode cannot be empty.', 16, 1);
    RETURN;
END;

IF @OldWorkplaceCode = @NewWorkplaceCode
BEGIN
    RAISERROR('OldWorkplaceCode and NewWorkplaceCode cannot be the same.', 16, 1);
    RETURN;
END;

--------------------------------------------------------------------------------
-- 2) Transactional apply
--------------------------------------------------------------------------------
BEGIN TRY
    BEGIN TRANSACTION;

    --------------------------------------------------------------------------
    -- 2.1) Ensure NEW Workplace exists in master tables
    --      (Column list may differ by environment; adjust to your schema)
    --------------------------------------------------------------------------

    -- cdWorkplace: create NEW workplace record if missing
    IF NOT EXISTS (SELECT 1 FROM dbo.cdWorkplace WITH (UPDLOCK, HOLDLOCK) WHERE WorkplaceCode = @NewWorkplaceCode)
    BEGIN
        INSERT INTO dbo.cdWorkplace
        (
            WorkplaceCode,
            WorkplaceTypeCode,
            CreatedDate,
            UpdatedDate
            -- Add required columns here if your schema requires them
        )
        VALUES
        (
            @NewWorkplaceCode,
            NULLIF(@NewWorkplaceTypeCode, N''),
            GETDATE(),
            GETDATE()
        );
    END

    -- cdWorkplaceDesc: insert TR/EN descriptions if missing (optional but nice)
    -- Adjust language codes and columns to your environment.
    IF NOT EXISTS (SELECT 1 FROM dbo.cdWorkplaceDesc WITH (UPDLOCK, HOLDLOCK) WHERE WorkplaceCode = @NewWorkplaceCode AND LangCode = N'TR')
    BEGIN
        INSERT INTO dbo.cdWorkplaceDesc (WorkplaceCode, LangCode, WorkplaceDescription, CreatedDate, UpdatedDate)
        VALUES (@NewWorkplaceCode, N'TR', @NewWorkplaceDesc_TR, GETDATE(), GETDATE());
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.cdWorkplaceDesc WITH (UPDLOCK, HOLDLOCK) WHERE WorkplaceCode = @NewWorkplaceCode AND LangCode = N'EN')
    BEGIN
        INSERT INTO dbo.cdWorkplaceDesc (WorkplaceCode, LangCode, WorkplaceDescription, CreatedDate, UpdatedDate)
        VALUES (@NewWorkplaceCode, N'EN', @NewWorkplaceDesc_EN, GETDATE(), GETDATE());
    END

    --------------------------------------------------------------------------
    -- 2.2) Apply updates across dependent tables
    --      Paste the generated UPDATE statements from 01_generate_updates.sql
    --      output below (or write your curated updates).
    --------------------------------------------------------------------------

    /*
        === PASTE GENERATED UPDATES BELOW ===

        Example pattern (replace Table/Column accordingly):
        UPDATE dbo.SomeTable
        SET WorkplaceCode = @NewWorkplaceCode
        WHERE WorkplaceCode = @OldWorkplaceCode;

        === PASTE GENERATED UPDATES ABOVE ===
    */

    --------------------------------------------------------------------------
    -- 2.3) Optional: if you want to block leaving OLD code in master tables,
    --      you may KEEP or REMOVE old workplace records depending on policy.
    --      Typically, do NOT delete old master data automatically.
    --------------------------------------------------------------------------

    COMMIT TRANSACTION;

    PRINT 'WorkplaceCode migration completed successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrState INT = ERROR_STATE();

    RAISERROR(@ErrMsg, @ErrSeverity, @ErrState);
END CATCH;
