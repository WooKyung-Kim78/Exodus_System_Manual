/* ============================================================
   05_seed_testusers.sql
   개발/테스트용 계정 (반복 실행 가능)

   비밀번호는 admin 계정의 해시를 그대로 복사한다.
   => admin 과 동일한 비밀번호로 로그인되며, 평문을 파일에 남기지 않는다.

   ⚠️ 운영 배포 전 반드시 삭제하거나 비밀번호를 개별 재설정할 것.
      여러 계정이 같은 해시를 공유하는 상태는 운영에 두면 안 된다.
   ============================================================ */
SET NOCOUNT ON;
GO

DECLARE @ADMIN_PW varchar(200) =
    (SELECT [PASSWORD] FROM dbo.TB_S_USER WHERE USER_ID = 'admin' AND IS_DELETED = 'N');

IF @ADMIN_PW IS NULL OR @ADMIN_PW = '!NEEDS_BOOTSTRAP'
BEGIN
    RAISERROR('admin 비밀번호가 아직 설정되지 않았습니다. 먼저 "dotnet run -- seed-admin" 을 실행하세요.', 16, 1);
    RETURN;
END

DECLARE @users TABLE (
    USER_ID   varchar(20),
    FULL_NAME nvarchar(100),
    EMAIL     varchar(100),
    DIVISION  nvarchar(100),
    TEAM      nvarchar(100),
    ROLE_NAME varchar(20)
);

INSERT INTO @users VALUES
    ('kim.rf',    N'김민준', 'kim.rf@example.com',    N'R&D',       N'RF Team',            'USER'),
    ('lee.mech',  N'이서연', 'lee.mech@example.com',  N'R&D',       N'Mechanical Team',    'USER'),
    ('park.qa',   N'박지훈', 'park.qa@example.com',   N'Quality',   N'QA Team',            'USER'),
    ('choi.doc',  N'최유진', 'choi.doc@example.com',  N'Marketing', N'Documentation Team', 'USER'),
    ('jung.mgr',  N'정우성', 'jung.mgr@example.com',  N'HQ',        N'Management',         'SUPPORTER');

INSERT INTO dbo.TB_S_USER
    (USER_ID, [PASSWORD], FULL_NAME, EMAIL, DIVISION, TEAM, AUTHORIZED, IS_DELETED, REG_ID, REG_DT)
SELECT u.USER_ID, @ADMIN_PW, u.FULL_NAME, u.EMAIL, u.DIVISION, u.TEAM, 'Y', 'N', 'system', GETDATE()
FROM @users u
WHERE NOT EXISTS (SELECT 1 FROM dbo.TB_S_USER x WHERE x.USER_ID = u.USER_ID);

-- 이미 있는 계정은 비밀번호만 admin 과 맞춰준다.
UPDATE t
SET t.[PASSWORD] = @ADMIN_PW,
    t.AUTHORIZED = 'Y',
    t.IS_DELETED = 'N',
    t.UPT_ID = 'system',
    t.UPT_DT = GETDATE()
FROM dbo.TB_S_USER t
INNER JOIN @users u ON u.USER_ID = t.USER_ID;

INSERT INTO dbo.TB_S_ROLE (USER_ID, ROLE_NAME, IS_DELETED, REG_ID, REG_DT)
SELECT u.USER_ID, u.ROLE_NAME, 'N', 'system', GETDATE()
FROM @users u
WHERE NOT EXISTS (SELECT 1 FROM dbo.TB_S_ROLE r
                  WHERE r.USER_ID = u.USER_ID AND r.IS_DELETED = 'N');

SELECT USER_ID, FULL_NAME, DIVISION, TEAM, AUTHORIZED
FROM dbo.TB_S_USER
WHERE USER_ID IN (SELECT USER_ID FROM @users)
ORDER BY USER_ID;
GO

PRINT '05_seed_testusers.sql 완료 - 비밀번호는 admin 과 동일';
GO
