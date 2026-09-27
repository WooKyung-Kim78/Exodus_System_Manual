/* ============================================================
   24_body_font_default.sql
   본문 기본 글꼴 Calibri · 글자 크기 10pt — 반복 실행 가능

   제목(목차) 스타일은 HEADING_STYLE_JSON 이 따로 가지므로 건드리지 않는다.
   ============================================================ */
SET NOCOUNT ON;
GO

/* ------------------------------------------------------------
   1) 기본값 — 새 문서는 글꼴을 고르지 않아도 Calibri 10pt 로 본다.
   ------------------------------------------------------------ */
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = 'DF_TB_S_MANUAL_BODY_FONT')
    ALTER TABLE dbo.TB_S_MANUAL ADD CONSTRAINT DF_TB_S_MANUAL_BODY_FONT DEFAULT ('CALIBRI') FOR BODY_FONT;
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = 'DF_TB_S_MANUAL_BODY_FONT_SIZE')
    ALTER TABLE dbo.TB_S_MANUAL ADD CONSTRAINT DF_TB_S_MANUAL_BODY_FONT_SIZE DEFAULT (10) FOR BODY_FONT_SIZE;
GO

/* ------------------------------------------------------------
   2) 기존 문서 보정
      글자 크기는 편집기에서 바꿀 수 없는 고정값이라 모두 맞춘다.
      글꼴은 예전 기본값(ARIAL)이거나 비어 있는 문서만 바꾼다.
   ------------------------------------------------------------ */
UPDATE dbo.TB_S_MANUAL SET BODY_FONT_SIZE = 10 WHERE ISNULL(BODY_FONT_SIZE, 0) <> 10;
GO
UPDATE dbo.TB_S_MANUAL SET BODY_FONT = 'CALIBRI' WHERE BODY_FONT IS NULL OR BODY_FONT = 'ARIAL';
GO

/* ------------------------------------------------------------
   3) 문서 스타일 저장 — 고정 글자 크기를 10 으로 내린다.
   ------------------------------------------------------------ */
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
        BODY_FONT           = ISNULL(@BODY_FONT, ISNULL(BODY_FONT, 'CALIBRI')),
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

PRINT '24_body_font_default.sql 완료';
GO
