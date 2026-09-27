/* ============================================================
   25_page_break_section.sql
   목차에 '페이지 나눔'(SEC_TYPE = 'PAGEBREAK') 항목 추가.

     - 제목·내용 없이 그 자리에서 PDF 페이지만 끊는 목차다.
     - 템플릿에 넣어 두면 문서를 만들 때 순서 그대로 복사되고,
       문서의 목차관리에서도 필요한 자리마다 직접 넣을 수 있다.
     - 같은 템플릿을 여러 번 넣어야 하므로 '이미 추가됨' 검사에서 제외한다.
     - NULL 은 일반 목차(NORMAL)로 본다.

   반복 실행 가능.
   ============================================================ */
SET NOCOUNT ON;
GO

IF COL_LENGTH('dbo.TB_S_SECTION_TEMPLATE', 'SEC_TYPE') IS NULL
    ALTER TABLE dbo.TB_S_SECTION_TEMPLATE ADD SEC_TYPE varchar(20) NULL;
GO

IF COL_LENGTH('dbo.TB_S_SECTION', 'SEC_TYPE') IS NULL
    ALTER TABLE dbo.TB_S_SECTION ADD SEC_TYPE varchar(20) NULL;
GO

UPDATE dbo.TB_S_SECTION_TEMPLATE SET SEC_TYPE = 'NORMAL' WHERE SEC_TYPE IS NULL;
UPDATE dbo.TB_S_SECTION          SET SEC_TYPE = 'NORMAL' WHERE SEC_TYPE IS NULL;
GO

