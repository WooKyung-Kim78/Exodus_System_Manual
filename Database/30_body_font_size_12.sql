/* ============================================================
   30_body_font_size_12.sql
   본문 글자 크기 10pt → 12pt — 반복 실행 가능

   본문 크기는 편집기에서 바꿀 수 없는 고정값이라 기존 문서도 모두 맞춘다.
   ============================================================ */
SET NOCOUNT ON;
GO

/* 1) 기본값 */
IF EXISTS (SELECT 1 FROM sys.default_constraints
           WHERE name = 'DF_TB_S_MANUAL_BODY_FONT_SIZE' AND definition <> '((12))')
    ALTER TABLE dbo.TB_S_MANUAL DROP CONSTRAINT DF_TB_S_MANUAL_BODY_FONT_SIZE;
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = 'DF_TB_S_MANUAL_BODY_FONT_SIZE')
    ALTER TABLE dbo.TB_S_MANUAL ADD CONSTRAINT DF_TB_S_MANUAL_BODY_FONT_SIZE DEFAULT (12) FOR BODY_FONT_SIZE;
GO

/* 2) 기존 문서 보정 */
UPDATE dbo.TB_S_MANUAL SET BODY_FONT_SIZE = 12 WHERE ISNULL(BODY_FONT_SIZE, 0) <> 12;
GO

/* 3) 문서 스타일 저장 (28_font_carlito.sql 기준, BODY_FONT_SIZE 10 → 12) */
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

PRINT '30_body_font_size_12.sql 완료';
GO
