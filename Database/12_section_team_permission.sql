/* ============================================================
   12_section_team_permission.sql
   1) 목차에서 담당자(ASSIGNED_USER_ID) 제거 — 담당 팀만 사용
   2) 목차에 팀이 지정되면 그 팀 소속만 내용을 수정할 수 있다.
      관리자와 문서 소유자는 예외로 항상 수정할 수 있다.
      (아무도 손댈 수 없는 목차가 생기면 문서를 끝낼 방법이 없다.)

   반복 실행 가능.
   ============================================================ */
SET NOCOUNT ON;
GO

/* ---------- 목차 편집 권한 판정 ---------- */
CREATE OR ALTER FUNCTION dbo.UFN_S_CAN_EDIT_SECTION (
    @SEC_ID  bigint,
    @USER_ID varchar(20)
)
RETURNS varchar(1)
AS
BEGIN
    IF @USER_ID IS NULL RETURN 'N';

    DECLARE @M_ID varchar(10), @TEAM nvarchar(100);
    SELECT @M_ID = s.M_ID, @TEAM = s.ASSIGNED_TEAM
    FROM dbo.TB_S_SECTION s
    WHERE s.SEC_ID = @SEC_ID AND s.IS_DELETED = 'N';

    IF @M_ID IS NULL RETURN 'N';

    IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_MANUAL
                   WHERE M_ID = @M_ID AND STATUS = 'DRAFT' AND IS_DELETED = 'N')
        RETURN 'N';

    IF EXISTS (SELECT 1 FROM dbo.TB_S_ROLE
               WHERE USER_ID = @USER_ID AND ROLE_NAME = 'ADMIN' AND IS_DELETED = 'N')
        RETURN 'Y';

    IF EXISTS (SELECT 1 FROM dbo.TB_S_MANUAL_MEMBER
               WHERE M_ID = @M_ID AND USER_ID = @USER_ID AND MEMBER_ROLE = 'OWNER' AND IS_DELETED = 'N')
        RETURN 'Y';

    -- 여기부터는 문서 참여자여야 한다.
    IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_MANUAL_MEMBER
                   WHERE M_ID = @M_ID AND USER_ID = @USER_ID AND IS_DELETED = 'N')
        RETURN 'N';

    IF @TEAM IS NULL RETURN 'Y';

    IF EXISTS (SELECT 1 FROM dbo.TB_S_USER
               WHERE USER_ID = @USER_ID AND IS_DELETED = 'N' AND TEAM = @TEAM)
        RETURN 'Y';

    RETURN 'N';
END
GO

/* ---------- 목차 목록 ---------- */
CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_SECTION_LIST
    @M_ID    varchar(10),
    @USER_ID varchar(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT s.SEC_ID, s.M_ID, s.ORDER_NUM, s.SEC_LEVEL, s.SEC_NO, s.TITLE,
           s.STYLE_JSON, s.TPL_ID,
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

/* ---------- 목차 저장 (담당자 파라미터 제거) ---------- */
CREATE OR ALTER PROCEDURE dbo.USP_S_MERGE_SECTION
    @SEC_ID        bigint        = NULL,
    @M_ID          varchar(10),
    @TITLE         nvarchar(200),
    @SEC_LEVEL     int           = 1,
    @SEC_NO        nvarchar(20)  = NULL,
    @ASSIGNED_TEAM nvarchar(100) = NULL,
    @SEC_STATUS    varchar(20)   = NULL,
    @STYLE_JSON    nvarchar(max) = NULL,
    @USER_ID       varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_MANUAL WHERE M_ID = @M_ID AND STATUS = 'DRAFT' AND IS_DELETED = 'N')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'작성(DRAFT) 상태의 문서만 수정할 수 있습니다.';
        RETURN;
    END

    IF @SEC_LEVEL NOT BETWEEN 1 AND 3 SET @SEC_LEVEL = 1;
    IF @ASSIGNED_TEAM = N'' SET @ASSIGNED_TEAM = NULL;

    IF @STYLE_JSON = N'' OR (@STYLE_JSON IS NOT NULL AND ISJSON(@STYLE_JSON) <> 1)
        SET @STYLE_JSON = NULL;

    IF @SEC_ID IS NULL
    BEGIN
        DECLARE @ORDER int = ISNULL((SELECT MAX(ORDER_NUM) FROM dbo.TB_S_SECTION
                                     WHERE M_ID = @M_ID AND IS_DELETED = 'N'), 0) + 1;

        INSERT INTO dbo.TB_S_SECTION
            (M_ID, ORDER_NUM, SEC_LEVEL, SEC_NO, TITLE, STYLE_JSON, ASSIGNED_TEAM, REG_ID)
        VALUES
            (@M_ID, @ORDER, @SEC_LEVEL, @SEC_NO, @TITLE, @STYLE_JSON, @ASSIGNED_TEAM, @USER_ID);

        DECLARE @NEW_ID bigint = SCOPE_IDENTITY();

        INSERT INTO dbo.TB_S_ELEMENT_HISTORY (M_ID, SEC_ID, ACTION, FIELD_NAME, AFTER_VALUE, REG_ID)
        VALUES (@M_ID, @NEW_ID, 'CREATE', 'SECTION', @TITLE, @USER_ID);

        SELECT Success = 1, ReturnMsg = CAST(@NEW_ID AS nvarchar(4000));
        RETURN;
    END

    DECLARE @OLD_TITLE nvarchar(200) = (SELECT TITLE FROM dbo.TB_S_SECTION WHERE SEC_ID = @SEC_ID);

    UPDATE dbo.TB_S_SECTION
    SET TITLE         = @TITLE,
        SEC_LEVEL     = @SEC_LEVEL,
        SEC_NO        = @SEC_NO,
        STYLE_JSON    = @STYLE_JSON,
        ASSIGNED_TEAM = @ASSIGNED_TEAM,
        SEC_STATUS    = ISNULL(@SEC_STATUS, SEC_STATUS),
        UPT_ID        = @USER_ID,
        UPT_DT        = GETDATE()
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

