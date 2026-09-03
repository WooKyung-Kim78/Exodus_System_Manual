/* ============================================================
   00_alter_user.sql
   기존 TB_S_USER 보정 (비파괴 · 반복 실행 가능)
   실행 순서: 00 → 01 → 02 → 03
   ============================================================ */
SET NOCOUNT ON;
GO

/* ---- 사전 점검: USER_ID 중복이 있으면 UNIQUE 인덱스를 만들 수 없음 ---- */
IF EXISTS (SELECT 1 FROM dbo.TB_S_USER GROUP BY USER_ID HAVING COUNT(*) > 1)
BEGIN
    SELECT USER_ID, COUNT(*) AS DUP_CNT
    FROM dbo.TB_S_USER
    GROUP BY USER_ID
    HAVING COUNT(*) > 1;

    RAISERROR('TB_S_USER.USER_ID 에 중복이 있습니다. 위 목록을 정리한 뒤 다시 실행하세요.', 16, 1);
    SET NOEXEC ON;
END
GO

/* ---- 1) NULL 값 정리 (NOT NULL 전환 전 선행) ---- */
UPDATE dbo.TB_S_USER SET IS_DELETED = 'N' WHERE IS_DELETED IS NULL;
UPDATE dbo.TB_S_USER SET AUTHORIZED = 'S' WHERE AUTHORIZED IS NULL OR AUTHORIZED NOT IN ('Y', 'S', 'N');
GO

/* ---- 2) 한글 보존을 위해 varchar → nvarchar ---- */
IF EXISTS (SELECT 1 FROM sys.columns
           WHERE object_id = OBJECT_ID('dbo.TB_S_USER') AND name = 'FULL_NAME' AND system_type_id = TYPE_ID('varchar'))
    ALTER TABLE dbo.TB_S_USER ALTER COLUMN FULL_NAME nvarchar(100) NOT NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns
           WHERE object_id = OBJECT_ID('dbo.TB_S_USER') AND name = 'DIVISION' AND system_type_id = TYPE_ID('varchar'))
    ALTER TABLE dbo.TB_S_USER ALTER COLUMN DIVISION nvarchar(100) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns
           WHERE object_id = OBJECT_ID('dbo.TB_S_USER') AND name = 'TEAM' AND system_type_id = TYPE_ID('varchar'))
    ALTER TABLE dbo.TB_S_USER ALTER COLUMN TEAM nvarchar(100) NULL;
GO

/* ---- 3) PASSWORD: varchar(max) → varchar(200) (PBKDF2 해시 약 84자) ---- */
IF EXISTS (SELECT 1 FROM sys.columns
           WHERE object_id = OBJECT_ID('dbo.TB_S_USER') AND name = 'PASSWORD' AND max_length = -1)
BEGIN
    IF EXISTS (SELECT 1 FROM dbo.TB_S_USER WHERE DATALENGTH(PASSWORD) > 200)
        RAISERROR('200자를 넘는 PASSWORD 값이 있어 축소할 수 없습니다. 확인 후 수동 처리하세요.', 16, 1);
    ELSE
        ALTER TABLE dbo.TB_S_USER ALTER COLUMN [PASSWORD] varchar(200) NOT NULL;
END
GO

/* ---- 4) SUPERVISOR_USER_ID 길이를 USER_ID(20)와 일치시킴 ---- */
IF EXISTS (SELECT 1 FROM sys.columns
           WHERE object_id = OBJECT_ID('dbo.TB_S_USER') AND name = 'SUPERVISOR_USER_ID' AND max_length < 20)
    ALTER TABLE dbo.TB_S_USER ALTER COLUMN SUPERVISOR_USER_ID varchar(20) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns
           WHERE object_id = OBJECT_ID('dbo.TB_S_USER') AND name = 'IS_SUPERVISOR' AND max_length > 1)
    ALTER TABLE dbo.TB_S_USER ALTER COLUMN IS_SUPERVISOR varchar(1) NULL;
GO

/* ---- 5) IS_DELETED NOT NULL 전환 ---- */
IF EXISTS (SELECT 1 FROM sys.columns
           WHERE object_id = OBJECT_ID('dbo.TB_S_USER') AND name = 'IS_DELETED' AND is_nullable = 1)
    ALTER TABLE dbo.TB_S_USER ALTER COLUMN IS_DELETED varchar(1) NOT NULL;
GO

/* ---- 6) 기본값 ---- */
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = 'DF_TB_S_USER_IS_DELETED')
    ALTER TABLE dbo.TB_S_USER ADD CONSTRAINT DF_TB_S_USER_IS_DELETED DEFAULT ('N') FOR IS_DELETED;
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = 'DF_TB_S_USER_AUTHORIZED')
    ALTER TABLE dbo.TB_S_USER ADD CONSTRAINT DF_TB_S_USER_AUTHORIZED DEFAULT ('S') FOR AUTHORIZED;
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = 'DF_TB_S_USER_REG_DT')
    ALTER TABLE dbo.TB_S_USER ADD CONSTRAINT DF_TB_S_USER_REG_DT DEFAULT (GETDATE()) FOR REG_DT;
GO

/* ---- 7) 값 제약 ---- */
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_TB_S_USER_AUTHORIZED')
    ALTER TABLE dbo.TB_S_USER ADD CONSTRAINT CK_TB_S_USER_AUTHORIZED CHECK (AUTHORIZED IN ('Y', 'S', 'N'));
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_TB_S_USER_IS_DELETED')
    ALTER TABLE dbo.TB_S_USER ADD CONSTRAINT CK_TB_S_USER_IS_DELETED CHECK (IS_DELETED IN ('Y', 'N'));
GO

/* ---- 8) PK / UNIQUE (EF Core 키 인식 + SingleOrDefault 예외 방지) ---- */
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = 'PK_TB_S_USER')
    ALTER TABLE dbo.TB_S_USER ADD CONSTRAINT PK_TB_S_USER PRIMARY KEY CLUSTERED (IDX);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_TB_S_USER_USER_ID' AND object_id = OBJECT_ID('dbo.TB_S_USER'))
    CREATE UNIQUE NONCLUSTERED INDEX UX_TB_S_USER_USER_ID ON dbo.TB_S_USER (USER_ID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_TB_S_USER_TEAM' AND object_id = OBJECT_ID('dbo.TB_S_USER'))
    CREATE NONCLUSTERED INDEX IX_TB_S_USER_TEAM ON dbo.TB_S_USER (DIVISION, TEAM) WHERE IS_DELETED = 'N';
GO

SET NOEXEC OFF;
GO
PRINT '00_alter_user.sql 완료';
GO
