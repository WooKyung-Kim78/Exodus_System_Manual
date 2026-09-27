/* ============================================================
   29_heading_size_13.sql
   이미 저장된 문서의 공통 제목 크기(대/중/소제목)를 모두 13pt 로 맞춘다. — 반복 실행 가능

   새 문서의 기본값은 HeadingStyle.Defaults() (13pt) 가 정한다.
   목차별 개별 스타일(TB_S_SECTION.STYLE_JSON)은 사용자가 따로 지정한 값이라 건드리지 않는다.
   ============================================================ */
SET NOCOUNT ON;
GO

UPDATE dbo.TB_S_MANUAL
SET HEADING_STYLE_JSON =
        JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(HEADING_STYLE_JSON,
            '$."1".size', 13),
            '$."2".size', 13),
            '$."3".size', 13)
WHERE IS_DELETED = 'N'
  AND ISJSON(HEADING_STYLE_JSON) = 1;
GO

PRINT '29_heading_size_13.sql 완료';
GO
