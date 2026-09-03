/* ============================================================
   06_procedures_notify.sql
   편집 요청 알림용 프로시저 (반복 실행 가능)
   ============================================================ */
SET NOCOUNT ON;
GO

/* 문서 참여자 + 각자에게 배정된 섹션 목록.
   ASSIGNED_SECTIONS 는 '1. 개요 / 3. 사양' 형태로 이어붙인다. */
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
                              AND s.ASSIGNED_USER_ID = mb.USER_ID),
           ASSIGNED_SECTIONS = STUFF((
                SELECT N' / ' + CAST(s.ORDER_NUM AS nvarchar(10)) + N'. ' + s.TITLE
                FROM dbo.TB_S_SECTION s
                WHERE s.M_ID = @M_ID AND s.IS_DELETED = 'N'
                  AND s.ASSIGNED_USER_ID = mb.USER_ID
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

/* 단일 사용자 알림용 (멤버 추가 직후 초대 메일) */
CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_NOTIFY_ONE
    @M_ID   varchar(10),
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
                              AND s.ASSIGNED_USER_ID = mb.USER_ID),
           ASSIGNED_SECTIONS = STUFF((
                SELECT N' / ' + CAST(s.ORDER_NUM AS nvarchar(10)) + N'. ' + s.TITLE
                FROM dbo.TB_S_SECTION s
                WHERE s.M_ID = @M_ID AND s.IS_DELETED = 'N'
                  AND s.ASSIGNED_USER_ID = mb.USER_ID
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

PRINT '06_procedures_notify.sql 완료';
GO
