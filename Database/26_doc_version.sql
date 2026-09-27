/* ============================================================
   26_doc_version.sql
   문서 버전(DOC_VERSION) 추가.

     - PDF 꼬리말에 "1 | Page - Ver. 1.0" 으로 찍히는 값이다.
     - 결재 이력을 따라가는 REVISION(A, B, C...) 과는 별개로,
       문서를 만들 때 사람이 직접 적는 표기용 버전이다.
     - 비어 있으면 '1.0' 으로 본다.

   반복 실행 가능.
   ============================================================ */
SET NOCOUNT ON;
GO

IF COL_LENGTH('dbo.TB_S_MANUAL', 'DOC_VERSION') IS NULL
    ALTER TABLE dbo.TB_S_MANUAL ADD DOC_VERSION nvarchar(20) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = 'DF_TB_S_MANUAL_DOC_VERSION')
    ALTER TABLE dbo.TB_S_MANUAL ADD CONSTRAINT DF_TB_S_MANUAL_DOC_VERSION DEFAULT (N'1.0') FOR DOC_VERSION;
GO

UPDATE dbo.TB_S_MANUAL SET DOC_VERSION = N'1.0' WHERE NULLIF(LTRIM(RTRIM(DOC_VERSION)), N'') IS NULL;
GO

/* ---------- 문서 생성 (25_page_break_section.sql 기준 + DOC_VERSION) ---------- */
CREATE OR ALTER PROCEDURE dbo.USP_S_INSERT_MANUAL
    @JOB_NUMBER nvarchar(50), @MODEL_NAME nvarchar(100), @LABEL nvarchar(200) = NULL,
    @COOLING nvarchar(100) = NULL, @OPTION_TEXT nvarchar(500) = NULL, @PAGE_SIZE varchar(10) = 'LETTER',
    @DOC_NUM varchar(50) = NULL, @USER_ID varchar(20), @PROCESS_ID varchar(50) = NULL,
    @DOC_VERSION nvarchar(20) = NULL
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
    SET @DOC_VERSION = ISNULL(NULLIF(LTRIM(RTRIM(@DOC_VERSION)), N''), N'1.0');
    DECLARE @SEQ bigint = NEXT VALUE FOR dbo.SEQ_S_MANUAL;
    DECLARE @M_ID varchar(10) = 'M' + RIGHT('000000000' + CAST(@SEQ AS varchar(9)), 9);
    IF @DOC_NUM IS NULL OR LTRIM(RTRIM(@DOC_NUM)) = '' SET @DOC_NUM = 'SM-' + FORMAT(GETDATE(), 'yy') + RIGHT('0000' + CAST(@SEQ AS varchar(9)), 4);
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO dbo.TB_S_MANUAL (M_ID, DOC_NUM, JOB_NUMBER, PROCESS_ID, MODEL_NAME, LABEL, COOLING, OPTION_TEXT, REVISION, DOC_VERSION, STATUS, PAGE_SIZE, REQUESTER_ID, REG_ID)
        VALUES (@M_ID, @DOC_NUM, @JOB_NUMBER, @PROCESS_ID, @MODEL_NAME, @LABEL, @COOLING, @OPTION_TEXT, 'A', @DOC_VERSION, 'DRAFT', @PAGE_SIZE, @USER_ID, @USER_ID);
        DECLARE @InsertedSections TABLE (SEC_ID bigint, TPL_ID bigint);
        INSERT INTO dbo.TB_S_SECTION (M_ID, ORDER_NUM, SEC_LEVEL, SEC_NO, TITLE, TPL_ID, ASSIGNED_TEAM, TITLE_ALIGN, SEC_TYPE, REG_ID)
        OUTPUT inserted.SEC_ID, inserted.TPL_ID INTO @InsertedSections
        SELECT @M_ID, ROW_NUMBER() OVER (ORDER BY t.ORDER_NUM, t.TPL_ID), t.SEC_LEVEL, t.SEC_NO, t.TITLE, t.TPL_ID, t.ASSIGNED_TEAM,
               ISNULL(t.TITLE_ALIGN, 'LEFT'), ISNULL(t.SEC_TYPE, 'NORMAL'), @USER_ID
        FROM dbo.TB_S_SECTION_TEMPLATE t
        WHERE t.IS_DELETED = 'N' AND t.IS_MANDATORY = 'Y'
          AND (t.LABEL IS NULL OR t.LABEL = @LABEL) AND (t.COOLING IS NULL OR t.COOLING = @COOLING);
        INSERT INTO dbo.TB_S_ELEMENT (M_ID, SEC_ID, ELE_TYPE, ORDER_NUM, WIDTH, HEIGHT, CONTENT_HTML, REG_ID)
        SELECT @M_ID, i.SEC_ID, 'TEXT', 1, 0, 0, t.CONTENT_HTML, @USER_ID
        FROM @InsertedSections i INNER JOIN dbo.TB_S_SECTION_TEMPLATE t ON t.TPL_ID = i.TPL_ID
        WHERE ISNULL(t.SEC_TYPE, 'NORMAL') = 'NORMAL'
          AND NULLIF(LTRIM(RTRIM(t.CONTENT_HTML)), N'') IS NOT NULL;
        COMMIT TRANSACTION;
        SELECT Success = 1, ReturnMsg = CAST(@M_ID AS nvarchar(4000));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT Success = 0, ReturnMsg = ERROR_MESSAGE();
    END CATCH
