/* ============================================================
   18_body_spacing.sql
   본문 행간(줄 간격) / 자간(글자 간격) 추가 (반복 실행 가능)

     글자 크기는 12pt 로 고정한다. 편집기에서도 바꿀 수 없다.
     문서마다 크기가 다르면 여러 팀이 쓴 목차가 한 문서 안에서 들쭉날쭉해진다.
   ============================================================ */
SET NOCOUNT ON;
GO

IF COL_LENGTH('dbo.TB_S_MANUAL', 'BODY_LINE_HEIGHT') IS NULL
    ALTER TABLE dbo.TB_S_MANUAL ADD BODY_LINE_HEIGHT decimal(4,2) NULL;
GO
IF COL_LENGTH('dbo.TB_S_MANUAL', 'BODY_LETTER_SPACING') IS NULL
    ALTER TABLE dbo.TB_S_MANUAL ADD BODY_LETTER_SPACING decimal(4,2) NULL;
GO

UPDATE dbo.TB_S_MANUAL SET BODY_FONT_SIZE = 12 WHERE ISNULL(BODY_FONT_SIZE, 0) <> 12;
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_UPDATE_DOC_STYLE
    @M_ID           varchar(10),
    @STYLE          nvarchar(max),
    @BODY_FONT      varchar(50)   = NULL,
    @LINE_HEIGHT    decimal(4,2)  = NULL,
    @LETTER_SPACING decimal(4,2)  = NULL,
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

    IF @LINE_HEIGHT IS NOT NULL AND @LINE_HEIGHT NOT BETWEEN 1.0 AND 3.0
    BEGIN
        SELECT Success = 0, ReturnMsg = N'행간은 1.0 ~ 3.0 사이로 지정하세요.';
        RETURN;
    END

    IF @LETTER_SPACING IS NOT NULL AND @LETTER_SPACING NOT BETWEEN -1.0 AND 3.0
    BEGIN
        SELECT Success = 0, ReturnMsg = N'자간은 -1.0 ~ 3.0px 사이로 지정하세요.';
        RETURN;
    END

    UPDATE dbo.TB_S_MANUAL
    SET HEADING_STYLE_JSON    = @STYLE,
        BODY_FONT             = ISNULL(@BODY_FONT, BODY_FONT),
        BODY_FONT_SIZE        = 12,
        BODY_LINE_HEIGHT      = ISNULL(@LINE_HEIGHT, BODY_LINE_HEIGHT),
        BODY_LETTER_SPACING   = ISNULL(@LETTER_SPACING, BODY_LETTER_SPACING),
        UPT_ID                = @USER_ID,
        UPT_DT                = GETDATE()
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
        m.BODY_LINE_HEIGHT, m.BODY_LETTER_SPACING,
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

PRINT '18_body_spacing.sql 완료';
GO
