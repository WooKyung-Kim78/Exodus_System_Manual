/* ============================================================
   22_user_admin.sql
   사용자 등록 / 수정 (관리자) — 반복 실행 가능

   비밀번호는 애플리케이션에서 PBKDF2 로 해시한 뒤 넘긴다.
   프로시저는 평문을 절대 받지 않는다.
   ============================================================ */
SET NOCOUNT ON;
GO

/* ------------------------------------------------------------
   0) 컬럼 보정 — EMAIL 은 레거시 테이블에서 넘어와 길이/타입이 제각각이다.
   ------------------------------------------------------------ */
IF EXISTS (SELECT 1 FROM sys.columns
           WHERE object_id = OBJECT_ID('dbo.TB_S_USER') AND name = 'EMAIL'
             AND (system_type_id = TYPE_ID('varchar') OR max_length < 200))
    ALTER TABLE dbo.TB_S_USER ALTER COLUMN EMAIL nvarchar(100) NULL;
GO

/* 이메일 중복 검사용 */
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_TB_S_USER_EMAIL' AND object_id = OBJECT_ID('dbo.TB_S_USER'))
    CREATE NONCLUSTERED INDEX IX_TB_S_USER_EMAIL
        ON dbo.TB_S_USER (EMAIL) WHERE IS_DELETED = 'N';
GO

/* ------------------------------------------------------------
   1) 목록 / 단건 조회
      @VIEW  : USE = 사용 중, DEL = 삭제됨
      @USER_ID 를 주면 상태와 무관하게 단건.
   ------------------------------------------------------------ */
CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_USER_LIST
    @KEYWORD nvarchar(100) = NULL,
    @VIEW    varchar(3)    = 'USE',
    @USER_ID varchar(20)   = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @VIEW IS NULL OR @VIEW NOT IN ('USE', 'DEL') SET @VIEW = 'USE';

    SELECT u.IDX,
           u.USER_ID,
           u.FULL_NAME,
           u.EMAIL,
           u.DIVISION,
           u.TEAM,
           u.AUTHORIZED,
           u.IS_DELETED,
           u.SUPERVISOR_USER_ID,
           SUPERVISOR_NAME = s.FULL_NAME,
           ROLE_NAME       = ISNULL(r.ROLE_NAME, 'USER'),
           u.REG_DT,
           u.UPT_DT
    FROM dbo.TB_S_USER u
    -- 삭제된 계정은 역할 행도 함께 닫히므로 살아 있는 행을 우선해 최근 것을 본다.
    OUTER APPLY (SELECT TOP (1) x.ROLE_NAME
                 FROM dbo.TB_S_ROLE x
                 WHERE x.USER_ID = u.USER_ID
                 ORDER BY CASE WHEN x.IS_DELETED = 'N' THEN 0 ELSE 1 END, x.IDX DESC) r
    LEFT JOIN dbo.TB_S_USER s ON s.USER_ID = u.SUPERVISOR_USER_ID AND s.IS_DELETED = 'N'
    WHERE (@USER_ID IS NOT NULL OR u.IS_DELETED = CASE WHEN @VIEW = 'DEL' THEN 'Y' ELSE 'N' END)
      AND (@USER_ID IS NULL OR u.USER_ID = @USER_ID)
      AND (@KEYWORD IS NULL OR @KEYWORD = N''
           OR u.USER_ID   LIKE N'%' + @KEYWORD + N'%'
           OR u.FULL_NAME LIKE N'%' + @KEYWORD + N'%'
           OR u.EMAIL     LIKE N'%' + @KEYWORD + N'%'
           OR u.TEAM      LIKE N'%' + @KEYWORD + N'%')
    ORDER BY u.FULL_NAME, u.USER_ID;
END
GO

/* ------------------------------------------------------------
   2) 등록 / 수정
      @PASSWORD_HASH 는 신규 등록에만 쓰고, 수정 시에는 무시한다.
   ------------------------------------------------------------ */
