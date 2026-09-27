/* ============================================================
   23_datasheet_process.sql
   Job Number 로 고른 datasheet 의 PROCESS_ID 저장 — 반복 실행 가능

   - TB_S_MANUAL.PROCESS_ID 는 exodus_datasheet 의 TB_DS_DOCUMENT.D_ID 와 같은 값.
   - SPECIFICATIONS 내용은 더 이상 TB_S_ELEMENT 에 복사하지 않는다.
     화면을 열 때와 PDF 를 만들 때 PROCESS_ID 로 datasheet 에서 바로 읽는다.
   ============================================================ */
SET NOCOUNT ON;
GO

/* ------------------------------------------------------------
   1) 컬럼 추가
   ------------------------------------------------------------ */
IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('dbo.TB_S_MANUAL') AND name = 'PROCESS_ID')
    ALTER TABLE dbo.TB_S_MANUAL ADD PROCESS_ID varchar(50) NULL;
GO

/* ------------------------------------------------------------
   2) 예전 동기화가 넣어 둔 사양 블록 정리
      ds-spec-block 은 동기화가 만든 블록의 표식이라 사용자가 쓴 글이 아니다.
      그대로 두면 실시간으로 그리는 사양과 두 번 보인다.
   ------------------------------------------------------------ */
UPDATE dbo.TB_S_ELEMENT
SET IS_DELETED = 'Y',
    UPT_DT     = GETDATE()
WHERE IS_DELETED = 'N'
  AND ELE_TYPE = 'TEXT'
  AND CONTENT_HTML LIKE '%ds-spec-block%';
GO

/* ------------------------------------------------------------
   3) 문서 생성 — @PROCESS_ID 추가 (마지막 인자)
   ------------------------------------------------------------ */
