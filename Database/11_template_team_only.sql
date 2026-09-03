/* ============================================================
   11_template_team_only.sql
   1) 목차 템플릿에서 담당자 제거 (담당 팀만 유지)
      담당자는 미리 정하지 않고, 실제로 내용을 넣은 사람을 기록한다.
   2) 템플릿 목록은 이미 추가된 항목도 숨기지 않고 표시한다.
      숨기면 목차를 지웠을 때 되돌릴 방법이 안 보인다.
   3) 목차 목록에 최종 수정자 표시

   반복 실행 가능.
   ============================================================ */
SET NOCOUNT ON;
GO

IF COL_LENGTH('dbo.TB_S_SECTION_TEMPLATE', 'ASSIGNED_USER_ID') IS NOT NULL
    ALTER TABLE dbo.TB_S_SECTION_TEMPLATE DROP COLUMN ASSIGNED_USER_ID;
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_SECTION_TEMPLATE_LIST
    @LABEL   nvarchar(20) = NULL,
    @COOLING nvarchar(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT t.TPL_ID, t.LABEL, t.COOLING, t.SEC_LEVEL, t.SEC_NO, t.TITLE,
           t.IS_MANDATORY, t.ORDER_NUM, t.ASSIGNED_TEAM,
           t.REG_DT, t.UPT_DT
    FROM dbo.TB_S_SECTION_TEMPLATE t
    WHERE t.IS_DELETED = 'N'
      AND (@LABEL   IS NULL OR t.LABEL   IS NULL OR t.LABEL   = @LABEL)
      AND (@COOLING IS NULL OR t.COOLING IS NULL OR t.COOLING = @COOLING)
    ORDER BY t.ORDER_NUM, t.TPL_ID;
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_MERGE_SECTION_TEMPLATE
    @TPL_ID        bigint        = NULL,
    @LABEL         nvarchar(20)  = NULL,
    @COOLING       nvarchar(20)  = NULL,
    @SEC_LEVEL     int           = 1,
    @SEC_NO        nvarchar(20)  = NULL,
    @TITLE         nvarchar(200),
    @IS_MANDATORY  varchar(1)    = 'Y',
    @ORDER_NUM     int           = NULL,
    @ASSIGNED_TEAM nvarchar(100) = NULL,
    @USER_ID       varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF (@TITLE IS NULL OR LTRIM(RTRIM(@TITLE)) = N'')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'제목은 필수입니다.';
        RETURN;
    END

    IF @SEC_LEVEL NOT BETWEEN 1 AND 3 SET @SEC_LEVEL = 1;
    IF @IS_MANDATORY NOT IN ('Y', 'N') SET @IS_MANDATORY = 'Y';
    IF @LABEL         = N'' SET @LABEL         = NULL;
    IF @COOLING       = N'' SET @COOLING       = NULL;
    IF @ASSIGNED_TEAM = N'' SET @ASSIGNED_TEAM = NULL;

    IF @TPL_ID IS NULL
    BEGIN
        IF @ORDER_NUM IS NULL OR @ORDER_NUM = 0
            SET @ORDER_NUM = ISNULL((SELECT MAX(ORDER_NUM) FROM dbo.TB_S_SECTION_TEMPLATE
                                     WHERE IS_DELETED = 'N'), 0) + 1;

        INSERT INTO dbo.TB_S_SECTION_TEMPLATE
            (LABEL, COOLING, SEC_LEVEL, SEC_NO, TITLE, IS_MANDATORY, ORDER_NUM, ASSIGNED_TEAM, REG_ID)
        VALUES
            (@LABEL, @COOLING, @SEC_LEVEL, @SEC_NO, @TITLE, @IS_MANDATORY, @ORDER_NUM, @ASSIGNED_TEAM, @USER_ID);

        SELECT Success = 1, ReturnMsg = CAST(SCOPE_IDENTITY() AS nvarchar(4000));
        RETURN;
    END

    UPDATE dbo.TB_S_SECTION_TEMPLATE
    SET LABEL         = @LABEL,
        COOLING       = @COOLING,
        SEC_LEVEL     = @SEC_LEVEL,
        SEC_NO        = @SEC_NO,
        TITLE         = @TITLE,
        IS_MANDATORY  = @IS_MANDATORY,
        ORDER_NUM     = ISNULL(@ORDER_NUM, ORDER_NUM),
        ASSIGNED_TEAM = @ASSIGNED_TEAM,
        UPT_ID        = @USER_ID,
        UPT_DT        = GETDATE()
    WHERE TPL_ID = @TPL_ID AND IS_DELETED = 'N';

    IF @@ROWCOUNT = 0
    BEGIN
        SELECT Success = 0, ReturnMsg = N'템플릿 항목을 찾을 수 없습니다.';
        RETURN;
    END

    SELECT Success = 1, ReturnMsg = CAST(@TPL_ID AS nvarchar(4000));
END
GO

/* 이미 추가된 항목도 IS_ADDED='Y' 로 함께 돌려준다. */
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
           IS_ADDED = CASE WHEN EXISTS (SELECT 1 FROM dbo.TB_S_SECTION s
                                        WHERE s.M_ID = @M_ID AND s.TPL_ID = t.TPL_ID AND s.IS_DELETED = 'N')
                           THEN 'Y' ELSE 'N' END
    FROM dbo.TB_S_SECTION_TEMPLATE t
    WHERE t.IS_DELETED = 'N'
      AND (t.LABEL   IS NULL OR @LABEL   IS NULL OR t.LABEL   = @LABEL)
      AND (t.COOLING IS NULL OR @COOLING IS NULL OR t.COOLING = @COOLING)
    ORDER BY t.ORDER_NUM, t.TPL_ID;
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_INSERT_SECTION_FROM_TEMPLATE
    @M_ID    varchar(10),
    @TPL_ID  bigint,
    @USER_ID varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_MANUAL WHERE M_ID = @M_ID AND STATUS = 'DRAFT' AND IS_DELETED = 'N')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'작성(DRAFT) 상태의 문서만 수정할 수 있습니다.';
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM dbo.TB_S_SECTION WHERE M_ID = @M_ID AND TPL_ID = @TPL_ID AND IS_DELETED = 'N')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'이미 추가된 목차입니다.';
        RETURN;
    END

    DECLARE @ORDER int = ISNULL((SELECT MAX(ORDER_NUM) FROM dbo.TB_S_SECTION
                                 WHERE M_ID = @M_ID AND IS_DELETED = 'N'), 0) + 1;

    INSERT INTO dbo.TB_S_SECTION
        (M_ID, ORDER_NUM, SEC_LEVEL, SEC_NO, TITLE, TPL_ID, ASSIGNED_TEAM, REG_ID)
    SELECT @M_ID, @ORDER, t.SEC_LEVEL, t.SEC_NO, t.TITLE, t.TPL_ID, t.ASSIGNED_TEAM, @USER_ID
    FROM dbo.TB_S_SECTION_TEMPLATE t
    WHERE t.TPL_ID = @TPL_ID AND t.IS_DELETED = 'N';

    IF @@ROWCOUNT = 0
    BEGIN
        SELECT Success = 0, ReturnMsg = N'템플릿 항목을 찾을 수 없습니다.';
        RETURN;
    END

    SELECT Success = 1, ReturnMsg = CAST(SCOPE_IDENTITY() AS nvarchar(4000));
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_INSERT_MANUAL
    @JOB_NUMBER  nvarchar(50),
    @MODEL_NAME  nvarchar(100),
    @LABEL       nvarchar(200) = NULL,
    @COOLING     nvarchar(100) = NULL,
    @OPTION_TEXT nvarchar(500) = NULL,
    @PAGE_SIZE   varchar(10)   = 'LETTER',
    @DOC_NUM     varchar(50)   = NULL,
    @USER_ID     varchar(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF (@MODEL_NAME IS NULL OR LTRIM(RTRIM(@MODEL_NAME)) = '')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'Model Name 은 필수입니다.';
        RETURN;
    END

    IF @LABEL   IS NOT NULL AND @LABEL   NOT IN (N'EXODUS', N'OEM')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'Label 값이 올바르지 않습니다.';
        RETURN;
    END

    IF @COOLING IS NOT NULL AND @COOLING NOT IN (N'AIR', N'LIQUID')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'Cooling 값이 올바르지 않습니다.';
        RETURN;
    END

    DECLARE @SEQ bigint = NEXT VALUE FOR dbo.SEQ_S_MANUAL;
    DECLARE @M_ID varchar(10) = 'M' + RIGHT('000000000' + CAST(@SEQ AS varchar(9)), 9);

    IF (@DOC_NUM IS NULL OR LTRIM(RTRIM(@DOC_NUM)) = '')
        SET @DOC_NUM = 'SM-' + FORMAT(GETDATE(), 'yy') + RIGHT('0000' + CAST(@SEQ AS varchar(9)), 4);

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.TB_S_MANUAL
            (M_ID, DOC_NUM, JOB_NUMBER, MODEL_NAME, LABEL, COOLING, OPTION_TEXT,
             REVISION, STATUS, PAGE_SIZE, REQUESTER_ID, REG_ID)
        VALUES
            (@M_ID, @DOC_NUM, @JOB_NUMBER, @MODEL_NAME, @LABEL, @COOLING, @OPTION_TEXT,
             'A', 'DRAFT', @PAGE_SIZE, @USER_ID, @USER_ID);

        INSERT INTO dbo.TB_S_MANUAL_MEMBER (M_ID, USER_ID, TEAM, MEMBER_ROLE, REG_ID)
        SELECT @M_ID, @USER_ID, u.TEAM, 'OWNER', @USER_ID
        FROM dbo.TB_S_USER u
        WHERE u.USER_ID = @USER_ID;

        -- 필수 목차만 자동으로 넣는다. 옵션은 편집기에서 골라 추가한다.
        INSERT INTO dbo.TB_S_SECTION
            (M_ID, ORDER_NUM, SEC_LEVEL, SEC_NO, TITLE, TPL_ID, ASSIGNED_TEAM, REG_ID)
        SELECT @M_ID,
               ROW_NUMBER() OVER (ORDER BY t.ORDER_NUM, t.TPL_ID),
               t.SEC_LEVEL, t.SEC_NO, t.TITLE, t.TPL_ID, t.ASSIGNED_TEAM, @USER_ID
        FROM dbo.TB_S_SECTION_TEMPLATE t
        WHERE t.IS_DELETED = 'N'
          AND t.IS_MANDATORY = 'Y'
          AND (t.LABEL   IS NULL OR t.LABEL   = @LABEL)
          AND (t.COOLING IS NULL OR t.COOLING = @COOLING);

        COMMIT TRANSACTION;
        SELECT Success = 1, ReturnMsg = CAST(@M_ID AS nvarchar(4000));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT Success = 0, ReturnMsg = ERROR_MESSAGE();
    END CATCH
END
GO

/* 목차 목록에 최종 수정자 포함 */
CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_SECTION_LIST
    @M_ID varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT s.SEC_ID, s.M_ID, s.ORDER_NUM, s.SEC_LEVEL, s.SEC_NO, s.TITLE,
           s.STYLE_JSON, s.TPL_ID,
           s.ASSIGNED_TEAM, s.ASSIGNED_USER_ID,
           ASSIGNED_NAME = au.FULL_NAME,
           EDITOR_NAME   = eu.FULL_NAME,
           s.SEC_STATUS,
           BLOCK_CNT = (SELECT COUNT(*) FROM dbo.TB_S_ELEMENT e
                        WHERE e.SEC_ID = s.SEC_ID AND e.IS_DELETED = 'N'),
           OPEN_CMT_CNT = (SELECT COUNT(*) FROM dbo.TB_S_COMMENT c
                           WHERE c.SEC_ID = s.SEC_ID AND c.IS_DELETED = 'N' AND c.IS_RESOLVED = 'N'),
           s.UPT_DT
    FROM dbo.TB_S_SECTION s
    LEFT JOIN dbo.TB_S_USER au ON au.USER_ID = s.ASSIGNED_USER_ID
    LEFT JOIN dbo.TB_S_USER eu ON eu.USER_ID = s.UPT_ID
    WHERE s.M_ID = @M_ID AND s.IS_DELETED = 'N'
    ORDER BY s.ORDER_NUM, s.SEC_ID;
END
GO

PRINT '11_template_team_only.sql 완료';
GO
