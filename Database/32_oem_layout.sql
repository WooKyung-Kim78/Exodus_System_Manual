/* ============================================================
   32_oem_layout.sql
   Label = OEM 문서 형식 — 반복 실행 가능

     1) OEM 문서는 표지·Table of Contents 페이지가 없고, 첫 페이지 상단에 "<Model Name> Manual Data" 만 찍는다.
     2) 꼬리말 문구는 관리자가 공통 코드(COVER / OEM_FOOTER)에서 바꾼다.
     3) 목차 템플릿을 자동으로 넣지 않는다. 문서를 만든 뒤 직접 추가한다.
   ============================================================ */
SET NOCOUNT ON;
GO

MERGE dbo.TB_S_MASTER_COMMON_CODE AS t
USING (VALUES
    ('COVER', 'OEM_FOOTER', N'EXODUS ADVANCED COMMUNICATIONS, CORP.', 4)
) AS s (CATEGORY, CODE, NAME, ORDER_NUM)
   ON t.CATEGORY = s.CATEGORY AND t.CODE = s.CODE
WHEN NOT MATCHED THEN
    INSERT (CATEGORY, CODE, NAME, ORDER_NUM, REG_ID)
    VALUES (s.CATEGORY, s.CODE, s.NAME, s.ORDER_NUM, 'system');
GO

/* ---------- 문서 생성 (27_template_toc_underline.sql 기준 + OEM 은 템플릿 목차 제외) ---------- */
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
        INSERT INTO dbo.TB_S_SECTION (M_ID, ORDER_NUM, SEC_LEVEL, SEC_NO, TITLE, TPL_ID, ASSIGNED_TEAM,
                                      TITLE_ALIGN, SEC_TYPE, SHOW_IN_TOC, TITLE_UNDERLINE, REG_ID)
        OUTPUT inserted.SEC_ID, inserted.TPL_ID INTO @InsertedSections
        SELECT @M_ID, ROW_NUMBER() OVER (ORDER BY t.ORDER_NUM, t.TPL_ID), t.SEC_LEVEL, t.SEC_NO, t.TITLE, t.TPL_ID, t.ASSIGNED_TEAM,
               ISNULL(t.TITLE_ALIGN, 'LEFT'), ISNULL(t.SEC_TYPE, 'NORMAL'),
               ISNULL(t.SHOW_IN_TOC, 'Y'), ISNULL(t.TITLE_UNDERLINE, 'N'), @USER_ID
        FROM dbo.TB_S_SECTION_TEMPLATE t
        WHERE ISNULL(@LABEL, N'') <> N'OEM'
          AND t.IS_DELETED = 'N' AND t.IS_MANDATORY = 'Y'
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

PRINT '32_oem_layout.sql 완료';
GO
