/* ============================================================
   15_section_history.sql
   목차별 수정 이력 조회 (반복 실행 가능)

     TB_S_ELEMENT_HISTORY 에 이미 쌓고 있던 기록을 화면에서 볼 수 있게 한다.
     본문 내용 자체는 보관하지 않는다. 누가·언제·무엇을 했는지만 남긴다.
   ============================================================ */
SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_SECTION_HISTORY
    @M_ID   varchar(10),
    @SEC_ID bigint,
    @TOP    int = 100
AS
BEGIN
    SET NOCOUNT ON;

    IF @TOP IS NULL OR @TOP < 1 OR @TOP > 500 SET @TOP = 100;

    SELECT TOP (@TOP)
           h.HIS_ID, h.SEC_ID, h.ELE_ID, h.ACTION, h.FIELD_NAME,
           h.BEFORE_VALUE, h.AFTER_VALUE,
           h.REG_ID,
           REG_NAME = ISNULL(u.FULL_NAME, h.REG_ID),
           REG_TEAM = u.TEAM,
           h.REG_DT
    FROM dbo.TB_S_ELEMENT_HISTORY h
    LEFT JOIN dbo.TB_S_USER u ON u.USER_ID = h.REG_ID
    WHERE h.M_ID = @M_ID
      AND h.SEC_ID = @SEC_ID
    ORDER BY h.HIS_ID DESC;
END
GO

PRINT '15_section_history.sql 완료';
GO