/* ---------- 목차 템플릿 ---------- */
CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_SECTION_TEMPLATE_LIST
    @LABEL nvarchar(20) = NULL,
    @COOLING nvarchar(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT t.TPL_ID, t.LABEL, t.COOLING, t.SEC_LEVEL, t.SEC_NO, t.TITLE,
           t.IS_MANDATORY, t.ORDER_NUM, t.ASSIGNED_TEAM, t.CONTENT_HTML,
           TITLE_ALIGN = ISNULL(t.TITLE_ALIGN, 'LEFT'),
           SEC_TYPE = ISNULL(t.SEC_TYPE, 'NORMAL'),
           t.REG_DT, t.UPT_DT
    FROM dbo.TB_S_SECTION_TEMPLATE t
    WHERE t.IS_DELETED = 'N'
      AND (@LABEL IS NULL OR t.LABEL IS NULL OR t.LABEL = @LABEL)
      AND (@COOLING IS NULL OR t.COOLING IS NULL OR t.COOLING = @COOLING)
    ORDER BY t.ORDER_NUM, t.TPL_ID;
END
GO

/* 페이지 나눔은 제목·단계·담당·내용이 의미가 없어 저장 전에 모두 비운다. */
CREATE OR ALTER PROCEDURE dbo.USP_S_MERGE_SECTION_TEMPLATE
    @TPL_ID bigint = NULL, @LABEL nvarchar(20) = NULL, @COOLING nvarchar(20) = NULL,
    @SEC_LEVEL int = 1, @SEC_NO nvarchar(20) = NULL, @TITLE nvarchar(200),
    @IS_MANDATORY varchar(1) = 'Y', @ORDER_NUM int = NULL,
    @ASSIGNED_TEAM nvarchar(100) = NULL, @CONTENT_HTML nvarchar(max) = NULL,
    @TITLE_ALIGN varchar(10) = NULL,
    @SEC_TYPE varchar(20) = NULL,
    @USER_ID varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF @SEC_TYPE IS NULL OR @SEC_TYPE NOT IN ('NORMAL', 'PAGEBREAK') SET @SEC_TYPE = 'NORMAL';

    IF @SEC_TYPE = 'PAGEBREAK'
    BEGIN
        SET @TITLE = N'페이지 나눔';
        SET @SEC_LEVEL = 1;
        SET @SEC_NO = NULL;
        SET @ASSIGNED_TEAM = NULL;
        SET @CONTENT_HTML = NULL;
        SET @TITLE_ALIGN = 'LEFT';
    END

    IF @TITLE IS NULL OR LTRIM(RTRIM(@TITLE)) = N''
    BEGIN SELECT Success = 0, ReturnMsg = N'제목은 필수입니다.'; RETURN; END
    IF @SEC_LEVEL NOT BETWEEN 1 AND 3 SET @SEC_LEVEL = 1;
    IF @IS_MANDATORY NOT IN ('Y', 'N') SET @IS_MANDATORY = 'Y';
    IF @LABEL = N'' SET @LABEL = NULL;
    IF @COOLING = N'' SET @COOLING = NULL;
    IF @ASSIGNED_TEAM = N'' SET @ASSIGNED_TEAM = NULL;
    IF @TITLE_ALIGN IS NULL OR @TITLE_ALIGN NOT IN ('LEFT', 'CENTER', 'RIGHT') SET @TITLE_ALIGN = 'LEFT';

    IF @TPL_ID IS NULL
    BEGIN
        IF @ORDER_NUM IS NULL OR @ORDER_NUM = 0
            SET @ORDER_NUM = ISNULL((SELECT MAX(ORDER_NUM) FROM dbo.TB_S_SECTION_TEMPLATE WHERE IS_DELETED = 'N'), 0) + 1;
        INSERT INTO dbo.TB_S_SECTION_TEMPLATE
            (LABEL, COOLING, SEC_LEVEL, SEC_NO, TITLE, IS_MANDATORY, ORDER_NUM, ASSIGNED_TEAM, CONTENT_HTML, TITLE_ALIGN, SEC_TYPE, REG_ID)
        VALUES
            (@LABEL, @COOLING, @SEC_LEVEL, @SEC_NO, @TITLE, @IS_MANDATORY, @ORDER_NUM, @ASSIGNED_TEAM, @CONTENT_HTML, @TITLE_ALIGN, @SEC_TYPE, @USER_ID);
        SELECT Success = 1, ReturnMsg = CAST(SCOPE_IDENTITY() AS nvarchar(4000));
        RETURN;
    END

    UPDATE dbo.TB_S_SECTION_TEMPLATE
    SET LABEL = @LABEL, COOLING = @COOLING, SEC_LEVEL = @SEC_LEVEL, SEC_NO = @SEC_NO,
        TITLE = @TITLE, IS_MANDATORY = @IS_MANDATORY, ORDER_NUM = ISNULL(@ORDER_NUM, ORDER_NUM),
        ASSIGNED_TEAM = @ASSIGNED_TEAM, CONTENT_HTML = @CONTENT_HTML, TITLE_ALIGN = @TITLE_ALIGN,
        SEC_TYPE = @SEC_TYPE,
        UPT_ID = @USER_ID, UPT_DT = GETDATE()
    WHERE TPL_ID = @TPL_ID AND IS_DELETED = 'N';
    IF @@ROWCOUNT = 0
    BEGIN SELECT Success = 0, ReturnMsg = N'템플릿 항목을 찾을 수 없습니다.'; RETURN; END
    SELECT Success = 1, ReturnMsg = CAST(@TPL_ID AS nvarchar(4000));
END
GO

/* 페이지 나눔은 한 문서에 여러 번 넣을 수 있어 '추가됨' 으로 잠그지 않는다. */
CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_TEMPLATE_OPTION_LIST
    @M_ID varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LABEL nvarchar(20), @COOLING nvarchar(20);
    SELECT @LABEL = LABEL, @COOLING = COOLING
    FROM dbo.TB_S_MANUAL WHERE M_ID = @M_ID AND IS_DELETED = 'N';

    SELECT t.TPL_ID, t.LABEL, t.COOLING, t.SEC_LEVEL, t.SEC_NO, t.TITLE,
           t.IS_MANDATORY, t.ORDER_NUM, t.ASSIGNED_TEAM,
           TITLE_ALIGN = ISNULL(t.TITLE_ALIGN, 'LEFT'),
           SEC_TYPE = ISNULL(t.SEC_TYPE, 'NORMAL'),
           IS_ADDED = CASE WHEN ISNULL(t.SEC_TYPE, 'NORMAL') = 'PAGEBREAK' THEN 'N'
                           WHEN EXISTS (SELECT 1 FROM dbo.TB_S_SECTION s
                                        WHERE s.M_ID = @M_ID AND s.TPL_ID = t.TPL_ID AND s.IS_DELETED = 'N')
                           THEN 'Y' ELSE 'N' END
    FROM dbo.TB_S_SECTION_TEMPLATE t
    WHERE t.IS_DELETED = 'N'
      AND (t.LABEL   IS NULL OR @LABEL   IS NULL OR t.LABEL   = @LABEL)
      AND (t.COOLING IS NULL OR @COOLING IS NULL OR t.COOLING = @COOLING)
    ORDER BY t.ORDER_NUM, t.TPL_ID;
END
GO

/* ---------- 템플릿 → 목차 복사 ---------- */
CREATE OR ALTER PROCEDURE dbo.USP_S_INSERT_SECTION_FROM_TEMPLATE
    @M_ID varchar(10), @TPL_ID bigint, @USER_ID varchar(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_MANUAL WHERE M_ID = @M_ID AND STATUS = 'DRAFT' AND IS_DELETED = 'N')
    BEGIN SELECT Success = 0, ReturnMsg = N'작성(DRAFT) 상태의 문서만 수정할 수 있습니다.'; RETURN; END

    DECLARE @TPL_TYPE varchar(20) = (SELECT ISNULL(SEC_TYPE, 'NORMAL') FROM dbo.TB_S_SECTION_TEMPLATE
                                     WHERE TPL_ID = @TPL_ID AND IS_DELETED = 'N');
    IF @TPL_TYPE IS NULL
    BEGIN SELECT Success = 0, ReturnMsg = N'템플릿 항목을 찾을 수 없습니다.'; RETURN; END

    IF @TPL_TYPE <> 'PAGEBREAK'
       AND EXISTS (SELECT 1 FROM dbo.TB_S_SECTION WHERE M_ID = @M_ID AND TPL_ID = @TPL_ID AND IS_DELETED = 'N')
    BEGIN SELECT Success = 0, ReturnMsg = N'이미 추가된 목차입니다.'; RETURN; END

    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @ORDER int = ISNULL((SELECT MAX(ORDER_NUM) FROM dbo.TB_S_SECTION WHERE M_ID = @M_ID AND IS_DELETED = 'N'), 0) + 1;
        DECLARE @SEC_ID bigint;
        INSERT INTO dbo.TB_S_SECTION (M_ID, ORDER_NUM, SEC_LEVEL, SEC_NO, TITLE, TPL_ID, ASSIGNED_TEAM, TITLE_ALIGN, SEC_TYPE, REG_ID)
        SELECT @M_ID, @ORDER, SEC_LEVEL, SEC_NO, TITLE, TPL_ID, ASSIGNED_TEAM, ISNULL(TITLE_ALIGN, 'LEFT'), ISNULL(SEC_TYPE, 'NORMAL'), @USER_ID
        FROM dbo.TB_S_SECTION_TEMPLATE WHERE TPL_ID = @TPL_ID AND IS_DELETED = 'N';
        SET @SEC_ID = SCOPE_IDENTITY();
        IF @SEC_ID IS NULL BEGIN ROLLBACK TRANSACTION; SELECT Success = 0, ReturnMsg = N'템플릿 항목을 찾을 수 없습니다.'; RETURN; END
        INSERT INTO dbo.TB_S_ELEMENT (M_ID, SEC_ID, ELE_TYPE, ORDER_NUM, WIDTH, HEIGHT, CONTENT_HTML, REG_ID)
        SELECT @M_ID, @SEC_ID, 'TEXT', 1, 0, 0, CONTENT_HTML, @USER_ID
        FROM dbo.TB_S_SECTION_TEMPLATE
        WHERE TPL_ID = @TPL_ID AND ISNULL(SEC_TYPE, 'NORMAL') = 'NORMAL'
          AND NULLIF(LTRIM(RTRIM(CONTENT_HTML)), N'') IS NOT NULL;
        COMMIT TRANSACTION;
        SELECT Success = 1, ReturnMsg = CAST(@SEC_ID AS nvarchar(4000));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT Success = 0, ReturnMsg = ERROR_MESSAGE();
    END CATCH
END
GO

/* ---------- 문서 생성 (23_datasheet_process.sql 기준 + SEC_TYPE) ---------- */
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

/* ---------- 문서 목차 ---------- */
CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_SECTION_LIST
    @M_ID    varchar(10),
    @USER_ID varchar(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT s.SEC_ID, s.M_ID, s.ORDER_NUM, s.SEC_LEVEL, s.SEC_NO, s.TITLE,
           s.STYLE_JSON, s.TPL_ID,
           TITLE_ALIGN = ISNULL(s.TITLE_ALIGN, 'LEFT'),
           SEC_TYPE = ISNULL(s.SEC_TYPE, 'NORMAL'),
           s.ASSIGNED_TEAM,
           EDITOR_NAME = eu.FULL_NAME,
           CAN_EDIT_SEC = dbo.UFN_S_CAN_EDIT_SECTION(s.SEC_ID, @USER_ID),
           s.SEC_STATUS,
           BLOCK_CNT = (SELECT COUNT(*) FROM dbo.TB_S_ELEMENT e
                        WHERE e.SEC_ID = s.SEC_ID AND e.IS_DELETED = 'N'),
           OPEN_CMT_CNT = (SELECT COUNT(*) FROM dbo.TB_S_COMMENT c
                           WHERE c.SEC_ID = s.SEC_ID AND c.IS_DELETED = 'N' AND c.IS_RESOLVED = 'N'),
           s.UPT_DT
    FROM dbo.TB_S_SECTION s
    LEFT JOIN dbo.TB_S_USER eu ON eu.USER_ID = s.UPT_ID
    WHERE s.M_ID = @M_ID AND s.IS_DELETED = 'N'
    ORDER BY s.ORDER_NUM, s.SEC_ID;
END
GO

/* 정렬은 STYLE_JSON 과 별개 컬럼이라 '개별 스타일'을 꺼도 남는다.
   종류(SEC_TYPE)는 한 번 정해지면 바뀌지 않는다. 신규 저장 때만 받는다. */
CREATE OR ALTER PROCEDURE dbo.USP_S_MERGE_SECTION
    @SEC_ID        bigint        = NULL,
    @M_ID          varchar(10),
    @TITLE         nvarchar(200),
    @SEC_LEVEL     int           = 1,
    @SEC_NO        nvarchar(20)  = NULL,
    @ASSIGNED_TEAM nvarchar(100) = NULL,
    @SEC_STATUS    varchar(20)   = NULL,
    @STYLE_JSON    nvarchar(max) = NULL,
    @TITLE_ALIGN   varchar(10)   = NULL,
    @SEC_TYPE      varchar(20)   = NULL,
    @USER_ID       varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_MANUAL WHERE M_ID = @M_ID AND STATUS = 'DRAFT' AND IS_DELETED = 'N')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'작성(DRAFT) 상태의 문서만 수정할 수 있습니다.';
        RETURN;
    END

    IF @SEC_ID IS NULL
    BEGIN
        IF dbo.UFN_S_IS_MANUAL_PARTICIPANT(@M_ID, @USER_ID) <> 'Y'
        BEGIN
            SELECT Success = 0, ReturnMsg = N'이 문서를 수정할 권한이 없습니다.';
            RETURN;
        END
    END
    ELSE IF dbo.UFN_S_CAN_EDIT_SECTION(@SEC_ID, @USER_ID) <> 'Y'
    BEGIN
        SELECT Success = 0, ReturnMsg = N'이 목차는 담당 팀만 수정할 수 있습니다.';
        RETURN;
    END

    IF @SEC_TYPE IS NULL OR @SEC_TYPE NOT IN ('NORMAL', 'PAGEBREAK') SET @SEC_TYPE = 'NORMAL';

    IF @SEC_TYPE = 'PAGEBREAK'
    BEGIN
        SET @TITLE = N'페이지 나눔';
        SET @SEC_LEVEL = 1;
        SET @SEC_NO = NULL;
        SET @ASSIGNED_TEAM = NULL;
        SET @STYLE_JSON = NULL;
        SET @TITLE_ALIGN = 'LEFT';
    END

    IF @SEC_LEVEL NOT BETWEEN 1 AND 3 SET @SEC_LEVEL = 1;
    IF @ASSIGNED_TEAM = N'' SET @ASSIGNED_TEAM = NULL;

    IF @STYLE_JSON = N'' OR (@STYLE_JSON IS NOT NULL AND ISJSON(@STYLE_JSON) <> 1)
        SET @STYLE_JSON = NULL;

    IF @TITLE_ALIGN IS NULL OR @TITLE_ALIGN NOT IN ('LEFT', 'CENTER', 'RIGHT') SET @TITLE_ALIGN = 'LEFT';

    IF @SEC_ID IS NULL
    BEGIN
        DECLARE @ORDER int = ISNULL((SELECT MAX(ORDER_NUM) FROM dbo.TB_S_SECTION
                                     WHERE M_ID = @M_ID AND IS_DELETED = 'N'), 0) + 1;

        INSERT INTO dbo.TB_S_SECTION
            (M_ID, ORDER_NUM, SEC_LEVEL, SEC_NO, TITLE, STYLE_JSON, TITLE_ALIGN, SEC_TYPE, ASSIGNED_TEAM, REG_ID)
        VALUES
            (@M_ID, @ORDER, @SEC_LEVEL, @SEC_NO, @TITLE, @STYLE_JSON, @TITLE_ALIGN, @SEC_TYPE, @ASSIGNED_TEAM, @USER_ID);

        DECLARE @NEW_ID bigint = SCOPE_IDENTITY();

        INSERT INTO dbo.TB_S_ELEMENT_HISTORY (M_ID, SEC_ID, ACTION, FIELD_NAME, AFTER_VALUE, REG_ID)
        VALUES (@M_ID, @NEW_ID, 'CREATE', 'SECTION', @TITLE, @USER_ID);

        SELECT Success = 1, ReturnMsg = CAST(@NEW_ID AS nvarchar(4000));
        RETURN;
    END

    DECLARE @OLD_TITLE nvarchar(200) = (SELECT TITLE FROM dbo.TB_S_SECTION WHERE SEC_ID = @SEC_ID);
    DECLARE @OLD_ALIGN varchar(10) = (SELECT ISNULL(TITLE_ALIGN, 'LEFT') FROM dbo.TB_S_SECTION WHERE SEC_ID = @SEC_ID);

    UPDATE dbo.TB_S_SECTION
    SET TITLE         = @TITLE,
        SEC_LEVEL     = @SEC_LEVEL,
        SEC_NO        = @SEC_NO,
        STYLE_JSON    = @STYLE_JSON,
        TITLE_ALIGN   = @TITLE_ALIGN,
        ASSIGNED_TEAM = @ASSIGNED_TEAM,
        SEC_STATUS    = ISNULL(@SEC_STATUS, SEC_STATUS),
        UPT_ID        = @USER_ID,
        UPT_DT        = GETDATE()
    WHERE SEC_ID = @SEC_ID AND M_ID = @M_ID AND IS_DELETED = 'N'
      AND ISNULL(SEC_TYPE, 'NORMAL') = 'NORMAL';

    IF @@ROWCOUNT = 0
    BEGIN
        SELECT Success = 0, ReturnMsg = N'섹션을 찾을 수 없습니다.';
        RETURN;
    END

    IF ISNULL(@OLD_TITLE, N'') <> @TITLE
        INSERT INTO dbo.TB_S_ELEMENT_HISTORY (M_ID, SEC_ID, ACTION, FIELD_NAME, BEFORE_VALUE, AFTER_VALUE, REG_ID)
        VALUES (@M_ID, @SEC_ID, 'UPDATE', 'TITLE', @OLD_TITLE, @TITLE, @USER_ID);

    IF @OLD_ALIGN <> @TITLE_ALIGN
        INSERT INTO dbo.TB_S_ELEMENT_HISTORY (M_ID, SEC_ID, ACTION, FIELD_NAME, BEFORE_VALUE, AFTER_VALUE, REG_ID)
        VALUES (@M_ID, @SEC_ID, 'UPDATE', 'TITLE_ALIGN', @OLD_ALIGN, @TITLE_ALIGN, @USER_ID);

    SELECT Success = 1, ReturnMsg = CAST(@SEC_ID AS nvarchar(4000));
END
GO

PRINT '25_page_break_section.sql 완료';
GO