CREATE OR ALTER PROCEDURE dbo.USP_S_MERGE_USER
    @USER_ID            varchar(20),
    @FULL_NAME          nvarchar(100),
    @EMAIL              nvarchar(100) = NULL,
    @DIVISION           nvarchar(100) = NULL,
    @TEAM               nvarchar(100) = NULL,
    @SUPERVISOR_USER_ID varchar(20)   = NULL,
    @ROLE_NAME          varchar(20),
    @AUTHORIZED         varchar(1),
    @PASSWORD_HASH      varchar(200)  = NULL,
    @REG_ID             varchar(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @EMAIL              = NULLIF(LTRIM(RTRIM(@EMAIL)), N'');
    SET @DIVISION           = NULLIF(LTRIM(RTRIM(@DIVISION)), N'');
    SET @TEAM               = NULLIF(LTRIM(RTRIM(@TEAM)), N'');
    SET @SUPERVISOR_USER_ID = NULLIF(LTRIM(RTRIM(@SUPERVISOR_USER_ID)), '');

    IF @ROLE_NAME NOT IN ('ADMIN', 'USER', 'READER')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'역할 값이 올바르지 않습니다.';
        RETURN;
    END

    IF @AUTHORIZED NOT IN ('Y', 'S', 'N')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'계정 상태 값이 올바르지 않습니다.';
        RETURN;
    END

    IF @SUPERVISOR_USER_ID = @USER_ID
    BEGIN
        SELECT Success = 0, ReturnMsg = N'자기 자신을 관리자로 지정할 수 없습니다.';
        RETURN;
    END

    IF @SUPERVISOR_USER_ID IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM dbo.TB_S_USER
                       WHERE USER_ID = @SUPERVISOR_USER_ID AND IS_DELETED = 'N')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'상급자를 찾을 수 없습니다.';
        RETURN;
    END

    -- 이메일은 사용 중인 계정 사이에서만 중복을 막는다.
    IF @EMAIL IS NOT NULL
       AND EXISTS (SELECT 1 FROM dbo.TB_S_USER
                   WHERE EMAIL = @EMAIL AND IS_DELETED = 'N' AND USER_ID <> @USER_ID)
    BEGIN
        SELECT Success = 0, ReturnMsg = N'이미 등록된 이메일입니다.';
        RETURN;
    END

    DECLARE @EXISTS bit = CASE WHEN EXISTS (SELECT 1 FROM dbo.TB_S_USER
                                            WHERE USER_ID = @USER_ID AND IS_DELETED = 'N')
                               THEN 1 ELSE 0 END;

    -- USER_ID 는 고유 인덱스라 삭제 계정의 아이디도 재사용할 수 없다.
    IF @EXISTS = 0 AND EXISTS (SELECT 1 FROM dbo.TB_S_USER WHERE USER_ID = @USER_ID)
    BEGIN
        SELECT Success = 0, ReturnMsg = N'삭제된 계정이 쓰던 아이디입니다. 삭제 목록에서 복구하세요.';
        RETURN;
    END

    IF @EXISTS = 0 AND (@PASSWORD_HASH IS NULL OR @PASSWORD_HASH = '')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'초기 비밀번호가 필요합니다.';
        RETURN;
    END

    -- 마지막 관리자를 강등하거나 잠그면 아무도 권한을 되돌릴 수 없게 된다.
    IF @EXISTS = 1
       AND (@ROLE_NAME <> 'ADMIN' OR @AUTHORIZED <> 'Y')
       AND EXISTS (SELECT 1 FROM dbo.TB_S_ROLE
                   WHERE USER_ID = @USER_ID AND ROLE_NAME = 'ADMIN' AND IS_DELETED = 'N')
       AND (SELECT COUNT(*)
            FROM dbo.TB_S_ROLE r
            INNER JOIN dbo.TB_S_USER u ON u.USER_ID = r.USER_ID
                                      AND u.IS_DELETED = 'N' AND u.AUTHORIZED = 'Y'
            WHERE r.ROLE_NAME = 'ADMIN' AND r.IS_DELETED = 'N') <= 1
    BEGIN
        SELECT Success = 0, ReturnMsg = N'마지막 관리자는 역할이나 상태를 바꿀 수 없습니다.';
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @EXISTS = 1
            UPDATE dbo.TB_S_USER
            SET FULL_NAME          = @FULL_NAME,
                EMAIL              = @EMAIL,
                DIVISION           = @DIVISION,
                TEAM               = @TEAM,
                SUPERVISOR_USER_ID = @SUPERVISOR_USER_ID,
                AUTHORIZED         = @AUTHORIZED,
                UPT_ID             = @REG_ID,
                UPT_DT             = GETDATE()
            WHERE USER_ID = @USER_ID AND IS_DELETED = 'N';
        ELSE
            INSERT INTO dbo.TB_S_USER
                (USER_ID, [PASSWORD], FULL_NAME, EMAIL, DIVISION, TEAM,
                 SUPERVISOR_USER_ID, AUTHORIZED, IS_DELETED, REG_ID, REG_DT)
            VALUES
                (@USER_ID, @PASSWORD_HASH, @FULL_NAME, @EMAIL, @DIVISION, @TEAM,
                 @SUPERVISOR_USER_ID, @AUTHORIZED, 'N', @REG_ID, GETDATE());

        UPDATE dbo.TB_S_ROLE
        SET IS_DELETED = 'Y', UPT_ID = @REG_ID, UPT_DT = GETDATE()
        WHERE USER_ID = @USER_ID AND IS_DELETED = 'N' AND ROLE_NAME <> @ROLE_NAME;

        IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_ROLE WHERE USER_ID = @USER_ID AND IS_DELETED = 'N')
            INSERT INTO dbo.TB_S_ROLE (USER_ID, ROLE_NAME, IS_DELETED, REG_ID, REG_DT)
            VALUES (@USER_ID, @ROLE_NAME, 'N', @REG_ID, GETDATE());

        COMMIT TRANSACTION;
        SELECT Success = 1, ReturnMsg = N'OK';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT Success = 0, ReturnMsg = ERROR_MESSAGE();
    END CATCH
