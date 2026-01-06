/*
    03_validation.sql
    -----------------
    Purpose:
      Post-migration validation for WorkplaceCode (Old -> New).

    What it checks:
      1) Master tables contain the NEW code
      2) (Optional) OLD code still exists in master (policy dependent)
      3) Counts of OLD/NEW occurrences across commonly-used tables (customize list)
      4) Quick summary output for migration sign-off

    Notes:
      - Update the table list based on your environment.
      - Keep this file generic (no server names, no real codes).
*/

SET NOCOUNT ON;

--------------------------------------------------------------------------------
-- Parameters (CHANGE THESE to match 02_apply_migration.sql)
--------------------------------------------------------------------------------
DECLARE @OldWorkplaceCode NVARCHAR(20) = N'OLD_CODE';
DECLARE @NewWorkplaceCode NVARCHAR(20) = N'NEW_CODE';

--------------------------------------------------------------------------------
-- 1) Master data checks
--------------------------------------------------------------------------------
PRINT '=== Master table checks ===';

SELECT
    'cdWorkplace' AS TableName,
    @NewWorkplaceCode AS WorkplaceCode,
    CASE WHEN EXISTS (SELECT 1 FROM dbo.cdWorkplace WHERE WorkplaceCode = @NewWorkplaceCode)
         THEN 'OK'
         ELSE 'MISSING'
    END AS Status;

SELECT
    'cdWorkplaceDesc(TR)' AS TableName,
    @NewWorkplaceCode AS WorkplaceCode,
    CASE WHEN EXISTS (SELECT 1 FROM dbo.cdWorkplaceDesc WHERE WorkplaceCode = @NewWorkplaceCode AND LangCode = N'TR')
         THEN 'OK'
         ELSE 'MISSING'
    END AS Status;

SELECT
    'cdWorkplaceDesc(EN)' AS TableName,
    @NewWorkplaceCode AS WorkplaceCode,
    CASE WHEN EXISTS (SELECT 1 FROM dbo.cdWorkplaceDesc WHERE WorkplaceCode = @NewWorkplaceCode AND LangCode = N'EN')
         THEN 'OK'
         ELSE 'MISSING'
    END AS Status;

-- Optional: check whether OLD still exists in master (depends on your policy)
SELECT
    'cdWorkplace (OLD exists?)' AS CheckName,
    @OldWorkplaceCode AS WorkplaceCode,
    CASE WHEN EXISTS (SELECT 1 FROM dbo.cdWorkplace WHERE WorkplaceCode = @OldWorkplaceCode)
         THEN 'YES'
         ELSE 'NO'
    END AS ExistsInMaster;

--------------------------------------------------------------------------------
-- 2) Occurrence checks in dependent tables
--    IMPORTANT: customize this list to match the tables you actually update.
--    You can add/remove tables freely.
--------------------------------------------------------------------------------
PRINT '=== Dependent table occurrence checks (customize table list) ===';

IF OBJECT_ID('tempdb..#Counts') IS NOT NULL DROP TABLE #Counts;
CREATE TABLE #Counts
(
    TableName SYSNAME NOT NULL,
    ColumnName SYSNAME NOT NULL,
    OldCount BIGINT NOT NULL,
    NewCount BIGINT NOT NULL
);

DECLARE @sql NVARCHAR(MAX);

-- Helper macro-like pattern:
-- Add entries by copying the block below and updating Table/Column names.

-- Example 1: dbo.SomeTable.WorkplaceCode
IF OBJECT_ID('dbo.SomeTable', 'U') IS NOT NULL
BEGIN
    SET @sql = N'
        INSERT INTO #Counts(TableName, ColumnName, OldCount, NewCount)
        SELECT
            N''dbo.SomeTable'',
            N''WorkplaceCode'',
            SUM(CASE WHEN WorkplaceCode = @Old THEN 1 ELSE 0 END),
            SUM(CASE WHEN WorkplaceCode = @New THEN 1 ELSE 0 END)
        FROM dbo.SomeTable WITH (NOLOCK);';

    EXEC sp_executesql @sql, N'@Old NVARCHAR(20), @New NVARCHAR(20)', @Old=@OldWorkplaceCode, @New=@NewWorkplaceCode;
END

-- Example 2: dbo.AnotherTable.FromWorkplaceCode
IF OBJECT_ID('dbo.AnotherTable', 'U') IS NOT NULL
BEGIN
    SET @sql = N'
        INSERT INTO #Counts(TableName, ColumnName, OldCount, NewCount)
        SELECT
            N''dbo.AnotherTable'',
            N''FromWorkplaceCode'',
            SUM(CASE WHEN FromWorkplaceCode = @Old THEN 1 ELSE 0 END),
            SUM(CASE WHEN FromWorkplaceCode = @New THEN 1 ELSE 0 END)
        FROM dbo.AnotherTable WITH (NOLOCK);';

    EXEC sp_executesql @sql, N'@Old NVARCHAR(20), @New NVARCHAR(20)', @Old=@OldWorkplaceCode, @New=@NewWorkplaceCode;
END

-- Example 3: dbo.AnotherTable.ToWorkplaceCode
IF OBJECT_ID('dbo.AnotherTable', 'U') IS NOT NULL
BEGIN
    SET @sql = N'
        INSERT INTO #Counts(TableName, ColumnName, OldCount, NewCount)
        SELECT
            N''dbo.AnotherTable'',
            N''ToWorkplaceCode'',
            SUM(CASE WHEN ToWorkplaceCode = @Old THEN 1 ELSE 0 END),
            SUM(CASE WHEN ToWorkplaceCode = @New THEN 1 ELSE 0 END)
        FROM dbo.AnotherTable WITH (NOLOCK);';

    EXEC sp_executesql @sql, N'@Old NVARCHAR(20), @New NVARCHAR(20)', @Old=@OldWorkplaceCode, @New=@NewWorkplaceCode;
END

--------------------------------------------------------------------------------
-- 3) Results + Sign-off summary
--------------------------------------------------------------------------------
SELECT *
FROM #Counts
ORDER BY (OldCount + NewCount) DESC, TableName, ColumnName;

SELECT
    SUM(CASE WHEN OldCount > 0 THEN 1 ELSE 0 END) AS TablesWithOldRemaining,
    SUM(OldCount) AS TotalOldOccurrences,
    SUM(NewCount) AS TotalNewOccurrences
FROM #Counts;

PRINT '=== Recommendation ===';
PRINT 'If TablesWithOldRemaining = 0 and master checks are OK, migration is consistent.';
