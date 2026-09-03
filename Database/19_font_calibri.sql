/* ============================================================
   19_font_calibri.sql
   본문 글꼴 목록에 Calibri 추가 (반복 실행 가능)
   ============================================================ */
SET NOCOUNT ON;
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
       AND @BODY_FONT NOT IN ('ARIAL', 'CALIBRI', 'VERDANA', 'TAHOMA', 'GEORGIA', 'TIMES')
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
    SET HEADING_STYLE_JSON  = @STYLE,
        BODY_FONT           = ISNULL(@BODY_FONT, BODY_FONT),
        BODY_FONT_SIZE      = 12,
        BODY_LINE_HEIGHT    = ISNULL(@LINE_HEIGHT, BODY_LINE_HEIGHT),
        BODY_LETTER_SPACING = ISNULL(@LETTER_SPACING, BODY_LETTER_SPACING),
        UPT_ID              = @USER_ID,
        UPT_DT              = GETDATE()
    WHERE M_ID = @M_ID AND IS_DELETED = 'N';

    IF @@ROWCOUNT = 0
    BEGIN
        SELECT Success = 0, ReturnMsg = N'문서를 찾을 수 없습니다.';
        RETURN;
    END

    SELECT Success = 1, ReturnMsg = N'OK';
END
GO

PRINT '19_font_calibri.sql 완료';
GO
