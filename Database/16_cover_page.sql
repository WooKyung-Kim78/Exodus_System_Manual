/* ============================================================
   16_cover_page.sql
   미리보기 표지 구성 (반복 실행 가능)

     1) 문서마다 표지 이미지(제품 사진) 를 올릴 수 있게 한다.
     2) 표지 상단 고정 문구와 로고는 공통 코드로 관리한다.
        관리자/서포터가 화면에서 바꿀 수 있어야 하므로 하드코딩하지 않는다.
   ============================================================ */
SET NOCOUNT ON;
GO

IF COL_LENGTH('dbo.TB_S_MANUAL', 'COVER_IMAGE_PATH') IS NULL
    ALTER TABLE dbo.TB_S_MANUAL ADD COVER_IMAGE_PATH nvarchar(500) NULL;
GO

/* 공통 코드에 수정 이력 컬럼 추가 */
IF COL_LENGTH('dbo.TB_S_MASTER_COMMON_CODE', 'UPT_ID') IS NULL
    ALTER TABLE dbo.TB_S_MASTER_COMMON_CODE ADD UPT_ID varchar(20) NULL;
GO
IF COL_LENGTH('dbo.TB_S_MASTER_COMMON_CODE', 'UPT_DT') IS NULL
    ALTER TABLE dbo.TB_S_MASTER_COMMON_CODE ADD UPT_DT datetime NULL;
GO

/* 표지 기본값. 이미 있으면 값을 덮어쓰지 않는다(운영 중 수정한 문구 보존). */
MERGE dbo.TB_S_MASTER_COMMON_CODE AS t
USING (VALUES
    ('COVER', 'TITLE_LINE1', N'Instruction Manual and Quick Start Guide', 1),
    ('COVER', 'TITLE_LINE2', N'Exodus Advanced Communications',          2),
    ('COVER', 'LOGO_PATH',   N'',                                        3)
) AS s (CATEGORY, CODE, NAME, ORDER_NUM)
   ON t.CATEGORY = s.CATEGORY AND t.CODE = s.CODE