CREATE OR ALTER PROCEDURE dbo.USP_S_INSERT_MANUAL
    @JOB_NUMBER nvarchar(50), @MODEL_NAME nvarchar(100), @LABEL nvarchar(200) = NULL,
    @COOLING nvarchar(100) = NULL, @OPTION_TEXT nvarchar(500) = NULL, @PAGE_SIZE varchar(10) = 'LETTER',
    @DOC_NUM varchar(50) = NULL, @USER_ID varchar(20), @PROCESS_ID varchar(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @MODEL_NAME IS NULL OR LTRIM(RTRIM(@MODEL_NAME)) = ''
    BEGIN SELECT Success = 0, ReturnMsg = N'Model Name 은 필수입니다.'; RETURN; END
    IF @LABEL IS NOT NULL AND @LABEL NOT IN (N'EXODUS', N'OEM')
    BEGIN SELECT Success = 0, ReturnMsg = N'Label 값이 올바르지 않습니다.'; RETURN; END
    IF @COOLING IS NOT NULL AND @COOLING NOT IN (N'AIR', N'LIQUID')
    BEGIN SELECT Success = 0, ReturnMsg = N'Cooling 값이 올바르지 않습니다.'; RETURN; END
    SET @PROCESS_ID = NULLIF(LTRIM(RTRIM(@PROCESS_ID)), '');
    DECLARE @SEQ bigint = NEXT VALUE FOR dbo.SEQ_S_MANUAL;
    DECLARE @M_ID varchar(10) = 'M' + RIGHT('000000000' + CAST(@SEQ AS varchar(9)), 9);
    IF @DOC_NUM IS NULL OR LTRIM(RTRIM(@DOC_NUM)) = '' SET @DOC_NUM = 'SM-' + FORMAT(GETDATE(), 'yy') + RIGHT('0000' + CAST(@SEQ AS varchar(9)), 4);
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO dbo.TB_S_MANUAL (M_ID, DOC_NUM, JOB_NUMBER, PROCESS_ID, MODEL_NAME, LABEL, COOLING, OPTION_TEXT, REVISION, STATUS, PAGE_SIZE, REQUESTER_ID, REG_ID)
        VALUES (@M_ID, @DOC_NUM, @JOB_NUMBER, @PROCESS_ID, @MODEL_NAME, @LABEL, @COOLING, @OPTION_TEXT, 'A', 'DRAFT', @PAGE_SIZE, @USER_ID, @USER_ID);
        DECLARE @InsertedSections TABLE (SEC_ID bigint, TPL_ID bigint);
        INSERT INTO dbo.TB_S_SECTION (M_ID, ORDER_NUM, SEC_LEVEL, SEC_NO, TITLE, TPL_ID, ASSIGNED_TEAM, TITLE_ALIGN, REG_ID)
        OUTPUT inserted.SEC_ID, inserted.TPL_ID INTO @InsertedSections
        SELECT @M_ID, ROW_NUMBER() OVER (ORDER BY t.ORDER_NUM, t.TPL_ID), t.SEC_LEVEL, t.SEC_NO, t.TITLE, t.TPL_ID, t.ASSIGNED_TEAM,
               ISNULL(t.TITLE_ALIGN, 'LEFT'), @USER_ID
        FROM dbo.TB_S_SECTION_TEMPLATE t
        WHERE t.IS_DELETED = 'N' AND t.IS_MANDATORY = 'Y'
          AND (t.LABEL IS NULL OR t.LABEL = @LABEL) AND (t.COOLING IS NULL OR t.COOLING = @COOLING);
        INSERT INTO dbo.TB_S_ELEMENT (M_ID, SEC_ID, ELE_TYPE, ORDER_NUM, WIDTH, HEIGHT, CONTENT_HTML, REG_ID)
        SELECT @M_ID, i.SEC_ID, 'TEXT', 1, 0, 0, t.CONTENT_HTML, @USER_ID
        FROM @InsertedSections i INNER JOIN dbo.TB_S_SECTION_TEMPLATE t ON t.TPL_ID = i.TPL_ID
        WHERE NULLIF(LTRIM(RTRIM(t.CONTENT_HTML)), N'') IS NOT NULL;
        COMMIT TRANSACTION;
        SELECT Success = 1, ReturnMsg = CAST(@M_ID AS nvarchar(4000));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT Success = 0, ReturnMsg = ERROR_MESSAGE();
    END CATCH
END
GO

/* ------------------------------------------------------------
   4) 기본 정보 수정 — @PROCESS_ID 추가 (마지막 인자)
      Job Number 를 지우면 PROCESS_ID 도 같이 비운다.
   ------------------------------------------------------------ */
CREATE OR ALTER PROCEDURE dbo.USP_S_UPDATE_MANUAL_HEADER
    @M_ID        varchar(10),
    @JOB_NUMBER  nvarchar(50)  = NULL,
    @MODEL_NAME  nvarchar(100),
    @LABEL       nvarchar(200) = NULL,
    @COOLING     nvarchar(100) = NULL,
    @OPTION_TEXT nvarchar(500) = NULL,
    @PAGE_SIZE   varchar(10)   = NULL,
    @USER_ID     varchar(20),
    @PROCESS_ID  varchar(50)   = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_MANUAL WHERE M_ID = @M_ID AND STATUS = 'DRAFT' AND IS_DELETED = 'N')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'작성(DRAFT) 상태의 문서만 수정할 수 있습니다.';
        RETURN;
    END

    SET @JOB_NUMBER = NULLIF(LTRIM(RTRIM(@JOB_NUMBER)), N'');
    SET @PROCESS_ID = NULLIF(LTRIM(RTRIM(@PROCESS_ID)), '');
    IF @JOB_NUMBER IS NULL SET @PROCESS_ID = NULL;

    UPDATE dbo.TB_S_MANUAL
    SET JOB_NUMBER  = @JOB_NUMBER,
        PROCESS_ID  = @PROCESS_ID,
        MODEL_NAME  = @MODEL_NAME,
        LABEL       = @LABEL,
        COOLING     = @COOLING,
        OPTION_TEXT = @OPTION_TEXT,
        PAGE_SIZE   = ISNULL(@PAGE_SIZE, PAGE_SIZE),
        UPT_ID      = @USER_ID,
        UPT_DT      = GETDATE()
    WHERE M_ID = @M_ID;

    SELECT Success = 1, ReturnMsg = N'OK';
END
GO

/* ------------------------------------------------------------
   5) 문서 단건 조회 — PROCESS_ID 반환
   ------------------------------------------------------------ */
CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_MANUAL
    @M_ID varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        m.M_ID, m.DOC_NUM, m.JOB_NUMBER, m.PROCESS_ID, m.MODEL_NAME, m.LABEL, m.COOLING, m.OPTION_TEXT,
        m.REVISION, m.STATUS, m.PAGE_SIZE, m.PAGE_ORIENTATION, m.HEADING_STYLE_JSON,
        m.COVER_IMAGE_PATH, m.BODY_FONT, m.BODY_FONT_SIZE,
        m.BODY_LINE_HEIGHT, m.BODY_LETTER_SPACING,
        m.REQUESTER_ID, REQUESTER_NAME = ru.FULL_NAME,
        m.APPROVER_ID,  APPROVER_NAME  = au.FULL_NAME,
        m.ORIGINAL_M_ID, m.REQUEST_DATE, m.APPROVED_DATE, m.PUBLISH_DATE, m.OBSOLETE_DATE,
        m.REG_DT, m.UPT_DT
    FROM dbo.TB_S_MANUAL m
    LEFT JOIN dbo.TB_S_USER ru ON ru.USER_ID = m.REQUESTER_ID
    LEFT JOIN dbo.TB_S_USER au ON au.USER_ID = m.APPROVER_ID
    WHERE m.M_ID = @M_ID
      AND m.IS_DELETED = 'N';
END
GO

PRINT '23_datasheet_process.sql 완료';
GO
