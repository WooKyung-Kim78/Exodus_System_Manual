/* ============================================================
   17_body_font.sql
   본문 글꼴 / 기본 글자 크기 (반복 실행 가능)

     글꼴은 문서 전체가 하나로 통일된다. 블록마다 다른 글꼴을 쓰면
     인쇄물에서 눈에 띄게 어색해지므로 편집기에서 바꾸지 못하게 한다.
     글자 크기는 여기 값이 기본이고, 편집기에서 지정한 부분만 그 값이 이긴다.
   ============================================================ */
SET NOCOUNT ON;
GO

IF COL_LENGTH('dbo.TB_S_MANUAL', 'BODY_FONT') IS NULL
    ALTER TABLE dbo.TB_S_MANUAL ADD BODY_FONT varchar(50) NULL;
GO
IF COL_LENGTH('dbo.TB_S_MANUAL', 'BODY_FONT_SIZE') IS NULL
    ALTER TABLE dbo.TB_S_MANUAL ADD BODY_FONT_SIZE int NULL;
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_UPDATE_DOC_STYLE
    @M_ID           varchar(10),
    @STYLE          nvarchar(max),
    @BODY_FONT      varchar(50)   = NULL,
    @BODY_FONT_SIZE int           = NULL,
    @USER_ID        varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF ISJSON(@STYLE) <> 1
    BEGIN
        SELECT Success = 0, ReturnMsg = N'스타일 형식이 올바르지 않습니다.';
        RETURN;
    END

    IF @BODY_FONT IS NOT NULL
       AND @BODY_FONT NOT IN ('ARIAL', 'VERDANA', 'TAHOMA', 'GEORGIA', 'TIMES')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'글꼴 값이 올바르지 않습니다.';
        RETURN;
    END

    IF @BODY_FONT_SIZE IS NOT NULL AND @BODY_FONT_SIZE NOT BETWEEN 7 AND 20
    BEGIN
        SELECT Success = 0, ReturnMsg = N'본문 글자 크기는 7~20pt 로 지정하세요.';
        RETURN;
    END

    UPDATE dbo.TB_S_MANUAL
    SET HEADING_STYLE_JSON = @STYLE,
        BODY_FONT          = ISNULL(@BODY_FONT, BODY_FONT),
        BODY_FONT_SIZE     = ISNULL(@BODY_FONT_SIZE, BODY_FONT_SIZE),
        UPT_ID             = @USER_ID,
        UPT_DT             = GETDATE()
    WHERE M_ID = @M_ID AND IS_DELETED = 'N';

    IF @@ROWCOUNT = 0
    BEGIN
        SELECT Success = 0, ReturnMsg = N'문서를 찾을 수 없습니다.';
        RETURN;
    END

    SELECT Success = 1, ReturnMsg = N'OK';
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_MANUAL
    @M_ID varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        m.M_ID, m.DOC_NUM, m.JOB_NUMBER, m.MODEL_NAME, m.LABEL, m.COOLING, m.OPTION_TEXT,
        m.REVISION, m.STATUS, m.PAGE_SIZE, m.PAGE_ORIENTATION, m.HEADING_STYLE_JSON,
        m.COVER_IMAGE_PATH, m.BODY_FONT, m.BODY_FONT_SIZE,
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

PRINT '17_body_font.sql 완료';
GO