/* ---------- 블록 저장: 목차 팀 권한 확인 ---------- */
CREATE OR ALTER PROCEDURE dbo.USP_S_MERGE_ELEMENT
    @ELE_ID       bigint        = NULL,
    @M_ID         varchar(10),
    @SEC_ID       bigint,
    @ELE_TYPE     varchar(20),
    @ORDER_NUM    int           = 0,
    @WIDTH        float         = 0,
    @HEIGHT       float         = 0,
    @CONTENT_HTML nvarchar(max) = NULL,   -- 반드시 서버에서 sanitize 후 전달
    @IMAGE_PATH   nvarchar(500) = NULL,
    @CAPTION      nvarchar(500) = NULL,
    @STYLE_JSON   nvarchar(max) = NULL,
    @ROW_VER      binary(8)     = NULL,
    @USER_ID      varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF dbo.UFN_S_CAN_EDIT_SECTION(@SEC_ID, @USER_ID) <> 'Y'
    BEGIN
        SELECT Success = 0, ReturnMsg = N'이 목차는 담당 팀만 수정할 수 있습니다.';
        RETURN;
    END

    IF @ELE_ID IS NULL
    BEGIN
        IF @ORDER_NUM = 0
            SET @ORDER_NUM = ISNULL((SELECT MAX(ORDER_NUM) FROM dbo.TB_S_ELEMENT
                                     WHERE SEC_ID = @SEC_ID AND IS_DELETED = 'N'), 0) + 1;

        INSERT INTO dbo.TB_S_ELEMENT
            (M_ID, SEC_ID, ELE_TYPE, ORDER_NUM, WIDTH, HEIGHT,
             CONTENT_HTML, IMAGE_PATH, CAPTION, STYLE_JSON, REG_ID, UPT_ID, UPT_DT)
        VALUES
            (@M_ID, @SEC_ID, @ELE_TYPE, @ORDER_NUM, @WIDTH, @HEIGHT,
             @CONTENT_HTML, @IMAGE_PATH, @CAPTION, @STYLE_JSON, @USER_ID, @USER_ID, GETDATE());

        DECLARE @NEW_ELE bigint = SCOPE_IDENTITY();

        UPDATE dbo.TB_S_SECTION SET UPT_ID = @USER_ID, UPT_DT = GETDATE() WHERE SEC_ID = @SEC_ID;

        INSERT INTO dbo.TB_S_ELEMENT_HISTORY (M_ID, SEC_ID, ELE_ID, ACTION, FIELD_NAME, AFTER_VALUE, REG_ID)
        VALUES (@M_ID, @SEC_ID, @NEW_ELE, 'CREATE', 'BLOCK', @ELE_TYPE, @USER_ID);

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
    SET ORDER_NUM    = @ORDER_NUM,
        WIDTH        = @WIDTH,
        HEIGHT       = @HEIGHT,
        CONTENT_HTML = @CONTENT_HTML,
        IMAGE_PATH   = @IMAGE_PATH,
        CAPTION      = @CAPTION,
        STYLE_JSON   = @STYLE_JSON,
        UPT_ID       = @USER_ID,
        UPT_DT       = GETDATE()
    WHERE ELE_ID = @ELE_ID AND M_ID = @M_ID AND IS_DELETED = 'N';

    IF @@ROWCOUNT = 0
    BEGIN
        SELECT Success = 0, ReturnMsg = N'블록을 찾을 수 없습니다.';
        RETURN;
    END

    UPDATE dbo.TB_S_SECTION SET UPT_ID = @USER_ID, UPT_DT = GETDATE() WHERE SEC_ID = @SEC_ID;

    INSERT INTO dbo.TB_S_ELEMENT_HISTORY (M_ID, SEC_ID, ELE_ID, ACTION, FIELD_NAME, AFTER_VALUE, REG_ID)
    VALUES (@M_ID, @SEC_ID, @ELE_ID, 'UPDATE', 'BLOCK', @ELE_TYPE, @USER_ID);

    SELECT Success = 1, ReturnMsg = CAST(@ELE_ID AS nvarchar(4000));
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_DELETE_ELEMENT
    @ELE_ID  bigint,
    @M_ID    varchar(10),
    @USER_ID varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SEC_ID bigint = (SELECT SEC_ID FROM dbo.TB_S_ELEMENT
                              WHERE ELE_ID = @ELE_ID AND M_ID = @M_ID AND IS_DELETED = 'N');

    IF @SEC_ID IS NULL
    BEGIN
        SELECT Success = 0, ReturnMsg = N'요소를 찾을 수 없습니다.';
        RETURN;
    END

    IF dbo.UFN_S_CAN_EDIT_SECTION(@SEC_ID, @USER_ID) <> 'Y'
    BEGIN
        SELECT Success = 0, ReturnMsg = N'이 목차는 담당 팀만 수정할 수 있습니다.';
        RETURN;
    END

    UPDATE dbo.TB_S_ELEMENT
    SET IS_DELETED = 'Y', UPT_ID = @USER_ID, UPT_DT = GETDATE()
    WHERE ELE_ID = @ELE_ID AND M_ID = @M_ID AND IS_DELETED = 'N';

    UPDATE dbo.TB_S_SECTION SET UPT_ID = @USER_ID, UPT_DT = GETDATE() WHERE SEC_ID = @SEC_ID;

    INSERT INTO dbo.TB_S_ELEMENT_HISTORY (M_ID, SEC_ID, ELE_ID, ACTION, FIELD_NAME, REG_ID)
    VALUES (@M_ID, @SEC_ID, @ELE_ID, 'DELETE', 'ELEMENT', @USER_ID);

    SELECT Success = 1, ReturnMsg = N'OK';
