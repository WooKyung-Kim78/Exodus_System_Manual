/* ============================================================
   07_alter_document_model.sql
   캔버스(자유 좌표) → 문서형(목차 계층 + 순서 블록) 전환 (반복 실행 가능)

   변경 요약
     - 섹션에 LEVEL(1=대,2=중,3=소) 과 수동 번호 SEC_NO 추가
       계층 그룹은 ORDER_NUM 순서 + LEVEL 로 파생한다 (Word 아웃라인과 동일 방식).
       PARENT_SEC_ID 를 따로 두면 순서 변경 때마다 부모 재계산이 필요해 어긋나기 쉽다.
     - 블록에 ORDER_NUM 추가 (POS_X/POS_Y/Z_INDEX 는 더 이상 쓰지 않음)
     - 도형/선 제거, 블록 타입은 TEXT / IMAGE / TABLE
     - 문서에 레벨별 제목 스타일(HEADING_STYLE_JSON) 추가
   ============================================================ */
SET NOCOUNT ON;
GO

/* ---------- 섹션: 계층 + 번호 ---------- */
IF COL_LENGTH('dbo.TB_S_SECTION', 'SEC_LEVEL') IS NULL
    ALTER TABLE dbo.TB_S_SECTION ADD SEC_LEVEL int NOT NULL CONSTRAINT DF_TB_S_SECTION_LEVEL DEFAULT (1);
GO
IF COL_LENGTH('dbo.TB_S_SECTION', 'SEC_NO') IS NULL
    ALTER TABLE dbo.TB_S_SECTION ADD SEC_NO nvarchar(20) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_TB_S_SECTION_LEVEL')
    ALTER TABLE dbo.TB_S_SECTION ADD CONSTRAINT CK_TB_S_SECTION_LEVEL CHECK (SEC_LEVEL BETWEEN 1 AND 3);
GO

/* ---------- 블록: 순서 ---------- */
IF COL_LENGTH('dbo.TB_S_ELEMENT', 'ORDER_NUM') IS NULL
    ALTER TABLE dbo.TB_S_ELEMENT ADD ORDER_NUM int NOT NULL CONSTRAINT DF_TB_S_ELEMENT_ORDER DEFAULT (0);
GO

-- 기존 캔버스 데이터의 Z_INDEX 를 순서로 옮긴다.
UPDATE dbo.TB_S_ELEMENT SET ORDER_NUM = Z_INDEX WHERE ORDER_NUM = 0 AND Z_INDEX > 0;
GO

-- 도형/선은 더 이상 쓰지 않으므로 정리한 뒤 제약을 조인다.
UPDATE dbo.TB_S_ELEMENT SET IS_DELETED = 'Y' WHERE ELE_TYPE IN ('SHAPE', 'LINE');
GO
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_TB_S_ELE_TYPE')
    ALTER TABLE dbo.TB_S_ELEMENT DROP CONSTRAINT CK_TB_S_ELE_TYPE;
GO
ALTER TABLE dbo.TB_S_ELEMENT WITH NOCHECK
    ADD CONSTRAINT CK_TB_S_ELE_TYPE CHECK (ELE_TYPE IN ('TEXT', 'IMAGE', 'TABLE'));
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_TB_S_ELEMENT_ORDER' AND object_id = OBJECT_ID('dbo.TB_S_ELEMENT'))
    CREATE NONCLUSTERED INDEX IX_TB_S_ELEMENT_ORDER ON dbo.TB_S_ELEMENT (SEC_ID, ORDER_NUM) WHERE IS_DELETED = 'N';
GO

/* ---------- 문서: 레벨별 제목 스타일 ---------- */
IF COL_LENGTH('dbo.TB_S_MANUAL', 'HEADING_STYLE_JSON') IS NULL
    ALTER TABLE dbo.TB_S_MANUAL ADD HEADING_STYLE_JSON nvarchar(max) NULL;
GO

/* ============================================================
   프로시저 개정
   ============================================================ */

CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_SECTION_LIST
    @M_ID varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT s.SEC_ID, s.M_ID, s.ORDER_NUM, s.SEC_LEVEL, s.SEC_NO, s.TITLE,
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

