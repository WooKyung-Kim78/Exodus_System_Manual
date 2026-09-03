/* ============================================================
   02_procedures.sql
   EXODUS System Manual — 저장 프로시저 (반복 실행 가능)

   반환 규약: 모든 쓰기 프로시저는 단일 행 (Success int, ReturnMsg nvarchar) 반환.
              신규 키가 생기는 경우 ReturnMsg 에 문자열로 담는다.
   ============================================================ */
SET NOCOUNT ON;
GO

/* M_ID 채번용 시퀀스 */
IF OBJECT_ID('dbo.SEQ_S_MANUAL', 'SO') IS NULL
    CREATE SEQUENCE dbo.SEQ_S_MANUAL AS bigint START WITH 1 INCREMENT BY 1;
GO

/* ============================================================
   공통: 문서 접근 권한 확인
   쓰기 API 는 반드시 이 프로시저를 먼저 통과시킨다.
   ============================================================ */
CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_MANUAL_ACCESS
    @M_ID    varchar(10),
    @USER_ID varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        m.M_ID,
        m.STATUS,
        m.REQUESTER_ID,
        m.APPROVER_ID,
        MEMBER_ROLE = mb.MEMBER_ROLE,
        USER_ROLE   = ISNULL(r.ROLE_NAME, 'USER'),
        CAN_EDIT    = CASE
                        WHEN m.STATUS <> 'DRAFT' THEN 'N'
                        WHEN mb.MEMBER_ROLE IS NOT NULL THEN 'Y'
                        WHEN ISNULL(r.ROLE_NAME, 'USER') = 'ADMIN' THEN 'Y'
                        ELSE 'N'
                      END,
        CAN_READ    = CASE
                        WHEN mb.MEMBER_ROLE IS NOT NULL THEN 'Y'
                        WHEN ISNULL(r.ROLE_NAME, 'USER') IN ('ADMIN', 'SUPPORTER', 'READER') THEN 'Y'
                        WHEN m.STATUS = 'PUBLISHED' THEN 'Y'
                        ELSE 'N'
                      END
    FROM dbo.TB_S_MANUAL m
    LEFT JOIN dbo.TB_S_MANUAL_MEMBER mb
           ON mb.M_ID = m.M_ID AND mb.USER_ID = @USER_ID AND mb.IS_DELETED = 'N'
    LEFT JOIN dbo.TB_S_ROLE r
           ON r.USER_ID = @USER_ID AND r.IS_DELETED = 'N'
    WHERE m.M_ID = @M_ID
      AND m.IS_DELETED = 'N';
END
GO

/* ============================================================
   문서 헤더
   ============================================================ */
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

        COMMIT TRANSACTION;
        SELECT Success = 1, ReturnMsg = CAST(@M_ID AS nvarchar(4000));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT Success = 0, ReturnMsg = ERROR_MESSAGE();
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_MANUAL
    @M_ID varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        m.M_ID, m.DOC_NUM, m.JOB_NUMBER, m.MODEL_NAME, m.LABEL, m.COOLING, m.OPTION_TEXT,
        m.REVISION, m.STATUS, m.PAGE_SIZE, m.PAGE_ORIENTATION,
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

CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_MANUAL_LIST_BY_STATUS
    @STATUS     varchar(20) = NULL,   -- NULL 이면 전체
    @USER_ID    varchar(20),
    @ONLY_MINE  varchar(1)  = 'N',
    @START_DATE varchar(10) = NULL,
    @END_DATE   varchar(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ROLE varchar(20) = ISNULL((SELECT TOP 1 ROLE_NAME FROM dbo.TB_S_ROLE
                                        WHERE USER_ID = @USER_ID AND IS_DELETED = 'N'), 'USER');

    SELECT
        m.M_ID, m.DOC_NUM, m.JOB_NUMBER, m.MODEL_NAME, m.LABEL, m.COOLING, m.OPTION_TEXT,
        m.REVISION, m.STATUS,
        m.REQUESTER_ID, REQUESTER_NAME = ru.FULL_NAME,
        APPROVER_NAME = au.FULL_NAME,
        m.REQUEST_DATE, m.PUBLISH_DATE, m.REG_DT,
        MY_ROLE     = mb.MEMBER_ROLE,
        SECTION_CNT = (SELECT COUNT(*) FROM dbo.TB_S_SECTION s WHERE s.M_ID = m.M_ID AND s.IS_DELETED = 'N'),
        OPEN_CMT_CNT= (SELECT COUNT(*) FROM dbo.TB_S_COMMENT c WHERE c.M_ID = m.M_ID AND c.IS_DELETED = 'N' AND c.IS_RESOLVED = 'N')
    FROM dbo.TB_S_MANUAL m
    LEFT JOIN dbo.TB_S_USER ru ON ru.USER_ID = m.REQUESTER_ID
    LEFT JOIN dbo.TB_S_USER au ON au.USER_ID = m.APPROVER_ID
    LEFT JOIN dbo.TB_S_MANUAL_MEMBER mb
           ON mb.M_ID = m.M_ID AND mb.USER_ID = @USER_ID AND mb.IS_DELETED = 'N'
    WHERE m.IS_DELETED = 'N'
      AND (@STATUS IS NULL OR m.STATUS = @STATUS)
      AND (@START_DATE IS NULL OR m.REG_DT >= CONVERT(datetime, @START_DATE))
      AND (@END_DATE   IS NULL OR m.REG_DT <  DATEADD(DAY, 1, CONVERT(datetime, @END_DATE)))
      AND (
            @ONLY_MINE = 'Y' AND mb.MEMBER_ROLE IS NOT NULL
            OR @ONLY_MINE <> 'Y' AND (mb.MEMBER_ROLE IS NOT NULL
                                      OR @ROLE IN ('ADMIN', 'SUPPORTER', 'READER')
                                      OR m.STATUS = 'PUBLISHED')
          )
    ORDER BY m.REG_DT DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_UPDATE_MANUAL_HEADER
    @M_ID        varchar(10),
    @JOB_NUMBER  nvarchar(50)  = NULL,
    @MODEL_NAME  nvarchar(100),
    @LABEL       nvarchar(200) = NULL,
    @COOLING     nvarchar(100) = NULL,
    @OPTION_TEXT nvarchar(500) = NULL,
    @PAGE_SIZE   varchar(10)   = NULL,
    @USER_ID     varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_MANUAL WHERE M_ID = @M_ID AND STATUS = 'DRAFT' AND IS_DELETED = 'N')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'작성(DRAFT) 상태의 문서만 수정할 수 있습니다.';
        RETURN;
    END

    UPDATE dbo.TB_S_MANUAL
    SET JOB_NUMBER  = @JOB_NUMBER,
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

