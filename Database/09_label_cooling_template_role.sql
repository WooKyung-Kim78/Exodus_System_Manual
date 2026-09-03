/* ============================================================
   09_label_cooling_template_role.sql
   1) Label / Cooling 을 선택 목록으로 고정
   2) 목차 템플릿 (Label·Cooling 별, 필수/옵션)
   3) 사용자 역할 관리

   반복 실행 가능.
   ============================================================ */
SET NOCOUNT ON;
GO

/* ============================================================
   1. Label / Cooling 선택 값
      값은 아래 CHECK 제약과 화면 <select> 에서 직접 관리한다.
      공통 코드로는 넣지 않는다. 읽는 코드가 없어 고쳐도 반영되지 않는다.
   ============================================================ */

/* 기존 자유 입력 값이 남아 있을 수 있어 NOCHECK 으로 붙인다.
   새로 저장되는 값만 검증하고 과거 문서는 건드리지 않는다. */
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_TB_S_MANUAL_LABEL')
    ALTER TABLE dbo.TB_S_MANUAL DROP CONSTRAINT CK_TB_S_MANUAL_LABEL;
GO
ALTER TABLE dbo.TB_S_MANUAL WITH NOCHECK
    ADD CONSTRAINT CK_TB_S_MANUAL_LABEL CHECK (LABEL IS NULL OR LABEL IN (N'EXODUS', N'OEM'));
GO

IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_TB_S_MANUAL_COOLING')
    ALTER TABLE dbo.TB_S_MANUAL DROP CONSTRAINT CK_TB_S_MANUAL_COOLING;
GO
ALTER TABLE dbo.TB_S_MANUAL WITH NOCHECK
    ADD CONSTRAINT CK_TB_S_MANUAL_COOLING CHECK (COOLING IS NULL OR COOLING IN (N'AIR', N'LIQUID'));
GO

/* ============================================================
   2. 목차 템플릿
   ============================================================ */