END
GO

/* @ORDERS: 'ELE_ID:ORDER_NUM' 을 콤마로 이어붙인 문자열 */
CREATE OR ALTER PROCEDURE dbo.USP_S_UPDATE_ELEMENT_ORDER
    @M_ID    varchar(10),
    @ORDERS  nvarchar(max),
    @USER_ID varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH parsed AS (
        SELECT ELE_ID    = TRY_CAST(LEFT(value, CHARINDEX(':', value) - 1) AS bigint),
               ORDER_NUM = TRY_CAST(SUBSTRING(value, CHARINDEX(':', value) + 1, 20) AS int)
        FROM STRING_SPLIT(@ORDERS, ',')
        WHERE CHARINDEX(':', value) > 0
    )
    UPDATE e
    SET e.ORDER_NUM = p.ORDER_NUM,
        e.UPT_ID    = @USER_ID,
        e.UPT_DT    = GETDATE()
    FROM dbo.TB_S_ELEMENT e
    INNER JOIN parsed p ON p.ELE_ID = e.ELE_ID
    WHERE e.M_ID = @M_ID
      AND e.IS_DELETED = 'N'
      AND dbo.UFN_S_CAN_EDIT_SECTION(e.SEC_ID, @USER_ID) = 'Y';

    IF @@ROWCOUNT = 0
    BEGIN
        SELECT Success = 0, ReturnMsg = N'이 목차는 담당 팀만 수정할 수 있습니다.';
        RETURN;
    END

    SELECT Success = 1, ReturnMsg = N'OK';
END
GO