CREATE OR ALTER PROCEDURE dbo.USP_S_UPDATE_MANUAL_STATUS
    @M_ID        varchar(10),
    @NEW_STATUS  varchar(20),
    @APPROVER_ID varchar(20) = NULL,
    @COMMENT     nvarchar(1000) = NULL,
    @USER_ID     varchar(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CUR varchar(20) = (SELECT STATUS FROM dbo.TB_S_MANUAL WHERE M_ID = @M_ID AND IS_DELETED = 'N');

    IF @CUR IS NULL
    BEGIN
        SELECT Success = 0, ReturnMsg = N'문서를 찾을 수 없습니다.';
        RETURN;
    END

    -- 허용된 전이만 통과시킨다.
    IF NOT (   (@CUR = 'DRAFT'     AND @NEW_STATUS = 'REVIEW')
            OR (@CUR = 'REVIEW'    AND @NEW_STATUS IN ('APPROVED', 'DRAFT'))
            OR (@CUR = 'APPROVED'  AND @NEW_STATUS = 'PUBLISHED')
            OR (@CUR = 'PUBLISHED' AND @NEW_STATUS = 'OBSOLETE'))
    BEGIN
        SELECT Success = 0, ReturnMsg = N'허용되지 않은 상태 전이입니다: ' + @CUR + N' → ' + @NEW_STATUS;
        RETURN;
    END

    IF @NEW_STATUS = 'REVIEW' AND @APPROVER_ID IS NULL
    BEGIN
        SELECT Success = 0, ReturnMsg = N'승인자를 지정해야 합니다.';
        RETURN;
    END

    IF @CUR = 'REVIEW' AND @NEW_STATUS IN ('APPROVED', 'DRAFT')
       AND NOT EXISTS (SELECT 1 FROM dbo.TB_S_MANUAL WHERE M_ID = @M_ID AND APPROVER_ID = @USER_ID)
    BEGIN
        SELECT Success = 0, ReturnMsg = N'지정된 승인자만 결재할 수 있습니다.';
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.TB_S_MANUAL
        SET STATUS        = @NEW_STATUS,
            APPROVER_ID   = CASE WHEN @NEW_STATUS = 'REVIEW' THEN @APPROVER_ID ELSE APPROVER_ID END,
            REQUEST_DATE  = CASE WHEN @NEW_STATUS = 'REVIEW'    THEN GETDATE() ELSE REQUEST_DATE  END,
            APPROVED_DATE = CASE WHEN @NEW_STATUS = 'APPROVED'  THEN GETDATE() ELSE APPROVED_DATE END,
            PUBLISH_DATE  = CASE WHEN @NEW_STATUS = 'PUBLISHED' THEN GETDATE() ELSE PUBLISH_DATE  END,
            OBSOLETE_DATE = CASE WHEN @NEW_STATUS = 'OBSOLETE'  THEN GETDATE() ELSE OBSOLETE_DATE END,
            UPT_ID        = @USER_ID,
            UPT_DT        = GETDATE()
        WHERE M_ID = @M_ID;

        INSERT INTO dbo.TB_S_ELEMENT_HISTORY (M_ID, ACTION, FIELD_NAME, BEFORE_VALUE, AFTER_VALUE, REG_ID)
        VALUES (@M_ID, 'UPDATE', 'STATUS', @CUR, @NEW_STATUS + ISNULL(N' / ' + @COMMENT, N''), @USER_ID);

        COMMIT TRANSACTION;
        SELECT Success = 1, ReturnMsg = N'OK';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT Success = 0, ReturnMsg = ERROR_MESSAGE();
    END CATCH
END
GO

/* ============================================================
   참여 멤버
   ============================================================ */
CREATE OR ALTER PROCEDURE dbo.USP_S_MERGE_MANUAL_MEMBER
    @M_ID         varchar(10),
    @TARGET_USER  varchar(20),
    @MEMBER_ROLE  varchar(20),
    @USER_ID      varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_USER WHERE USER_ID = @TARGET_USER AND IS_DELETED = 'N')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'사용자를 찾을 수 없습니다.';
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM dbo.TB_S_MANUAL_MEMBER
               WHERE M_ID = @M_ID AND USER_ID = @TARGET_USER AND IS_DELETED = 'N')
        UPDATE dbo.TB_S_MANUAL_MEMBER
        SET MEMBER_ROLE = @MEMBER_ROLE
        WHERE M_ID = @M_ID AND USER_ID = @TARGET_USER AND IS_DELETED = 'N';
    ELSE
        INSERT INTO dbo.TB_S_MANUAL_MEMBER (M_ID, USER_ID, TEAM, MEMBER_ROLE, REG_ID)
        SELECT @M_ID, @TARGET_USER, u.TEAM, @MEMBER_ROLE, @USER_ID
        FROM dbo.TB_S_USER u WHERE u.USER_ID = @TARGET_USER;

    SELECT Success = 1, ReturnMsg = N'OK';
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_MANUAL_MEMBER_LIST
    @M_ID varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT mb.IDX, mb.M_ID, mb.USER_ID, mb.MEMBER_ROLE,
           FULL_NAME = u.FULL_NAME, EMAIL = u.EMAIL,
           DIVISION = u.DIVISION, TEAM = ISNULL(mb.TEAM, u.TEAM)
    FROM dbo.TB_S_MANUAL_MEMBER mb
    INNER JOIN dbo.TB_S_USER u ON u.USER_ID = mb.USER_ID
    WHERE mb.M_ID = @M_ID AND mb.IS_DELETED = 'N'
    ORDER BY CASE mb.MEMBER_ROLE WHEN 'OWNER' THEN 0 WHEN 'APPROVER' THEN 1
                                 WHEN 'REVIEWER' THEN 2 ELSE 3 END, u.FULL_NAME;
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_DELETE_MANUAL_MEMBER
    @M_ID        varchar(10),
    @TARGET_USER varchar(20),
    @USER_ID     varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM dbo.TB_S_MANUAL_MEMBER
               WHERE M_ID = @M_ID AND USER_ID = @TARGET_USER AND MEMBER_ROLE = 'OWNER' AND IS_DELETED = 'N')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'문서 소유자는 제외할 수 없습니다.';
        RETURN;
    END

    UPDATE dbo.TB_S_MANUAL_MEMBER
    SET IS_DELETED = 'Y'
    WHERE M_ID = @M_ID AND USER_ID = @TARGET_USER AND IS_DELETED = 'N';

    SELECT Success = 1, ReturnMsg = N'OK';
