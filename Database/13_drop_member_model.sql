/* ============================================================
   13_drop_member_model.sql
   참여자(TB_S_MANUAL_MEMBER) 기반 권한을 목차 담당 팀 기반으로 교체한다.

     열람 : 관리자 / 읽기전용 역할 / 작성자(REQUESTER) / 목차에 지정된 팀 소속
            + 발행(PUBLISHED) 문서는 기존대로 전원 열람 가능
     수정 : 위 대상 중 DRAFT 상태에서, 목차에 팀이 지정되면 그 팀만

   TB_S_MANUAL_MEMBER 테이블 자체는 남겨둔다(과거 기록).
   더 이상 읽거나 쓰지 않는다.

   반복 실행 가능.
   ============================================================ */
SET NOCOUNT ON;
GO

/* 문서에 참여하는 팀인지 = 목차 중 하나라도 내 팀이 담당인지 */
CREATE OR ALTER FUNCTION dbo.UFN_S_IS_MANUAL_PARTICIPANT (
    @M_ID    varchar(10),
    @USER_ID varchar(20)
)
RETURNS varchar(1)
AS
BEGIN
    IF @USER_ID IS NULL RETURN 'N';

    IF EXISTS (SELECT 1 FROM dbo.TB_S_ROLE
               WHERE USER_ID = @USER_ID AND ROLE_NAME = 'ADMIN' AND IS_DELETED = 'N')
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

    -- 관리자와 작성자는 담당 팀이 비어 있는 목차도 정리할 수 있어야 한다.
    IF EXISTS (SELECT 1 FROM dbo.TB_S_ROLE
               WHERE USER_ID = @USER_ID AND ROLE_NAME = 'ADMIN' AND IS_DELETED = 'N')
        RETURN 'Y';

    IF EXISTS (SELECT 1 FROM dbo.TB_S_MANUAL
               WHERE M_ID = @M_ID AND REQUESTER_ID = @USER_ID AND IS_DELETED = 'N')
        RETURN 'Y';

    IF dbo.UFN_S_IS_MANUAL_PARTICIPANT(@M_ID, @USER_ID) <> 'Y' RETURN 'N';

    IF @TEAM IS NULL RETURN 'Y';

    IF EXISTS (SELECT 1 FROM dbo.TB_S_USER
               WHERE USER_ID = @USER_ID AND IS_DELETED = 'N' AND TEAM = @TEAM)
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
        CAN_EDIT    = CASE
                        WHEN m.STATUS <> 'DRAFT' THEN 'N'
                        WHEN dbo.UFN_S_IS_MANUAL_PARTICIPANT(m.M_ID, @USER_ID) = 'Y' THEN 'Y'
                        ELSE 'N'
                      END,
        CAN_READ    = CASE
                        WHEN dbo.UFN_S_IS_MANUAL_PARTICIPANT(m.M_ID, @USER_ID) = 'Y' THEN 'Y'
                        WHEN @ROLE IN ('ADMIN', 'SUPPORTER', 'READER') THEN 'Y'
                        WHEN m.STATUS = 'PUBLISHED' THEN 'Y'
                        ELSE 'N'
                      END
    FROM dbo.TB_S_MANUAL m
    WHERE m.M_ID = @M_ID
      AND m.IS_DELETED = 'N';
END
GO

/* 목록도 참여 팀 기준으로 거른다. */
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
      AND (
            @ONLY_MINE = 'Y' AND x.MY_ROLE IS NOT NULL
            OR @ONLY_MINE <> 'Y' AND (x.MY_ROLE IS NOT NULL
                                      OR @ROLE IN ('ADMIN', 'SUPPORTER', 'READER')
                                      OR m.STATUS = 'PUBLISHED')
          )
    ORDER BY m.REG_DT DESC;
END
GO

/* 수신자도 참여 팀 기준으로 뽑는다. */
CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_NOTIFY_RECIPIENT_LIST
    @M_ID varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT u.USER_ID,
           MEMBER_ROLE   = CASE WHEN m.REQUESTER_ID = u.USER_ID THEN 'OWNER' ELSE 'EDITOR' END,
           FULL_NAME     = u.FULL_NAME,
           EMAIL_ADDRESS = u.EMAIL,
           TEAM          = u.TEAM,
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
    FROM dbo.TB_S_MANUAL m
    INNER JOIN dbo.TB_S_USER u
            ON u.IS_DELETED = 'N'
           AND (u.USER_ID = m.REQUESTER_ID
                OR EXISTS (SELECT 1 FROM dbo.TB_S_SECTION s
                           WHERE s.M_ID = m.M_ID AND s.IS_DELETED = 'N'
                             AND s.ASSIGNED_TEAM = u.TEAM))
    WHERE m.M_ID = @M_ID
      AND m.IS_DELETED = 'N'
      AND u.EMAIL IS NOT NULL
      AND LTRIM(RTRIM(u.EMAIL)) <> ''
    ORDER BY CASE WHEN m.REQUESTER_ID = u.USER_ID THEN 0 ELSE 1 END, u.FULL_NAME;
END
GO

/* 문서 생성 시 참여자 행을 더 이상 만들지 않는다. */
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

DROP PROCEDURE IF EXISTS dbo.USP_S_SELECT_NOTIFY_ONE;
DROP PROCEDURE IF EXISTS dbo.USP_S_SELECT_MANUAL_MEMBER_LIST;
DROP PROCEDURE IF EXISTS dbo.USP_S_MERGE_MANUAL_MEMBER;
DROP PROCEDURE IF EXISTS dbo.USP_S_DELETE_MANUAL_MEMBER;
GO

PRINT '13_drop_member_model.sql 완료';
GO