/* 목차 자체를 지우는 것도 담당 팀(또는 소유자/관리자)만 */
CREATE OR ALTER PROCEDURE dbo.USP_S_DELETE_SECTION
    @SEC_ID  bigint,
    @M_ID    varchar(10),
    @USER_ID varchar(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF dbo.UFN_S_CAN_EDIT_SECTION(@SEC_ID, @USER_ID) <> 'Y'
    BEGIN
        SELECT Success = 0, ReturnMsg = N'이 목차는 담당 팀만 수정할 수 있습니다.';
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

/* 담당 섹션은 이제 팀 기준이다. 두 프로시저 모두 같은 결과 모델을 쓰므로 컬럼을 맞춘다. */
CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_NOTIFY_RECIPIENT_LIST
    @M_ID varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT mb.USER_ID,
           mb.MEMBER_ROLE,
           FULL_NAME     = u.FULL_NAME,
           EMAIL_ADDRESS = u.EMAIL,
           TEAM          = ISNULL(mb.TEAM, u.TEAM),
           SECTION_CNT   = (SELECT COUNT(*) FROM dbo.TB_S_SECTION s
                            WHERE s.M_ID = @M_ID AND s.IS_DELETED = 'N'
                              AND s.ASSIGNED_TEAM IS NOT NULL
                              AND s.ASSIGNED_TEAM = u.TEAM),
           ASSIGNED_SECTIONS = STUFF((
                SELECT N' / ' + CAST(s.ORDER_NUM AS nvarchar(10)) + N'. ' + s.TITLE
                FROM dbo.TB_S_SECTION s
                WHERE s.M_ID = @M_ID AND s.IS_DELETED = 'N'
                  AND s.ASSIGNED_TEAM IS NOT NULL
                  AND s.ASSIGNED_TEAM = u.TEAM
                ORDER BY s.ORDER_NUM
                FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 3, N'')
    FROM dbo.TB_S_MANUAL_MEMBER mb
    INNER JOIN dbo.TB_S_USER u ON u.USER_ID = mb.USER_ID
    WHERE mb.M_ID = @M_ID
      AND mb.IS_DELETED = 'N'
      AND u.IS_DELETED = 'N'
      AND u.EMAIL IS NOT NULL
      AND LTRIM(RTRIM(u.EMAIL)) <> ''
    ORDER BY CASE mb.MEMBER_ROLE WHEN 'OWNER' THEN 0 WHEN 'APPROVER' THEN 1
                                 WHEN 'REVIEWER' THEN 2 ELSE 3 END, u.FULL_NAME;
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_NOTIFY_ONE
    @M_ID    varchar(10),
    @USER_ID varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT mb.USER_ID,
           mb.MEMBER_ROLE,
           FULL_NAME     = u.FULL_NAME,
           EMAIL_ADDRESS = u.EMAIL,
           TEAM          = ISNULL(mb.TEAM, u.TEAM),
           SECTION_CNT   = (SELECT COUNT(*) FROM dbo.TB_S_SECTION s
                            WHERE s.M_ID = @M_ID AND s.IS_DELETED = 'N'
                              AND s.ASSIGNED_TEAM IS NOT NULL
                              AND s.ASSIGNED_TEAM = u.TEAM),
           ASSIGNED_SECTIONS = STUFF((
                SELECT N' / ' + CAST(s.ORDER_NUM AS nvarchar(10)) + N'. ' + s.TITLE
                FROM dbo.TB_S_SECTION s
                WHERE s.M_ID = @M_ID AND s.IS_DELETED = 'N'
                  AND s.ASSIGNED_TEAM IS NOT NULL
                  AND s.ASSIGNED_TEAM = u.TEAM
                ORDER BY s.ORDER_NUM
                FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 3, N'')
    FROM dbo.TB_S_MANUAL_MEMBER mb
    INNER JOIN dbo.TB_S_USER u ON u.USER_ID = mb.USER_ID
    WHERE mb.M_ID = @M_ID
      AND mb.USER_ID = @USER_ID
      AND mb.IS_DELETED = 'N'
      AND u.IS_DELETED = 'N';
END
GO

/* 마지막에 컬럼을 지운다. 위 프로시저들이 더 이상 참조하지 않는다. */
IF COL_LENGTH('dbo.TB_S_SECTION', 'ASSIGNED_USER_ID') IS NOT NULL
    ALTER TABLE dbo.TB_S_SECTION DROP COLUMN ASSIGNED_USER_ID;
GO

PRINT '12_section_team_permission.sql 완료';
GO
