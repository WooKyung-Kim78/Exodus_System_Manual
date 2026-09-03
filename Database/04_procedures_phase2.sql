/* ============================================================
   04_procedures_phase2.sql
   Phase 2 추가 프로시저 (반복 실행 가능)

   EF Core 의 FromSqlRaw 는 첫 번째 결과셋만 읽으므로,
   USP_S_SELECT_CANVAS(3개 결과셋)를 단일 결과셋 프로시저로 분리한다.
   ============================================================ */
SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_SECTION_LIST
    @M_ID varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT s.SEC_ID, s.M_ID, s.ORDER_NUM, s.TITLE,
           s.CANVAS_X, s.CANVAS_Y, s.BOARD_W, s.BOARD_H,
           s.ASSIGNED_TEAM, s.ASSIGNED_USER_ID,
           ASSIGNED_NAME = u.FULL_NAME,
           s.SEC_STATUS,
           ELEMENT_CNT = (SELECT COUNT(*) FROM dbo.TB_S_ELEMENT e
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

CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_ELEMENT_LIST
    @M_ID   varchar(10),
    @SEC_ID bigint = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT e.ELE_ID, e.M_ID, e.SEC_ID, e.ELE_TYPE,
           e.POS_X, e.POS_Y, e.WIDTH, e.HEIGHT, e.ROTATION, e.Z_INDEX,
           e.GROUP_ID, e.CONTENT_HTML, e.IMAGE_PATH, e.CAPTION, e.STYLE_JSON,
           e.ROW_VER, e.UPT_ID, e.UPT_DT
    FROM dbo.TB_S_ELEMENT e
    WHERE e.M_ID = @M_ID
      AND e.IS_DELETED = 'N'
      AND (@SEC_ID IS NULL OR e.SEC_ID = @SEC_ID)
    ORDER BY e.SEC_ID, e.Z_INDEX, e.ELE_ID;
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_ELEMENT_TABLE_ROW_LIST
    @M_ID varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT r.ROW_ID, r.ELE_ID, r.ORDER_NUM,
           r.ITEM, r.SPEC, r.UNIT, r.MIN_VAL, r.TYP_VAL, r.MAX_VAL, r.REMARK
    FROM dbo.TB_S_ELEMENT_TABLE_ROW r
    INNER JOIN dbo.TB_S_ELEMENT e ON e.ELE_ID = r.ELE_ID
    WHERE e.M_ID = @M_ID AND e.IS_DELETED = 'N' AND r.IS_DELETED = 'N'
    ORDER BY r.ELE_ID, r.ORDER_NUM;
END
GO

/* 담당 팀 드롭다운용 */
CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_USER_TEAM_LIST
AS
BEGIN
    SET NOCOUNT ON;

    SELECT DIVISION = ISNULL(DIVISION, N''),
           TEAM     = ISNULL(TEAM, N''),
           CNT      = COUNT(*)
    FROM dbo.TB_S_USER
    WHERE IS_DELETED = 'N' AND AUTHORIZED = 'Y'
    GROUP BY DIVISION, TEAM
    HAVING ISNULL(TEAM, N'') <> N''
    ORDER BY DIVISION, TEAM;
END
GO

/* 담당자 지정 / 멤버 초대 검색용 */
CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_USER_SEARCH_LIST
    @KEYWORD nvarchar(100) = NULL,
    @TEAM    nvarchar(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (100)
           u.USER_ID, u.FULL_NAME, u.EMAIL, u.DIVISION, u.TEAM
    FROM dbo.TB_S_USER u
    WHERE u.IS_DELETED = 'N'
      AND u.AUTHORIZED = 'Y'
      AND (@TEAM IS NULL OR u.TEAM = @TEAM)
      AND (@KEYWORD IS NULL OR @KEYWORD = N''
           OR u.USER_ID LIKE N'%' + @KEYWORD + N'%'
           OR u.FULL_NAME LIKE N'%' + @KEYWORD + N'%')
    ORDER BY u.FULL_NAME;
END
GO

/* 문서 소프트 삭제 (DRAFT 상태 + 소유자만) */
CREATE OR ALTER PROCEDURE dbo.USP_S_DELETE_MANUAL
    @M_ID    varchar(10),
    @USER_ID varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_MANUAL
                   WHERE M_ID = @M_ID AND STATUS = 'DRAFT' AND IS_DELETED = 'N')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'작성(DRAFT) 상태의 문서만 삭제할 수 있습니다.';
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_MANUAL_MEMBER
                   WHERE M_ID = @M_ID AND USER_ID = @USER_ID
                     AND MEMBER_ROLE = 'OWNER' AND IS_DELETED = 'N')
       AND NOT EXISTS (SELECT 1 FROM dbo.TB_S_ROLE
                       WHERE USER_ID = @USER_ID AND ROLE_NAME = 'ADMIN' AND IS_DELETED = 'N')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'문서 소유자 또는 관리자만 삭제할 수 있습니다.';
        RETURN;
    END

    UPDATE dbo.TB_S_MANUAL
    SET IS_DELETED = 'Y', UPT_ID = @USER_ID, UPT_DT = GETDATE()
    WHERE M_ID = @M_ID;

    SELECT Success = 1, ReturnMsg = N'OK';
END
GO

PRINT '04_procedures_phase2.sql 완료';
GO
