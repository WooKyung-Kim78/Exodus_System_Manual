/* ============================================================
   03_seed.sql
   초기 데이터 (반복 실행 가능 · 기존 값 덮어쓰지 않음)

   주의: 관리자 비밀번호는 여기서 설정하지 않는다.
         SQL 파일에 기본 비밀번호를 넣으면 그대로 운영에 남는 사고가 생기므로,
         PASSWORD 는 검증이 반드시 실패하는 표식으로 두고
         애플리케이션의 부트스트랩 명령으로 최초 1회 설정한다.
   ============================================================ */
SET NOCOUNT ON;
GO

/* ---- 관리자 계정 (없을 때만 생성) ---- */
IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_USER WHERE USER_ID = 'admin')
BEGIN
    INSERT INTO dbo.TB_S_USER
        (USER_ID, [PASSWORD], FULL_NAME, EMAIL, DIVISION, TEAM,
         AUTHORIZED, IS_DELETED, REG_ID, REG_DT)
    VALUES
        ('admin', '!NEEDS_BOOTSTRAP', N'Administrator', NULL, N'HQ', N'IT',
         'Y', 'N', 'system', GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_ROLE WHERE USER_ID = 'admin' AND IS_DELETED = 'N')
    INSERT INTO dbo.TB_S_ROLE (USER_ID, ROLE_NAME, IS_DELETED, REG_ID, REG_DT)
    VALUES ('admin', 'ADMIN', 'N', 'system', GETDATE());
GO

/* ---- SMTP 설정 (값은 관리자 화면에서 입력) ---- */
MERGE dbo.TB_S_SETTING AS t
USING (VALUES
    ('SMTP', 'SYSTEM_NAME',           N'EXODUS System Manual'),
    ('SMTP', 'SYSTEM_EMAIL',          N''),
    ('SMTP', 'SYSTEM_SMTP',           N''),
    ('SMTP', 'SYSTEM_SMTP_PORT',      N'587'),
    ('SMTP', 'SYSTEM_SMTP_SECURE',    N'STARTTLS'),
    ('SMTP', 'SYSTEM_EMAIL_ID',       N''),
    ('SMTP', 'SYSTEM_EMAIL_PASSWORD', N''),   -- DataProtection 으로 암호화해 저장
    ('SMTP', 'SYSTEM_SMTP_SCOPE',     N'T')   -- T=TEST, P=PRODUCTION
) AS s (CATEGORY, TYPE, VALUE)
   ON t.TYPE = s.TYPE
WHEN NOT MATCHED THEN
    INSERT (CATEGORY, TYPE, VALUE, REG_ID, REG_DT)
    VALUES (s.CATEGORY, s.TYPE, s.VALUE, 'system', GETDATE());
GO

/* ---- 공통 코드 ----
   상태·역할·페이지 크기 등은 화면과 프로시저에 직접 박혀 있어 코드로 읽지 않는다.
   쓰지 않는 값을 넣어두면 관리 화면에서 고쳐도 반영되는 줄 알게 되므로 시드하지 않는다.
   실제로 쓰는 표지(COVER) 항목은 16_cover_page.sql 에서 넣는다. */
GO

PRINT '03_seed.sql 완료';
PRINT 'admin 비밀번호는 아직 설정되지 않았습니다. 애플리케이션 부트스트랩 명령으로 지정하세요.';
GO