END
GO

/* ============================================================
   섹션 보드
   ============================================================ */
CREATE OR ALTER PROCEDURE dbo.USP_S_MERGE_SECTION
    @SEC_ID           bigint        = NULL,
    @M_ID             varchar(10),
    @TITLE            nvarchar(200),
    @CANVAS_X         int           = NULL,
    @CANVAS_Y         int           = NULL,
    @BOARD_W          int           = NULL,
    @BOARD_H          int           = NULL,
    @ASSIGNED_TEAM    nvarchar(100) = NULL,
    @ASSIGNED_USER_ID varchar(20)   = NULL,
    @SEC_STATUS       varchar(20)   = NULL,
    @USER_ID          varchar(20)
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
        DECLARE @ORDER int = ISNULL((SELECT MAX(ORDER_NUM) FROM dbo.TB_S_SECTION
                                     WHERE M_ID = @M_ID AND IS_DELETED = 'N'), 0) + 1;

        INSERT INTO dbo.TB_S_SECTION
            (M_ID, ORDER_NUM, TITLE, CANVAS_X, CANVAS_Y, BOARD_W, BOARD_H,
             ASSIGNED_TEAM, ASSIGNED_USER_ID, REG_ID)
        VALUES
            (@M_ID, @ORDER, @TITLE, ISNULL(@CANVAS_X, 0), ISNULL(@CANVAS_Y, (@ORDER - 1) * 1120),
             ISNULL(@BOARD_W, 816), ISNULL(@BOARD_H, 1056),
             @ASSIGNED_TEAM, @ASSIGNED_USER_ID, @USER_ID);

        DECLARE @NEW_ID bigint = SCOPE_IDENTITY();

        INSERT INTO dbo.TB_S_ELEMENT_HISTORY (M_ID, SEC_ID, ACTION, FIELD_NAME, AFTER_VALUE, REG_ID)
        VALUES (@M_ID, @NEW_ID, 'CREATE', 'SECTION', @TITLE, @USER_ID);

        SELECT Success = 1, ReturnMsg = CAST(@NEW_ID AS nvarchar(4000));
        RETURN;
    END

    DECLARE @OLD_TITLE nvarchar(200) = (SELECT TITLE FROM dbo.TB_S_SECTION WHERE SEC_ID = @SEC_ID);

    UPDATE dbo.TB_S_SECTION
    SET TITLE            = @TITLE,
        CANVAS_X         = ISNULL(@CANVAS_X, CANVAS_X),
        CANVAS_Y         = ISNULL(@CANVAS_Y, CANVAS_Y),
        BOARD_W          = ISNULL(@BOARD_W, BOARD_W),
        BOARD_H          = ISNULL(@BOARD_H, BOARD_H),
        ASSIGNED_TEAM    = @ASSIGNED_TEAM,
        ASSIGNED_USER_ID = @ASSIGNED_USER_ID,
        SEC_STATUS       = ISNULL(@SEC_STATUS, SEC_STATUS),
        UPT_ID           = @USER_ID,
        UPT_DT           = GETDATE()
    WHERE SEC_ID = @SEC_ID AND M_ID = @M_ID AND IS_DELETED = 'N';

    IF @@ROWCOUNT = 0
    BEGIN
        SELECT Success = 0, ReturnMsg = N'섹션을 찾을 수 없습니다.';
        RETURN;
    END

    IF ISNULL(@OLD_TITLE, N'') <> @TITLE
        INSERT INTO dbo.TB_S_ELEMENT_HISTORY (M_ID, SEC_ID, ACTION, FIELD_NAME, BEFORE_VALUE, AFTER_VALUE, REG_ID)
        VALUES (@M_ID, @SEC_ID, 'UPDATE', 'TITLE', @OLD_TITLE, @TITLE, @USER_ID);

    SELECT Success = 1, ReturnMsg = CAST(@SEC_ID AS nvarchar(4000));
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_DELETE_SECTION
    @SEC_ID  bigint,
    @M_ID    varchar(10),
    @USER_ID varchar(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_MANUAL WHERE M_ID = @M_ID AND STATUS = 'DRAFT' AND IS_DELETED = 'N')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'작성(DRAFT) 상태의 문서만 수정할 수 있습니다.';
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.TB_S_ELEMENT
        SET IS_DELETED = 'Y', UPT_ID = @USER_ID, UPT_DT = GETDATE()
        WHERE SEC_ID = @SEC_ID AND IS_DELETED = 'N';

        UPDATE dbo.TB_S_SECTION
        SET IS_DELETED = 'Y', UPT_ID = @USER_ID, UPT_DT = GETDATE()
        WHERE SEC_ID = @SEC_ID AND M_ID = @M_ID AND IS_DELETED = 'N';

        INSERT INTO dbo.TB_S_ELEMENT_HISTORY (M_ID, SEC_ID, ACTION, FIELD_NAME, REG_ID)
        VALUES (@M_ID, @SEC_ID, 'DELETE', 'SECTION', @USER_ID);

        COMMIT TRANSACTION;
        SELECT Success = 1, ReturnMsg = N'OK';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT Success = 0, ReturnMsg = ERROR_MESSAGE();
    END CATCH