IF OBJECT_ID('dbo.TB_S_SECTION_TEMPLATE', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.TB_S_SECTION_TEMPLATE (
        TPL_ID       bigint        IDENTITY(1,1) NOT NULL,
        -- NULL = 모든 Label / 모든 Cooling 에 공통 적용
        LABEL        nvarchar(20)  NULL,
        COOLING      nvarchar(20)  NULL,
        SEC_LEVEL    int           NOT NULL CONSTRAINT DF_TB_S_TPL_LEVEL DEFAULT (1),
        SEC_NO       nvarchar(20)  NULL,
        TITLE        nvarchar(200) NOT NULL,
        -- Y = 문서 생성 시 자동 삽입, N = 사용자가 필요할 때 추가
        IS_MANDATORY varchar(1)    NOT NULL CONSTRAINT DF_TB_S_TPL_MANDATORY DEFAULT ('Y'),
        ORDER_NUM    int           NOT NULL CONSTRAINT DF_TB_S_TPL_ORDER DEFAULT (0),
        IS_DELETED   varchar(1)    NOT NULL CONSTRAINT DF_TB_S_TPL_IS_DELETED DEFAULT ('N'),
        REG_ID       varchar(20)   NOT NULL,
        REG_DT       datetime      NOT NULL CONSTRAINT DF_TB_S_TPL_REG_DT DEFAULT (GETDATE()),
        UPT_ID       varchar(20)   NULL,
        UPT_DT       datetime      NULL,
        CONSTRAINT PK_TB_S_SECTION_TEMPLATE PRIMARY KEY CLUSTERED (TPL_ID),
        CONSTRAINT CK_TB_S_TPL_LEVEL CHECK (SEC_LEVEL BETWEEN 1 AND 3),
        CONSTRAINT CK_TB_S_TPL_MANDATORY CHECK (IS_MANDATORY IN ('Y', 'N')),
        CONSTRAINT CK_TB_S_TPL_LABEL CHECK (LABEL IS NULL OR LABEL IN (N'EXODUS', N'OEM')),
        CONSTRAINT CK_TB_S_TPL_COOLING CHECK (COOLING IS NULL OR COOLING IN (N'AIR', N'LIQUID'))
    );

    CREATE NONCLUSTERED INDEX IX_TB_S_TPL_SCOPE
        ON dbo.TB_S_SECTION_TEMPLATE (LABEL, COOLING, ORDER_NUM) WHERE IS_DELETED = 'N';
END
GO

/* 문서의 목차가 어느 템플릿에서 왔는지 기억해야 옵션 중복 추가를 막을 수 있다. */
IF COL_LENGTH('dbo.TB_S_SECTION', 'TPL_ID') IS NULL
    ALTER TABLE dbo.TB_S_SECTION ADD TPL_ID bigint NULL;
GO

/* ---------- 관리 화면용 목록 ---------- */
CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_SECTION_TEMPLATE_LIST
    @LABEL   nvarchar(20) = NULL,
    @COOLING nvarchar(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT t.TPL_ID, t.LABEL, t.COOLING, t.SEC_LEVEL, t.SEC_NO, t.TITLE,
           t.IS_MANDATORY, t.ORDER_NUM, t.REG_DT, t.UPT_DT
    FROM dbo.TB_S_SECTION_TEMPLATE t
    WHERE t.IS_DELETED = 'N'
      -- 조합을 고르면 그 조합에 실제로 적용되는 항목(공통 포함)을 보여준다.
      AND (@LABEL   IS NULL OR t.LABEL   IS NULL OR t.LABEL   = @LABEL)
      AND (@COOLING IS NULL OR t.COOLING IS NULL OR t.COOLING = @COOLING)
    ORDER BY t.ORDER_NUM, t.TPL_ID;
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_MERGE_SECTION_TEMPLATE
    @TPL_ID       bigint        = NULL,
    @LABEL        nvarchar(20)  = NULL,
    @COOLING      nvarchar(20)  = NULL,
    @SEC_LEVEL    int           = 1,
    @SEC_NO       nvarchar(20)  = NULL,
    @TITLE        nvarchar(200),
    @IS_MANDATORY varchar(1)    = 'Y',
    @ORDER_NUM    int           = NULL,
    @USER_ID      varchar(20)
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
    IF @LABEL   = N'' SET @LABEL   = NULL;
    IF @COOLING = N'' SET @COOLING = NULL;

    IF @TPL_ID IS NULL
    BEGIN
        IF @ORDER_NUM IS NULL OR @ORDER_NUM = 0
            SET @ORDER_NUM = ISNULL((SELECT MAX(ORDER_NUM) FROM dbo.TB_S_SECTION_TEMPLATE
                                     WHERE IS_DELETED = 'N'), 0) + 1;

        INSERT INTO dbo.TB_S_SECTION_TEMPLATE
            (LABEL, COOLING, SEC_LEVEL, SEC_NO, TITLE, IS_MANDATORY, ORDER_NUM, REG_ID)
        VALUES
            (@LABEL, @COOLING, @SEC_LEVEL, @SEC_NO, @TITLE, @IS_MANDATORY, @ORDER_NUM, @USER_ID);

        SELECT Success = 1, ReturnMsg = CAST(SCOPE_IDENTITY() AS nvarchar(4000));
        RETURN;
    END

    UPDATE dbo.TB_S_SECTION_TEMPLATE
    SET LABEL        = @LABEL,
        COOLING      = @COOLING,
        SEC_LEVEL    = @SEC_LEVEL,
        SEC_NO       = @SEC_NO,
        TITLE        = @TITLE,
        IS_MANDATORY = @IS_MANDATORY,
        ORDER_NUM    = ISNULL(@ORDER_NUM, ORDER_NUM),
        UPT_ID       = @USER_ID,
        UPT_DT       = GETDATE()
    WHERE TPL_ID = @TPL_ID AND IS_DELETED = 'N';

    IF @@ROWCOUNT = 0
    BEGIN
        SELECT Success = 0, ReturnMsg = N'템플릿 항목을 찾을 수 없습니다.';
        RETURN;
    END

    SELECT Success = 1, ReturnMsg = CAST(@TPL_ID AS nvarchar(4000));
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_DELETE_SECTION_TEMPLATE
    @TPL_ID  bigint,
    @USER_ID varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.TB_S_SECTION_TEMPLATE
    SET IS_DELETED = 'Y', UPT_ID = @USER_ID, UPT_DT = GETDATE()
    WHERE TPL_ID = @TPL_ID AND IS_DELETED = 'N';

    IF @@ROWCOUNT = 0
    BEGIN
        SELECT Success = 0, ReturnMsg = N'템플릿 항목을 찾을 수 없습니다.';
        RETURN;
    END

    SELECT Success = 1, ReturnMsg = N'OK';
END
GO

/* @ORDERS: 'TPL_ID:ORDER_NUM' 을 콤마로 이어붙인 문자열 */
CREATE OR ALTER PROCEDURE dbo.USP_S_UPDATE_SECTION_TEMPLATE_ORDER
    @ORDERS  nvarchar(max),
    @USER_ID varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH parsed AS (
        SELECT TPL_ID    = TRY_CAST(LEFT(value, CHARINDEX(':', value) - 1) AS bigint),
               ORDER_NUM = TRY_CAST(SUBSTRING(value, CHARINDEX(':', value) + 1, 20) AS int)
        FROM STRING_SPLIT(@ORDERS, ',')
        WHERE CHARINDEX(':', value) > 0
    )
    UPDATE t
    SET t.ORDER_NUM = p.ORDER_NUM,
        t.UPT_ID    = @USER_ID,
        t.UPT_DT    = GETDATE()
    FROM dbo.TB_S_SECTION_TEMPLATE t
    INNER JOIN parsed p ON p.TPL_ID = t.TPL_ID
    WHERE t.IS_DELETED = 'N';

    SELECT Success = 1, ReturnMsg = CAST(@@ROWCOUNT AS nvarchar(4000));
END
GO

/* ---------- 문서에서 아직 안 쓴 옵션 목차 ---------- */
CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_TEMPLATE_OPTION_LIST
    @M_ID varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LABEL nvarchar(20), @COOLING nvarchar(20);
    SELECT @LABEL = LABEL, @COOLING = COOLING
    FROM dbo.TB_S_MANUAL WHERE M_ID = @M_ID AND IS_DELETED = 'N';

    SELECT t.TPL_ID, t.LABEL, t.COOLING, t.SEC_LEVEL, t.SEC_NO, t.TITLE,
           t.IS_MANDATORY, t.ORDER_NUM
    FROM dbo.TB_S_SECTION_TEMPLATE t
    WHERE t.IS_DELETED = 'N'
      AND (t.LABEL   IS NULL OR t.LABEL   = @LABEL)
      AND (t.COOLING IS NULL OR t.COOLING = @COOLING)
      AND NOT EXISTS (SELECT 1 FROM dbo.TB_S_SECTION s
                      WHERE s.M_ID = @M_ID AND s.TPL_ID = t.TPL_ID AND s.IS_DELETED = 'N')
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

    INSERT INTO dbo.TB_S_SECTION (M_ID, ORDER_NUM, SEC_LEVEL, SEC_NO, TITLE, TPL_ID, REG_ID)
    SELECT @M_ID, @ORDER, t.SEC_LEVEL, t.SEC_NO, t.TITLE, t.TPL_ID, @USER_ID
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

/* ---------- 문서 생성 시 필수 목차 자동 삽입 ---------- */
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
        INSERT INTO dbo.TB_S_SECTION (M_ID, ORDER_NUM, SEC_LEVEL, SEC_NO, TITLE, TPL_ID, REG_ID)
        SELECT @M_ID,
               ROW_NUMBER() OVER (ORDER BY t.ORDER_NUM, t.TPL_ID),
               t.SEC_LEVEL, t.SEC_NO, t.TITLE, t.TPL_ID, @USER_ID
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

/* 목차 목록에 템플릿 출처를 포함시킨다. */
CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_SECTION_LIST
    @M_ID varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT s.SEC_ID, s.M_ID, s.ORDER_NUM, s.SEC_LEVEL, s.SEC_NO, s.TITLE,
           s.STYLE_JSON, s.TPL_ID,
           s.ASSIGNED_TEAM, s.ASSIGNED_USER_ID,
           ASSIGNED_NAME = u.FULL_NAME,
           s.SEC_STATUS,
           BLOCK_CNT = (SELECT COUNT(*) FROM dbo.TB_S_ELEMENT e
                        WHERE e.SEC_ID = s.SEC_ID AND e.IS_DELETED = 'N'),
           OPEN_CMT_CNT = (SELECT COUNT(*) FROM dbo.TB_S_COMMENT c
                           WHERE c.SEC_ID = s.SEC_ID AND c.IS_DELETED = 'N' AND c.IS_RESOLVED = 'N'),
           s.UPT_DT
    FROM dbo.TB_S_SECTION s
    LEFT JOIN dbo.TB_S_USER u ON u.USER_ID = s.ASSIGNED_USER_ID
    WHERE s.M_ID = @M_ID AND s.IS_DELETED = 'N'
    ORDER BY s.ORDER_NUM, s.SEC_ID;
END
GO

/* ============================================================
   3. 사용자 역할
   ============================================================ */

CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_USER_ROLE_LIST
    @KEYWORD nvarchar(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT u.USER_ID, u.FULL_NAME, u.DIVISION, u.TEAM, u.AUTHORIZED,
           ROLE_NAME = ISNULL(r.ROLE_NAME, 'USER'),
           r.UPT_DT
    FROM dbo.TB_S_USER u
    LEFT JOIN dbo.TB_S_ROLE r ON r.USER_ID = u.USER_ID AND r.IS_DELETED = 'N'
    WHERE u.IS_DELETED = 'N'
      AND (@KEYWORD IS NULL OR @KEYWORD = N''
           OR u.USER_ID LIKE '%' + @KEYWORD + '%'
           OR u.FULL_NAME LIKE N'%' + @KEYWORD + N'%'
           OR u.TEAM LIKE N'%' + @KEYWORD + N'%')
    ORDER BY u.FULL_NAME, u.USER_ID;
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_MERGE_USER_ROLE
    @USER_ID   varchar(20),
    @ROLE_NAME varchar(20),
    @UPT_ID    varchar(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @ROLE_NAME NOT IN ('ADMIN', 'USER', 'READER')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'역할 값이 올바르지 않습니다.';
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_USER WHERE USER_ID = @USER_ID AND IS_DELETED = 'N')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'사용자를 찾을 수 없습니다.';
        RETURN;
    END

    -- 마지막 관리자를 강등하면 아무도 권한을 되돌릴 수 없게 된다.
    IF @ROLE_NAME <> 'ADMIN'
       AND EXISTS (SELECT 1 FROM dbo.TB_S_ROLE WHERE USER_ID = @USER_ID AND ROLE_NAME = 'ADMIN' AND IS_DELETED = 'N')
       AND (SELECT COUNT(*) FROM dbo.TB_S_ROLE WHERE ROLE_NAME = 'ADMIN' AND IS_DELETED = 'N') <= 1
    BEGIN
        SELECT Success = 0, ReturnMsg = N'마지막 관리자는 역할을 바꿀 수 없습니다.';
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.TB_S_ROLE
        SET IS_DELETED = 'Y', UPT_ID = @UPT_ID, UPT_DT = GETDATE()
        WHERE USER_ID = @USER_ID AND IS_DELETED = 'N' AND ROLE_NAME <> @ROLE_NAME;

        IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_ROLE WHERE USER_ID = @USER_ID AND IS_DELETED = 'N')
            INSERT INTO dbo.TB_S_ROLE (USER_ID, ROLE_NAME, REG_ID) VALUES (@USER_ID, @ROLE_NAME, @UPT_ID);

        COMMIT TRANSACTION;
        SELECT Success = 1, ReturnMsg = N'OK';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT Success = 0, ReturnMsg = ERROR_MESSAGE();
    END CATCH
END
GO

PRINT '09_label_cooling_template_role.sql 완료';
GO
