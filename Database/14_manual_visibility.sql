/* ============================================================
   14_manual_visibility.sql
   문서 목록/열람 범위를 다음 세 가지로 한정한다.

     1) 관리자(ADMIN) 와 읽기전용(READER) 역할
     2) 문서를 만든 사람(REQUESTER)
     3) 그 문서의 목차에 담당 팀으로 지정된 팀의 팀원

   발행(PUBLISHED) 문서를 전원에게 열어주던 규칙은 제거한다.
   (2번을 남긴 이유: 목차에 팀을 지정하기 전에는 만든 사람도
    자기 문서를 못 보게 되어 되돌릴 방법이 없다.)

   반복 실행 가능.
   ============================================================ */
SET NOCOUNT ON;
GO

CREATE OR ALTER FUNCTION dbo.UFN_S_CAN_READ_MANUAL (
    @M_ID    varchar(10),
    @USER_ID varchar(20)
)
RETURNS varchar(1)
AS
BEGIN
    IF @USER_ID IS NULL RETURN 'N';

    IF EXISTS (SELECT 1 FROM dbo.TB_S_ROLE
               WHERE USER_ID = @USER_ID AND IS_DELETED = 'N'
                 AND ROLE_NAME IN ('ADMIN', 'SUPPORTER', 'READER'))
        RETURN 'Y';

    IF EXISTS (SELECT 1 FROM dbo.TB_S_MANUAL
               WHERE M_ID = @M_ID AND REQUESTER_ID = @USER_ID AND IS_DELETED = 'N')
        RETURN 'Y';

    IF EXISTS (SELECT 1
               FROM dbo.TB_S_SECTION s
               INNER JOIN dbo.TB_S_USER u ON u.USER_ID = @USER_ID AND u.IS_DELETED = 'N'
               WHERE s.M_ID = @M_ID AND s.IS_DELETED = 'N'
                 AND s.ASSIGNED_TEAM IS NOT NULL
                 AND s.ASSIGNED_TEAM = u.TEAM)
        RETURN 'Y';

    RETURN 'N';
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_MANUAL_ACCESS
    @M_ID    varchar(10),
    @USER_ID varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ROLE varchar(20) = ISNULL((SELECT TOP 1 ROLE_NAME FROM dbo.TB_S_ROLE
                                        WHERE USER_ID = @USER_ID AND IS_DELETED = 'N'), 'USER');

    SELECT
        m.M_ID,
        m.STATUS,
        m.REQUESTER_ID,
        m.APPROVER_ID,
        MEMBER_ROLE = CASE WHEN m.REQUESTER_ID = @USER_ID THEN 'OWNER'
                           WHEN dbo.UFN_S_IS_MANUAL_PARTICIPANT(m.M_ID, @USER_ID) = 'Y' THEN 'EDITOR'
                           ELSE NULL END,
        USER_ROLE   = @ROLE,
        -- 문서 단위 CAN_EDIT 은 '편집기를 열 수 있는가'까지만 뜻한다.
        -- 실제 수정 가능 여부는 목차별 CAN_EDIT_SEC 이 결정한다.
        CAN_EDIT    = CASE
                        WHEN m.STATUS <> 'DRAFT' THEN 'N'
                        WHEN @ROLE = 'READER' THEN 'N'
                        WHEN dbo.UFN_S_IS_MANUAL_PARTICIPANT(m.M_ID, @USER_ID) = 'Y' THEN 'Y'
                        ELSE 'N'
                      END,
        CAN_READ    = dbo.UFN_S_CAN_READ_MANUAL(m.M_ID, @USER_ID)
    FROM dbo.TB_S_MANUAL m
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

    DECLARE @TEAM nvarchar(100) = (SELECT TEAM FROM dbo.TB_S_USER
                                   WHERE USER_ID = @USER_ID AND IS_DELETED = 'N');

    SELECT
        m.M_ID, m.DOC_NUM, m.JOB_NUMBER, m.MODEL_NAME, m.LABEL, m.COOLING, m.OPTION_TEXT,
        m.REVISION, m.STATUS,
        m.REQUESTER_ID, REQUESTER_NAME = ru.FULL_NAME,
        APPROVER_NAME = au.FULL_NAME,
        m.REQUEST_DATE, m.PUBLISH_DATE, m.REG_DT,
        MY_ROLE     = x.MY_ROLE,
        SECTION_CNT = (SELECT COUNT(*) FROM dbo.TB_S_SECTION s WHERE s.M_ID = m.M_ID AND s.IS_DELETED = 'N'),
        OPEN_CMT_CNT= (SELECT COUNT(*) FROM dbo.TB_S_COMMENT c WHERE c.M_ID = m.M_ID AND c.IS_DELETED = 'N' AND c.IS_RESOLVED = 'N')
    FROM dbo.TB_S_MANUAL m
    LEFT JOIN dbo.TB_S_USER ru ON ru.USER_ID = m.REQUESTER_ID
    LEFT JOIN dbo.TB_S_USER au ON au.USER_ID = m.APPROVER_ID
    CROSS APPLY (SELECT MY_ROLE = CASE
                    WHEN m.REQUESTER_ID = @USER_ID THEN 'OWNER'
                    WHEN @TEAM IS NOT NULL
                         AND EXISTS (SELECT 1 FROM dbo.TB_S_SECTION s
                                     WHERE s.M_ID = m.M_ID AND s.IS_DELETED = 'N'
                                       AND s.ASSIGNED_TEAM = @TEAM) THEN 'EDITOR'
                    ELSE NULL END) x
    WHERE m.IS_DELETED = 'N'
      AND (@STATUS IS NULL OR m.STATUS = @STATUS)
      AND (@START_DATE IS NULL OR m.REG_DT >= CONVERT(datetime, @START_DATE))
      AND (@END_DATE   IS NULL OR m.REG_DT <  DATEADD(DAY, 1, CONVERT(datetime, @END_DATE)))
      -- 목록에 보이는 조건과 실제 열람 권한을 같은 함수로 맞춘다.
      AND dbo.UFN_S_CAN_READ_MANUAL(m.M_ID, @USER_ID) = 'Y'
      AND (@ONLY_MINE <> 'Y' OR x.MY_ROLE IS NOT NULL)
    ORDER BY m.REG_DT DESC;
END
GO

/* 목차 자체(제목·번호·팀)도 담당이 아닌 사람은 못 바꾼다. */
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

    IF dbo.UFN_S_IS_MANUAL_PARTICIPANT(@M_ID, @USER_ID) <> 'Y'
    BEGIN
        SELECT Success = 0, ReturnMsg = N'이 문서를 수정할 권한이 없습니다.';
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

PRINT '14_manual_visibility.sql 완료';
GO
