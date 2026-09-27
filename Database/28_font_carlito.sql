/* ============================================================
   28_font_carlito.sql
   본문 글꼴 Calibri → Carlito — 반복 실행 가능

   Carlito 는 Calibri 와 글자 폭이 같은 오픈 글꼴(SIL OFL 1.1)이다.
   글꼴 파일을 wwwroot/assets/fonts/carlito 에 두고 웹 글꼴로 쓰므로
   서버 PDF 생성 시 서버에 글꼴을 설치하지 않아도 같은 모양으로 나온다.
   ============================================================ */
SET NOCOUNT ON;
GO

/* 1) 기본값 */
IF EXISTS (SELECT 1 FROM sys.default_constraints
           WHERE name = 'DF_TB_S_MANUAL_BODY_FONT' AND definition <> '(''CARLITO'')')
    ALTER TABLE dbo.TB_S_MANUAL DROP CONSTRAINT DF_TB_S_MANUAL_BODY_FONT;
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = 'DF_TB_S_MANUAL_BODY_FONT')
    ALTER TABLE dbo.TB_S_MANUAL ADD CONSTRAINT DF_TB_S_MANUAL_BODY_FONT DEFAULT ('CARLITO') FOR BODY_FONT;
GO

/* 2) 기존 문서 보정 */
UPDATE dbo.TB_S_MANUAL SET BODY_FONT = 'CARLITO' WHERE BODY_FONT IS NULL OR BODY_FONT = 'CALIBRI';
GO

/* 3) 문서 스타일 저장 (24_body_font_default.sql 기준, CALIBRI → CARLITO) */
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

    IF @BODY_FONT = 'CALIBRI' SET @BODY_FONT = 'CARLITO';

    IF @BODY_FONT IS NOT NULL
       AND @BODY_FONT NOT IN ('ARIAL', 'CARLITO', 'VERDANA', 'TAHOMA', 'GEORGIA', 'TIMES')
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
        BODY_FONT           = ISNULL(@BODY_FONT, ISNULL(BODY_FONT, 'CARLITO')),
        BODY_FONT_SIZE      = 10,
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

PRINT '28_font_carlito.sql 완료';
GO