WHEN NOT MATCHED THEN
    INSERT (CATEGORY, CODE, NAME, ORDER_NUM, REG_ID)
    VALUES (s.CATEGORY, s.CODE, s.NAME, s.ORDER_NUM, 'system');
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_COMMON_CODE_LIST
    @CATEGORY varchar(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT c.IDX, c.CATEGORY, c.CODE, c.NAME, c.ORDER_NUM, c.REG_DT, c.UPT_DT
    FROM dbo.TB_S_MASTER_COMMON_CODE c
    WHERE c.IS_DELETED = 'N'
      AND (@CATEGORY IS NULL OR @CATEGORY = '' OR c.CATEGORY = @CATEGORY)
    ORDER BY c.CATEGORY, c.ORDER_NUM, c.CODE;
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_MERGE_COMMON_CODE
    @IDX       bigint       = NULL,
    @CATEGORY  varchar(50),
    @CODE      varchar(50),
    @NAME      nvarchar(200),
    @ORDER_NUM int          = 0,
    @USER_ID   varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF (@CATEGORY IS NULL OR LTRIM(RTRIM(@CATEGORY)) = '' OR @CODE IS NULL OR LTRIM(RTRIM(@CODE)) = '')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'분류와 코드는 필수입니다.';
        RETURN;
    END

    IF @IDX IS NULL
    BEGIN
        IF EXISTS (SELECT 1 FROM dbo.TB_S_MASTER_COMMON_CODE
                   WHERE CATEGORY = @CATEGORY AND CODE = @CODE)
        BEGIN
            SELECT Success = 0, ReturnMsg = N'같은 분류에 이미 있는 코드입니다.';
            RETURN;
        END

        INSERT INTO dbo.TB_S_MASTER_COMMON_CODE (CATEGORY, CODE, NAME, ORDER_NUM, REG_ID)
        VALUES (@CATEGORY, @CODE, @NAME, @ORDER_NUM, @USER_ID);

        SELECT Success = 1, ReturnMsg = CAST(SCOPE_IDENTITY() AS nvarchar(4000));
        RETURN;
    END

    UPDATE dbo.TB_S_MASTER_COMMON_CODE
    SET NAME      = @NAME,
        ORDER_NUM = @ORDER_NUM,
        UPT_ID    = @USER_ID,
        UPT_DT    = GETDATE()
    WHERE IDX = @IDX AND IS_DELETED = 'N';

    IF @@ROWCOUNT = 0
    BEGIN
        SELECT Success = 0, ReturnMsg = N'코드를 찾을 수 없습니다.';
        RETURN;
    END

    SELECT Success = 1, ReturnMsg = CAST(@IDX AS nvarchar(4000));
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_DELETE_COMMON_CODE
    @IDX     bigint,
    @USER_ID varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    -- 표지 구성 항목이 사라지면 미리보기가 비어버린다.
    IF EXISTS (SELECT 1 FROM dbo.TB_S_MASTER_COMMON_CODE
               WHERE IDX = @IDX AND CATEGORY = 'COVER')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'표지 항목은 삭제할 수 없습니다. 내용을 비워 두세요.';
        RETURN;
    END

    UPDATE dbo.TB_S_MASTER_COMMON_CODE
    SET IS_DELETED = 'Y', UPT_ID = @USER_ID, UPT_DT = GETDATE()
    WHERE IDX = @IDX AND IS_DELETED = 'N';

    IF @@ROWCOUNT = 0
    BEGIN
        SELECT Success = 0, ReturnMsg = N'코드를 찾을 수 없습니다.';
        RETURN;
    END

    SELECT Success = 1, ReturnMsg = N'OK';
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_UPDATE_MANUAL_COVER_IMAGE
    @M_ID    varchar(10),
    @PATH    nvarchar(500) = NULL,
    @USER_ID varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_MANUAL WHERE M_ID = @M_ID AND STATUS = 'DRAFT' AND IS_DELETED = 'N')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'작성(DRAFT) 상태의 문서만 수정할 수 있습니다.';
        RETURN;
    END

    IF @PATH = N'' SET @PATH = NULL;

    UPDATE dbo.TB_S_MANUAL
    SET COVER_IMAGE_PATH = @PATH, UPT_ID = @USER_ID, UPT_DT = GETDATE()
    WHERE M_ID = @M_ID AND IS_DELETED = 'N';

    SELECT Success = 1, ReturnMsg = N'OK';
END
GO

/* 문서 헤더 조회에 표지 이미지 포함 */
CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_MANUAL
    @M_ID varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        m.M_ID, m.DOC_NUM, m.JOB_NUMBER, m.MODEL_NAME, m.LABEL, m.COOLING, m.OPTION_TEXT,
        m.REVISION, m.STATUS, m.PAGE_SIZE, m.PAGE_ORIENTATION, m.HEADING_STYLE_JSON,
        m.COVER_IMAGE_PATH,
        m.REQUESTER_ID, REQUESTER_NAME = ru.FULL_NAME,
        m.APPROVER_ID,  APPROVER_NAME  = au.FULL_NAME,
        m.ORIGINAL_M_ID, m.REQUEST_DATE, m.APPROVED_DATE, m.PUBLISH_DATE, m.OBSOLETE_DATE,
        m.REG_DT, m.UPT_DT
    FROM dbo.TB_S_MANUAL m
    LEFT JOIN dbo.TB_S_USER ru ON ru.USER_ID = m.REQUESTER_ID
    LEFT JOIN dbo.TB_S_USER au ON au.USER_ID = m.APPROVER_ID
    WHERE m.M_ID = @M_ID
      AND m.IS_DELETED = 'N';
END
GO

PRINT '16_cover_page.sql 완료';
GO