CREATE OR ALTER PROCEDURE dbo.USP_S_MERGE_SECTION
    @SEC_ID           bigint        = NULL,
    @M_ID             varchar(10),
    @TITLE            nvarchar(200),
    @SEC_LEVEL        int           = 1,
    @SEC_NO           nvarchar(20)  = NULL,
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

    IF @SEC_LEVEL NOT BETWEEN 1 AND 3 SET @SEC_LEVEL = 1;

    IF @SEC_ID IS NULL
    BEGIN
        DECLARE @ORDER int = ISNULL((SELECT MAX(ORDER_NUM) FROM dbo.TB_S_SECTION
                                     WHERE M_ID = @M_ID AND IS_DELETED = 'N'), 0) + 1;

        INSERT INTO dbo.TB_S_SECTION
            (M_ID, ORDER_NUM, SEC_LEVEL, SEC_NO, TITLE, ASSIGNED_TEAM, ASSIGNED_USER_ID, REG_ID)
        VALUES
            (@M_ID, @ORDER, @SEC_LEVEL, @SEC_NO, @TITLE, @ASSIGNED_TEAM, @ASSIGNED_USER_ID, @USER_ID);

        DECLARE @NEW_ID bigint = SCOPE_IDENTITY();

        INSERT INTO dbo.TB_S_ELEMENT_HISTORY (M_ID, SEC_ID, ACTION, FIELD_NAME, AFTER_VALUE, REG_ID)
        VALUES (@M_ID, @NEW_ID, 'CREATE', 'SECTION', @TITLE, @USER_ID);

        SELECT Success = 1, ReturnMsg = CAST(@NEW_ID AS nvarchar(4000));
        RETURN;
    END

    DECLARE @OLD_TITLE nvarchar(200) = (SELECT TITLE FROM dbo.TB_S_SECTION WHERE SEC_ID = @SEC_ID);

    UPDATE dbo.TB_S_SECTION
    SET TITLE            = @TITLE,
        SEC_LEVEL        = @SEC_LEVEL,
        SEC_NO           = @SEC_NO,
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

CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_ELEMENT_LIST
    @M_ID   varchar(10),
    @SEC_ID bigint = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT e.ELE_ID, e.M_ID, e.SEC_ID, e.ELE_TYPE, e.ORDER_NUM,
           e.WIDTH, e.HEIGHT,
           e.CONTENT_HTML, e.IMAGE_PATH, e.CAPTION, e.STYLE_JSON,
           e.ROW_VER, e.UPT_ID, e.UPT_DT
    FROM dbo.TB_S_ELEMENT e
    WHERE e.M_ID = @M_ID
      AND e.IS_DELETED = 'N'
      AND (@SEC_ID IS NULL OR e.SEC_ID = @SEC_ID)
    ORDER BY e.SEC_ID, e.ORDER_NUM, e.ELE_ID;
END
GO

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

    IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_MANUAL WHERE M_ID = @M_ID AND STATUS = 'DRAFT' AND IS_DELETED = 'N')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'작성(DRAFT) 상태의 문서만 수정할 수 있습니다.';
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

    INSERT INTO dbo.TB_S_ELEMENT_HISTORY (M_ID, SEC_ID, ELE_ID, ACTION, FIELD_NAME, AFTER_VALUE, REG_ID)
    VALUES (@M_ID, @SEC_ID, @ELE_ID, 'UPDATE', 'BLOCK', @ELE_TYPE, @USER_ID);

    SELECT Success = 1, ReturnMsg = CAST(@ELE_ID AS nvarchar(4000));
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

    IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_MANUAL WHERE M_ID = @M_ID AND STATUS = 'DRAFT' AND IS_DELETED = 'N')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'작성(DRAFT) 상태의 문서만 수정할 수 있습니다.';
        RETURN;
    END

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
    WHERE e.M_ID = @M_ID AND e.IS_DELETED = 'N';

    SELECT Success = 1, ReturnMsg = CAST(@@ROWCOUNT AS nvarchar(4000));
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_UPDATE_HEADING_STYLE
    @M_ID    varchar(10),
    @STYLE   nvarchar(max),
    @USER_ID varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF ISJSON(@STYLE) <> 1
    BEGIN
        SELECT Success = 0, ReturnMsg = N'스타일 형식이 올바르지 않습니다.';
        RETURN;
    END

    UPDATE dbo.TB_S_MANUAL
    SET HEADING_STYLE_JSON = @STYLE, UPT_ID = @USER_ID, UPT_DT = GETDATE()
    WHERE M_ID = @M_ID AND IS_DELETED = 'N';

    SELECT Success = 1, ReturnMsg = N'OK';
END
GO

/* 문서 헤더 조회에 제목 스타일 포함 */
CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_MANUAL
    @M_ID varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        m.M_ID, m.DOC_NUM, m.JOB_NUMBER, m.MODEL_NAME, m.LABEL, m.COOLING, m.OPTION_TEXT,
        m.REVISION, m.STATUS, m.PAGE_SIZE, m.PAGE_ORIENTATION, m.HEADING_STYLE_JSON,
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

PRINT '07_alter_document_model.sql 완료';
GO