END
GO

/* @ORDERS: 'SEC_ID:ORDER_NUM' 을 콤마로 이어붙인 문자열 (예: '12:1,15:2,9:3') */
CREATE OR ALTER PROCEDURE dbo.USP_S_UPDATE_SECTION_ORDER
    @M_ID    varchar(10),
    @ORDERS  nvarchar(max),
    @USER_ID varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_MANUAL WHERE M_ID = @M_ID AND STATUS = 'DRAFT' AND IS_DELETED = 'N')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'작성(DRAFT) 상태의 문서만 수정할 수 있습니다.';
        RETURN;
    END

    ;WITH parsed AS (
        SELECT SEC_ID    = TRY_CAST(LEFT(value, CHARINDEX(':', value) - 1) AS bigint),
               ORDER_NUM = TRY_CAST(SUBSTRING(value, CHARINDEX(':', value) + 1, 20) AS int)
        FROM STRING_SPLIT(@ORDERS, ',')
        WHERE CHARINDEX(':', value) > 0
    )
    UPDATE s
    SET s.ORDER_NUM = p.ORDER_NUM,
        s.UPT_ID    = @USER_ID,
        s.UPT_DT    = GETDATE()
    FROM dbo.TB_S_SECTION s
    INNER JOIN parsed p ON p.SEC_ID = s.SEC_ID
    WHERE s.M_ID = @M_ID AND s.IS_DELETED = 'N';

    INSERT INTO dbo.TB_S_ELEMENT_HISTORY (M_ID, ACTION, FIELD_NAME, AFTER_VALUE, REG_ID)
    VALUES (@M_ID, 'REORDER', 'SECTION_ORDER', @ORDERS, @USER_ID);

    SELECT Success = 1, ReturnMsg = N'OK';
END
GO

/* ============================================================
   캔버스 요소
   ============================================================ */
