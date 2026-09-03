/* ============================================================
   08_alter_section_style.sql
   목차별 제목 스타일 개별 지정 (반복 실행 가능)

     - 문서 공통 스타일(TB_S_MANUAL.HEADING_STYLE_JSON)은 그대로 유지한다.
     - 목차마다 STYLE_JSON 을 두고, 값이 있는 항목만 공통 스타일을 덮어쓴다.
       NULL 이면 공통 스타일을 그대로 따르므로 공통값을 바꾸면 함께 바뀐다.
   ============================================================ */
SET NOCOUNT ON;
GO

IF COL_LENGTH('dbo.TB_S_SECTION', 'STYLE_JSON') IS NULL
    ALTER TABLE dbo.TB_S_SECTION ADD STYLE_JSON nvarchar(max) NULL;
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_SECTION_LIST
    @M_ID varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT s.SEC_ID, s.M_ID, s.ORDER_NUM, s.SEC_LEVEL, s.SEC_NO, s.TITLE,
           s.STYLE_JSON,
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
    @STYLE_JSON       nvarchar(max) = NULL,
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

    -- 빈 문자열이나 깨진 JSON 은 '공통 스타일 사용'으로 처리한다.
    IF @STYLE_JSON = N'' OR (@STYLE_JSON IS NOT NULL AND ISJSON(@STYLE_JSON) <> 1)
        SET @STYLE_JSON = NULL;

    IF @SEC_ID IS NULL
    BEGIN
        DECLARE @ORDER int = ISNULL((SELECT MAX(ORDER_NUM) FROM dbo.TB_S_SECTION
                                     WHERE M_ID = @M_ID AND IS_DELETED = 'N'), 0) + 1;

        INSERT INTO dbo.TB_S_SECTION
            (M_ID, ORDER_NUM, SEC_LEVEL, SEC_NO, TITLE, STYLE_JSON,
             ASSIGNED_TEAM, ASSIGNED_USER_ID, REG_ID)
        VALUES
            (@M_ID, @ORDER, @SEC_LEVEL, @SEC_NO, @TITLE, @STYLE_JSON,
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
        SEC_LEVEL        = @SEC_LEVEL,
        SEC_NO           = @SEC_NO,
        STYLE_JSON       = @STYLE_JSON,
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

PRINT '08_alter_section_style.sql 완료';
GO