END
GO

/* ---------- 기본 정보 수정 (23_datasheet_process.sql 기준 + DOC_VERSION) ---------- */
CREATE OR ALTER PROCEDURE dbo.USP_S_UPDATE_MANUAL_HEADER
    @M_ID        varchar(10),
    @JOB_NUMBER  nvarchar(50)  = NULL,
    @MODEL_NAME  nvarchar(100),
    @LABEL       nvarchar(200) = NULL,
    @COOLING     nvarchar(100) = NULL,
    @OPTION_TEXT nvarchar(500) = NULL,
    @PAGE_SIZE   varchar(10)   = NULL,
    @USER_ID     varchar(20),
    @PROCESS_ID  varchar(50)   = NULL,
    @DOC_VERSION nvarchar(20)  = NULL
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
    SET @DOC_VERSION = NULLIF(LTRIM(RTRIM(@DOC_VERSION)), N'');

    UPDATE dbo.TB_S_MANUAL
    SET JOB_NUMBER  = @JOB_NUMBER,
        PROCESS_ID  = @PROCESS_ID,
        MODEL_NAME  = @MODEL_NAME,
        LABEL       = @LABEL,
        COOLING     = @COOLING,
        OPTION_TEXT = @OPTION_TEXT,
        PAGE_SIZE   = ISNULL(@PAGE_SIZE, PAGE_SIZE),
        DOC_VERSION = ISNULL(@DOC_VERSION, DOC_VERSION),
        UPT_ID      = @USER_ID,
        UPT_DT      = GETDATE()
    WHERE M_ID = @M_ID;

    SELECT Success = 1, ReturnMsg = N'OK';
END
GO

/* ---------- 문서 단건 조회 (23_datasheet_process.sql 기준 + DOC_VERSION) ---------- */
CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_MANUAL
    @M_ID varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        m.M_ID, m.DOC_NUM, m.JOB_NUMBER, m.PROCESS_ID, m.MODEL_NAME, m.LABEL, m.COOLING, m.OPTION_TEXT,
        m.REVISION, DOC_VERSION = ISNULL(NULLIF(LTRIM(RTRIM(m.DOC_VERSION)), N''), N'1.0'),
        m.STATUS, m.PAGE_SIZE, m.PAGE_ORIENTATION, m.HEADING_STYLE_JSON,
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

PRINT '26_doc_version.sql 완료';
GO