CREATE OR ALTER PROCEDURE dbo.USP_S_MERGE_ELEMENT
    @ELE_ID       bigint        = NULL,
    @M_ID         varchar(10),
    @SEC_ID       bigint,
    @ELE_TYPE     varchar(20),
    @POS_X        float,
    @POS_Y        float,
    @WIDTH        float,
    @HEIGHT       float,
    @ROTATION     float         = 0,
    @Z_INDEX      int           = 0,
    @GROUP_ID     varchar(36)   = NULL,
    @CONTENT_HTML nvarchar(max) = NULL,   -- 반드시 서버에서 sanitize 후 전달
    @IMAGE_PATH   nvarchar(500) = NULL,
    @CAPTION      nvarchar(500) = NULL,
    @STYLE_JSON   nvarchar(max) = NULL,
    @ROW_VER      binary(8)     = NULL,
    @USER_ID      varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_MANUAL WHERE M_ID = @M_ID AND STATUS = 'DRAFT' AND IS_DELETED = 'N')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'작성(DRAFT) 상태의 문서만 수정할 수 있습니다.';
        RETURN;
    END

    IF @ELE_ID IS NULL
    BEGIN
        INSERT INTO dbo.TB_S_ELEMENT
            (M_ID, SEC_ID, ELE_TYPE, POS_X, POS_Y, WIDTH, HEIGHT, ROTATION, Z_INDEX,
             GROUP_ID, CONTENT_HTML, IMAGE_PATH, CAPTION, STYLE_JSON, REG_ID, UPT_ID, UPT_DT)
        VALUES
            (@M_ID, @SEC_ID, @ELE_TYPE, @POS_X, @POS_Y, @WIDTH, @HEIGHT, @ROTATION, @Z_INDEX,
             @GROUP_ID, @CONTENT_HTML, @IMAGE_PATH, @CAPTION, @STYLE_JSON, @USER_ID, @USER_ID, GETDATE());

        DECLARE @NEW_ELE bigint = SCOPE_IDENTITY();

        INSERT INTO dbo.TB_S_ELEMENT_HISTORY (M_ID, SEC_ID, ELE_ID, ACTION, FIELD_NAME, AFTER_VALUE, REG_ID)
        VALUES (@M_ID, @SEC_ID, @NEW_ELE, 'CREATE', 'ELEMENT', @ELE_TYPE, @USER_ID);

        SELECT Success = 1, ReturnMsg = CAST(@NEW_ELE AS nvarchar(4000));
        RETURN;
    END

    -- 낙관적 동시성: 클라이언트가 읽은 이후 다른 사용자가 먼저 저장했는지 확인
    IF @ROW_VER IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM dbo.TB_S_ELEMENT WHERE ELE_ID = @ELE_ID AND ROW_VER = @ROW_VER)
    BEGIN
        SELECT Success = 0, ReturnMsg = N'CONFLICT';
        RETURN;
    END

    UPDATE dbo.TB_S_ELEMENT
    SET POS_X        = @POS_X,
        POS_Y        = @POS_Y,
        WIDTH        = @WIDTH,
        HEIGHT       = @HEIGHT,
        ROTATION     = @ROTATION,
        Z_INDEX      = @Z_INDEX,
        GROUP_ID     = @GROUP_ID,
        CONTENT_HTML = @CONTENT_HTML,
        IMAGE_PATH   = @IMAGE_PATH,
        CAPTION      = @CAPTION,
        STYLE_JSON   = @STYLE_JSON,
        UPT_ID       = @USER_ID,
        UPT_DT       = GETDATE()
    WHERE ELE_ID = @ELE_ID AND M_ID = @M_ID AND IS_DELETED = 'N';

    IF @@ROWCOUNT = 0
    BEGIN
        SELECT Success = 0, ReturnMsg = N'요소를 찾을 수 없습니다.';
        RETURN;
    END

    INSERT INTO dbo.TB_S_ELEMENT_HISTORY (M_ID, SEC_ID, ELE_ID, ACTION, FIELD_NAME, AFTER_VALUE, REG_ID)
    VALUES (@M_ID, @SEC_ID, @ELE_ID, 'UPDATE', 'ELEMENT', @ELE_TYPE, @USER_ID);

    SELECT Success = 1, ReturnMsg = CAST(@ELE_ID AS nvarchar(4000));
END
GO

/* 다중 선택 드래그/리사이즈를 한 번에 반영.
   @ITEMS JSON 배열: [{"ELE_ID":1,"POS_X":0,"POS_Y":0,"WIDTH":10,"HEIGHT":10,"ROTATION":0,"Z_INDEX":0}] */