END
GO

/* ------------------------------------------------------------
   3) 비밀번호 재설정 (관리자)
   ------------------------------------------------------------ */
CREATE OR ALTER PROCEDURE dbo.USP_S_UPDATE_USER_PASSWORD
    @USER_ID       varchar(20),
    @PASSWORD_HASH varchar(200),
    @UPT_ID        varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF @PASSWORD_HASH IS NULL OR @PASSWORD_HASH = ''
    BEGIN
        SELECT Success = 0, ReturnMsg = N'비밀번호가 비어 있습니다.';
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_USER WHERE USER_ID = @USER_ID AND IS_DELETED = 'N')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'사용자를 찾을 수 없습니다.';
        RETURN;
    END

    UPDATE dbo.TB_S_USER
    SET [PASSWORD] = @PASSWORD_HASH,
        UPT_ID     = @UPT_ID,
        UPT_DT     = GETDATE()
    WHERE USER_ID = @USER_ID AND IS_DELETED = 'N';

    SELECT Success = 1, ReturnMsg = N'OK';
END
GO

/* ------------------------------------------------------------
   4) 계정 상태 변경 (승인 / 대기 / 차단)
   ------------------------------------------------------------ */
CREATE OR ALTER PROCEDURE dbo.USP_S_UPDATE_USER_AUTHORIZED
    @USER_ID    varchar(20),
    @AUTHORIZED varchar(1),
    @UPT_ID     varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF @AUTHORIZED NOT IN ('Y', 'S', 'N')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'계정 상태 값이 올바르지 않습니다.';
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_USER WHERE USER_ID = @USER_ID AND IS_DELETED = 'N')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'사용자를 찾을 수 없습니다.';
        RETURN;
    END

    IF @AUTHORIZED <> 'Y'
       AND EXISTS (SELECT 1 FROM dbo.TB_S_ROLE
                   WHERE USER_ID = @USER_ID AND ROLE_NAME = 'ADMIN' AND IS_DELETED = 'N')
       AND (SELECT COUNT(*)
            FROM dbo.TB_S_ROLE r
            INNER JOIN dbo.TB_S_USER u ON u.USER_ID = r.USER_ID
                                      AND u.IS_DELETED = 'N' AND u.AUTHORIZED = 'Y'
            WHERE r.ROLE_NAME = 'ADMIN' AND r.IS_DELETED = 'N') <= 1
    BEGIN
        SELECT Success = 0, ReturnMsg = N'마지막 관리자는 상태를 바꿀 수 없습니다.';
        RETURN;
    END

    UPDATE dbo.TB_S_USER
    SET AUTHORIZED = @AUTHORIZED,
        UPT_ID     = @UPT_ID,
        UPT_DT     = GETDATE()
    WHERE USER_ID = @USER_ID AND IS_DELETED = 'N';

    SELECT Success = 1, ReturnMsg = N'OK';
END
GO

/* ------------------------------------------------------------
   5) 소프트 삭제
      문서 이력에서 이름을 계속 참조하므로 행은 남긴다.
   ------------------------------------------------------------ */