CREATE OR ALTER PROCEDURE dbo.USP_S_UPDATE_ELEMENT_TRANSFORM
    @M_ID    varchar(10),
    @ITEMS   nvarchar(max),
    @USER_ID varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_MANUAL WHERE M_ID = @M_ID AND STATUS = 'DRAFT' AND IS_DELETED = 'N')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'작성(DRAFT) 상태의 문서만 수정할 수 있습니다.';
        RETURN;
    END

    IF ISJSON(@ITEMS) <> 1
    BEGIN
        SELECT Success = 0, ReturnMsg = N'ITEMS 형식이 올바르지 않습니다.';
        RETURN;
    END

    UPDATE e
    SET e.POS_X    = p.POS_X,
        e.POS_Y    = p.POS_Y,
        e.WIDTH    = p.WIDTH,
        e.HEIGHT   = p.HEIGHT,
        e.ROTATION = p.ROTATION,
        e.Z_INDEX  = p.Z_INDEX,
        e.UPT_ID   = @USER_ID,
        e.UPT_DT   = GETDATE()
    FROM dbo.TB_S_ELEMENT e
    INNER JOIN OPENJSON(@ITEMS)
        WITH (
            ELE_ID   bigint '$.ELE_ID',
            POS_X    float  '$.POS_X',
            POS_Y    float  '$.POS_Y',
            WIDTH    float  '$.WIDTH',
            HEIGHT   float  '$.HEIGHT',
            ROTATION float  '$.ROTATION',
            Z_INDEX  int    '$.Z_INDEX'
        ) p ON p.ELE_ID = e.ELE_ID
    WHERE e.M_ID = @M_ID AND e.IS_DELETED = 'N';

    SELECT Success = 1, ReturnMsg = CAST(@@ROWCOUNT AS nvarchar(4000));
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_DELETE_ELEMENT
    @ELE_ID  bigint,
    @M_ID    varchar(10),
    @USER_ID varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_MANUAL WHERE M_ID = @M_ID AND STATUS = 'DRAFT' AND IS_DELETED = 'N')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'작성(DRAFT) 상태의 문서만 수정할 수 있습니다.';
        RETURN;
    END

    UPDATE dbo.TB_S_ELEMENT
    SET IS_DELETED = 'Y', UPT_ID = @USER_ID, UPT_DT = GETDATE()
    WHERE ELE_ID = @ELE_ID AND M_ID = @M_ID AND IS_DELETED = 'N';

    IF @@ROWCOUNT = 0
    BEGIN
        SELECT Success = 0, ReturnMsg = N'요소를 찾을 수 없습니다.';
        RETURN;
    END

    INSERT INTO dbo.TB_S_ELEMENT_HISTORY (M_ID, ELE_ID, ACTION, FIELD_NAME, REG_ID)
    VALUES (@M_ID, @ELE_ID, 'DELETE', 'ELEMENT', @USER_ID);

    SELECT Success = 1, ReturnMsg = N'OK';
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_MERGE_ELEMENT_TABLE_ROWS
    @ELE_ID  bigint,
    @ROWS    nvarchar(max),   -- JSON 배열: [{"ORDER_NUM":1,"ITEM":"","SPEC":"", ...}]
    @USER_ID varchar(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.TB_S_ELEMENT_TABLE_ROW SET IS_DELETED = 'Y' WHERE ELE_ID = @ELE_ID;

        INSERT INTO dbo.TB_S_ELEMENT_TABLE_ROW
            (ELE_ID, ORDER_NUM, ITEM, SPEC, UNIT, MIN_VAL, TYP_VAL, MAX_VAL, REMARK)
        SELECT @ELE_ID, j.ORDER_NUM, j.ITEM, j.SPEC, j.UNIT, j.MIN_VAL, j.TYP_VAL, j.MAX_VAL, j.REMARK
        FROM OPENJSON(@ROWS)
        WITH (
            ORDER_NUM int           '$.ORDER_NUM',
            ITEM      nvarchar(200) '$.ITEM',
            SPEC      nvarchar(500) '$.SPEC',
            UNIT      nvarchar(50)  '$.UNIT',
            MIN_VAL   nvarchar(50)  '$.MIN_VAL',
            TYP_VAL   nvarchar(50)  '$.TYP_VAL',
            MAX_VAL   nvarchar(50)  '$.MAX_VAL',
            REMARK    nvarchar(500) '$.REMARK'
        ) j;

        UPDATE dbo.TB_S_ELEMENT
        SET UPT_ID = @USER_ID, UPT_DT = GETDATE()
        WHERE ELE_ID = @ELE_ID;

        COMMIT TRANSACTION;
        SELECT Success = 1, ReturnMsg = N'OK';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT Success = 0, ReturnMsg = ERROR_MESSAGE();
    END CATCH
END
GO

/* ============================================================
   캔버스 조회 (전체 / 델타)
   ============================================================ */
CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_CANVAS
    @M_ID varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1) 섹션 보드
    SELECT s.SEC_ID, s.M_ID, s.ORDER_NUM, s.TITLE, s.CANVAS_X, s.CANVAS_Y, s.BOARD_W, s.BOARD_H,
           s.ASSIGNED_TEAM, s.ASSIGNED_USER_ID, ASSIGNED_NAME = u.FULL_NAME,
           s.SEC_STATUS, s.ROW_VER, s.UPT_DT
    FROM dbo.TB_S_SECTION s
    LEFT JOIN dbo.TB_S_USER u ON u.USER_ID = s.ASSIGNED_USER_ID
    WHERE s.M_ID = @M_ID AND s.IS_DELETED = 'N'
    ORDER BY s.ORDER_NUM;

    -- 2) 요소
    SELECT e.ELE_ID, e.M_ID, e.SEC_ID, e.ELE_TYPE, e.POS_X, e.POS_Y, e.WIDTH, e.HEIGHT,
           e.ROTATION, e.Z_INDEX, e.GROUP_ID, e.CONTENT_HTML, e.IMAGE_PATH, e.CAPTION,
           e.STYLE_JSON, e.ROW_VER, e.UPT_ID, e.UPT_DT
    FROM dbo.TB_S_ELEMENT e
    WHERE e.M_ID = @M_ID AND e.IS_DELETED = 'N'
    ORDER BY e.SEC_ID, e.Z_INDEX;

    -- 3) 스펙표 행
    SELECT r.ROW_ID, r.ELE_ID, r.ORDER_NUM, r.ITEM, r.SPEC, r.UNIT, r.MIN_VAL, r.TYP_VAL, r.MAX_VAL, r.REMARK
    FROM dbo.TB_S_ELEMENT_TABLE_ROW r
    INNER JOIN dbo.TB_S_ELEMENT e ON e.ELE_ID = r.ELE_ID
    WHERE e.M_ID = @M_ID AND e.IS_DELETED = 'N' AND r.IS_DELETED = 'N'
    ORDER BY r.ELE_ID, r.ORDER_NUM;
END
GO

/* 4초 주기 폴링. @CLIENT_ID 는 presence 갱신용이며, 자기 변경 필터링은 애플리케이션에서 UPT_ID 로 처리한다. */
CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_CANVAS_DELTA
    @M_ID     varchar(10),
    @SINCE_DT datetime
AS
BEGIN
    SET NOCOUNT ON;

    -- 삭제분도 함께 내려야 클라이언트에서 제거할 수 있으므로 IS_DELETED 를 필터하지 않는다.
    SELECT e.ELE_ID, e.M_ID, e.SEC_ID, e.ELE_TYPE, e.POS_X, e.POS_Y, e.WIDTH, e.HEIGHT,
           e.ROTATION, e.Z_INDEX, e.GROUP_ID, e.CONTENT_HTML, e.IMAGE_PATH, e.CAPTION,
           e.STYLE_JSON, e.IS_DELETED, e.ROW_VER, e.UPT_ID, e.UPT_DT
    FROM dbo.TB_S_ELEMENT e
    WHERE e.M_ID = @M_ID
      AND e.UPT_DT > @SINCE_DT;

    SELECT s.SEC_ID, s.M_ID, s.ORDER_NUM, s.TITLE, s.CANVAS_X, s.CANVAS_Y, s.BOARD_W, s.BOARD_H,
           s.ASSIGNED_TEAM, s.ASSIGNED_USER_ID, s.SEC_STATUS, s.IS_DELETED, s.ROW_VER, s.UPT_DT
    FROM dbo.TB_S_SECTION s
    WHERE s.M_ID = @M_ID
      AND ISNULL(s.UPT_DT, s.REG_DT) > @SINCE_DT;

    SELECT SERVER_DT = GETDATE();
END
GO

/* ============================================================
   접속 표시 (presence)
   ============================================================ */
CREATE OR ALTER PROCEDURE dbo.USP_S_UPSERT_PRESENCE
    @M_ID           varchar(10),
    @CLIENT_ID      varchar(36),
    @USER_ID        varchar(20),
    @SEC_ID         bigint = NULL,
    @EDITING_ELE_ID bigint = NULL
AS
BEGIN
    SET NOCOUNT ON;

    MERGE dbo.TB_S_PRESENCE AS t
    USING (SELECT @M_ID AS M_ID, @CLIENT_ID AS CLIENT_ID) AS s
       ON t.M_ID = s.M_ID AND t.CLIENT_ID = s.CLIENT_ID
    WHEN MATCHED THEN
        UPDATE SET USER_ID = @USER_ID, SEC_ID = @SEC_ID,
                   EDITING_ELE_ID = @EDITING_ELE_ID, LAST_PING_DT = GETDATE()
    WHEN NOT MATCHED THEN
        INSERT (M_ID, CLIENT_ID, USER_ID, SEC_ID, EDITING_ELE_ID, LAST_PING_DT)
        VALUES (@M_ID, @CLIENT_ID, @USER_ID, @SEC_ID, @EDITING_ELE_ID, GETDATE());

    DELETE FROM dbo.TB_S_PRESENCE
    WHERE M_ID = @M_ID AND LAST_PING_DT < DATEADD(SECOND, -30, GETDATE());

    SELECT Success = 1, ReturnMsg = N'OK';
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_PRESENCE
    @M_ID varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT p.CLIENT_ID, p.USER_ID, FULL_NAME = u.FULL_NAME,
           p.SEC_ID, p.EDITING_ELE_ID, p.LAST_PING_DT
    FROM dbo.TB_S_PRESENCE p
    INNER JOIN dbo.TB_S_USER u ON u.USER_ID = p.USER_ID
    WHERE p.M_ID = @M_ID
      AND p.LAST_PING_DT >= DATEADD(SECOND, -30, GETDATE());
END
GO

/* ============================================================
   변경이력
   ============================================================ */
CREATE OR ALTER PROCEDURE dbo.USP_S_INSERT_ELEMENT_HISTORY
    @M_ID         varchar(10),
    @SEC_ID       bigint        = NULL,
    @ELE_ID       bigint        = NULL,
    @ACTION       varchar(20),
    @FIELD_NAME   varchar(50)   = NULL,
    @BEFORE_VALUE nvarchar(max) = NULL,
    @AFTER_VALUE  nvarchar(max) = NULL,
    @USER_ID      varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.TB_S_ELEMENT_HISTORY (M_ID, SEC_ID, ELE_ID, ACTION, FIELD_NAME, BEFORE_VALUE, AFTER_VALUE, REG_ID)
    VALUES (@M_ID, @SEC_ID, @ELE_ID, @ACTION, @FIELD_NAME, @BEFORE_VALUE, @AFTER_VALUE, @USER_ID);

    SELECT Success = 1, ReturnMsg = N'OK';
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_ELEMENT_HISTORY
    @M_ID   varchar(10),
    @SEC_ID bigint = NULL,
    @ELE_ID bigint = NULL,
    @TOP    int    = 200
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@TOP)
           h.HIS_ID, h.M_ID, h.SEC_ID, h.ELE_ID, h.ACTION, h.FIELD_NAME,
           h.BEFORE_VALUE, h.AFTER_VALUE, h.REG_ID, REG_NAME = u.FULL_NAME, h.REG_DT
    FROM dbo.TB_S_ELEMENT_HISTORY h
    LEFT JOIN dbo.TB_S_USER u ON u.USER_ID = h.REG_ID
    WHERE h.M_ID = @M_ID
      AND (@SEC_ID IS NULL OR h.SEC_ID = @SEC_ID)
      AND (@ELE_ID IS NULL OR h.ELE_ID = @ELE_ID)
    ORDER BY h.REG_DT DESC, h.HIS_ID DESC;