CREATE OR ALTER PROCEDURE dbo.USP_S_DELETE_USER
    @USER_ID varchar(20),
    @UPT_ID  varchar(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @USER_ID = @UPT_ID
    BEGIN
        SELECT Success = 0, ReturnMsg = N'자기 자신은 삭제할 수 없습니다.';
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_USER WHERE USER_ID = @USER_ID AND IS_DELETED = 'N')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'사용자를 찾을 수 없습니다.';
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM dbo.TB_S_ROLE
               WHERE USER_ID = @USER_ID AND ROLE_NAME = 'ADMIN' AND IS_DELETED = 'N')
       AND (SELECT COUNT(*)
            FROM dbo.TB_S_ROLE r
            INNER JOIN dbo.TB_S_USER u ON u.USER_ID = r.USER_ID
                                      AND u.IS_DELETED = 'N' AND u.AUTHORIZED = 'Y'
            WHERE r.ROLE_NAME = 'ADMIN' AND r.IS_DELETED = 'N') <= 1
    BEGIN
        SELECT Success = 0, ReturnMsg = N'마지막 관리자는 삭제할 수 없습니다.';
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM dbo.TB_S_MANUAL
               WHERE IS_DELETED = 'N' AND STATUS NOT IN ('OBSOLETE', 'PUBLISHED')
                 AND (REQUESTER_ID = @USER_ID OR APPROVER_ID = @USER_ID))
    BEGIN
        SELECT Success = 0, ReturnMsg = N'진행 중인 문서의 작성자 또는 승인자입니다. 담당을 넘긴 뒤 삭제하세요.';
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.TB_S_USER
        SET IS_DELETED = 'Y',
            AUTHORIZED = 'N',
            UPT_ID     = @UPT_ID,
            UPT_DT     = GETDATE()
        WHERE USER_ID = @USER_ID AND IS_DELETED = 'N';

        UPDATE dbo.TB_S_ROLE
        SET IS_DELETED = 'Y', UPT_ID = @UPT_ID, UPT_DT = GETDATE()
        WHERE USER_ID = @USER_ID AND IS_DELETED = 'N';

        -- 남은 계정이 사라진 상급자를 가리키지 않게 정리한다.
        UPDATE dbo.TB_S_USER
        SET SUPERVISOR_USER_ID = NULL, UPT_ID = @UPT_ID, UPT_DT = GETDATE()
        WHERE SUPERVISOR_USER_ID = @USER_ID AND IS_DELETED = 'N';

        COMMIT TRANSACTION;
        SELECT Success = 1, ReturnMsg = N'OK';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT Success = 0, ReturnMsg = ERROR_MESSAGE();
    END CATCH
END
GO

/* ------------------------------------------------------------
   6) 삭제 계정 복구
      로그인은 바로 열지 않고 미승인(S) 상태로 되돌린다.
   ------------------------------------------------------------ */
CREATE OR ALTER PROCEDURE dbo.USP_S_RESTORE_USER
    @USER_ID varchar(20),
    @UPT_ID  varchar(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EMAIL nvarchar(100) =
        (SELECT EMAIL FROM dbo.TB_S_USER WHERE USER_ID = @USER_ID AND IS_DELETED = 'Y');

    IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_USER WHERE USER_ID = @USER_ID AND IS_DELETED = 'Y')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'삭제된 사용자를 찾을 수 없습니다.';
        RETURN;
    END

    IF @EMAIL IS NOT NULL
       AND EXISTS (SELECT 1 FROM dbo.TB_S_USER
                   WHERE EMAIL = @EMAIL AND IS_DELETED = 'N' AND USER_ID <> @USER_ID)
    BEGIN
        SELECT Success = 0, ReturnMsg = N'같은 이메일을 쓰는 계정이 있어 복구할 수 없습니다. 해당 계정의 이메일을 먼저 정리하세요.';
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.TB_S_USER
        SET IS_DELETED = 'N',
            AUTHORIZED = 'S',
            UPT_ID     = @UPT_ID,
            UPT_DT     = GETDATE()
        WHERE USER_ID = @USER_ID AND IS_DELETED = 'Y';

        IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_ROLE WHERE USER_ID = @USER_ID AND IS_DELETED = 'N')
        BEGIN
            DECLARE @ROLE_NAME varchar(20) =
                (SELECT TOP (1) ROLE_NAME FROM dbo.TB_S_ROLE WHERE USER_ID = @USER_ID ORDER BY IDX DESC);

            INSERT INTO dbo.TB_S_ROLE (USER_ID, ROLE_NAME, IS_DELETED, REG_ID, REG_DT)
            VALUES (@USER_ID, ISNULL(@ROLE_NAME, 'USER'), 'N', @UPT_ID, GETDATE());
        END

        COMMIT TRANSACTION;
        SELECT Success = 1, ReturnMsg = N'OK';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT Success = 0, ReturnMsg = ERROR_MESSAGE();
    END CATCH
END
GO

PRINT '22_user_admin.sql 완료';
GO