END
GO

/* ============================================================
   코멘트
   ============================================================ */
CREATE OR ALTER PROCEDURE dbo.USP_S_INSERT_COMMENT
    @M_ID          varchar(10),
    @SEC_ID        bigint        = NULL,
    @ELE_ID        bigint        = NULL,
    @PIN_X         float         = NULL,
    @PIN_Y         float         = NULL,
    @PARENT_CMT_ID bigint        = NULL,
    @BODY          nvarchar(max),
    @USER_ID       varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF (@BODY IS NULL OR LTRIM(RTRIM(@BODY)) = '')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'내용을 입력하세요.';
        RETURN;
    END

    INSERT INTO dbo.TB_S_COMMENT (M_ID, SEC_ID, ELE_ID, PIN_X, PIN_Y, PARENT_CMT_ID, BODY, REG_ID)
    VALUES (@M_ID, @SEC_ID, @ELE_ID, @PIN_X, @PIN_Y, @PARENT_CMT_ID, @BODY, @USER_ID);

    SELECT Success = 1, ReturnMsg = CAST(SCOPE_IDENTITY() AS nvarchar(4000));
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_COMMENT_LIST
    @M_ID   varchar(10),
    @SEC_ID bigint = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT c.CMT_ID, c.M_ID, c.SEC_ID, c.ELE_ID, c.PIN_X, c.PIN_Y, c.PARENT_CMT_ID,
           c.BODY, c.IS_RESOLVED, c.REG_ID, REG_NAME = u.FULL_NAME, c.REG_DT
    FROM dbo.TB_S_COMMENT c
    LEFT JOIN dbo.TB_S_USER u ON u.USER_ID = c.REG_ID
    WHERE c.M_ID = @M_ID
      AND c.IS_DELETED = 'N'
      AND (@SEC_ID IS NULL OR c.SEC_ID = @SEC_ID)
    ORDER BY ISNULL(c.PARENT_CMT_ID, c.CMT_ID), c.CMT_ID;
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_UPDATE_COMMENT_RESOLVE
    @CMT_ID      bigint,
    @IS_RESOLVED varchar(1),
    @USER_ID     varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    -- 스레드 루트를 해결 처리하면 하위 답글도 함께 처리한다.
    UPDATE dbo.TB_S_COMMENT
    SET IS_RESOLVED = @IS_RESOLVED
    WHERE (CMT_ID = @CMT_ID OR PARENT_CMT_ID = @CMT_ID)
      AND IS_DELETED = 'N';

    SELECT Success = 1, ReturnMsg = N'OK';
END
GO

/* ============================================================
   메일 수신자 / 대시보드
   ============================================================ */
CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_EMAIL_RECIPIENT_LIST
    @M_ID varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT mb.MEMBER_ROLE AS USER_TYPE, mb.USER_ID,
           FULL_NAME = u.FULL_NAME, EMAIL_ADDRESS = u.EMAIL
    FROM dbo.TB_S_MANUAL_MEMBER mb
    INNER JOIN dbo.TB_S_USER u ON u.USER_ID = mb.USER_ID
    WHERE mb.M_ID = @M_ID
      AND mb.IS_DELETED = 'N'
      AND u.IS_DELETED = 'N'
      AND u.EMAIL IS NOT NULL;
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_MY_TASK_CNT
    @USER_ID varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        MY_DRAFT_CNT = (SELECT COUNT(*) FROM dbo.TB_S_MANUAL m
                        INNER JOIN dbo.TB_S_MANUAL_MEMBER mb ON mb.M_ID = m.M_ID AND mb.IS_DELETED = 'N'
                        WHERE mb.USER_ID = @USER_ID AND m.IS_DELETED = 'N' AND m.STATUS = 'DRAFT'),
        MY_REVIEW_CNT = (SELECT COUNT(*) FROM dbo.TB_S_MANUAL
                         WHERE APPROVER_ID = @USER_ID AND IS_DELETED = 'N' AND STATUS = 'REVIEW'),
        MY_PUBLISHED_CNT = (SELECT COUNT(*) FROM dbo.TB_S_MANUAL m
                            INNER JOIN dbo.TB_S_MANUAL_MEMBER mb ON mb.M_ID = m.M_ID AND mb.IS_DELETED = 'N'
                            WHERE mb.USER_ID = @USER_ID AND m.IS_DELETED = 'N' AND m.STATUS = 'PUBLISHED'),
        MY_OPEN_CMT_CNT = (SELECT COUNT(*) FROM dbo.TB_S_COMMENT c
                           INNER JOIN dbo.TB_S_MANUAL_MEMBER mb ON mb.M_ID = c.M_ID AND mb.IS_DELETED = 'N'
                           WHERE mb.USER_ID = @USER_ID AND c.IS_DELETED = 'N' AND c.IS_RESOLVED = 'N'
                             AND c.REG_ID <> @USER_ID);
END
GO

PRINT '02_procedures.sql 완료';
GO
