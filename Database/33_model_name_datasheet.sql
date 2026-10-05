/* ============================================================
   33_model_name_datasheet.sql
   datasheet 선택을 Job Number 에서 Model Name 으로 옮긴다 — 반복 실행 가능

     - Job Number 는 직접 입력하는 값이 되어 PROCESS_ID(= TB_DS_DOCUMENT.D_ID) 와 상관이 없다.
     - 예전 프로시저는 Job Number 가 비면 PROCESS_ID 를 지웠다. 이 줄만 뺀다.
   ============================================================ */
SET NOCOUNT ON;
GO

/* ---------- 기본 정보 수정 (26_doc_version.sql 기준, Job Number 와 PROCESS_ID 분리) ---------- */
CREATE OR ALTER PROCEDURE dbo.USP_S_UPDATE_MANUAL_HEADER
    @M_ID        varchar(10),
    @JOB_NUMBER  nvarchar(50)  = NULL,
    @MODEL_NAME  nvarchar(100),
    @LABEL       nvarchar(200) = NULL,
    @COOLING     nvarchar(100) = NULL,
    @OPTION_TEXT nvarchar(500) = NULL,
    @PAGE_SIZE   varchar(10)   = NULL,
    @USER_ID     varchar(20),
    @PROCESS_ID  varchar(50)   = NULL,
    @DOC_VERSION nvarchar(20)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_MANUAL WHERE M_ID = @M_ID AND STATUS = 'DRAFT' AND IS_DELETED = 'N')
    BEGIN
        SELECT Success = 0, ReturnMsg = N'작성(DRAFT) 상태의 문서만 수정할 수 있습니다.';
        RETURN;
    END

    SET @JOB_NUMBER = NULLIF(LTRIM(RTRIM(@JOB_NUMBER)), N'');
    SET @PROCESS_ID = NULLIF(LTRIM(RTRIM(@PROCESS_ID)), '');
    SET @DOC_VERSION = NULLIF(LTRIM(RTRIM(@DOC_VERSION)), N'');

    UPDATE dbo.TB_S_MANUAL
    SET JOB_NUMBER  = @JOB_NUMBER,
        PROCESS_ID  = @PROCESS_ID,
        MODEL_NAME  = @MODEL_NAME,
        LABEL       = @LABEL,
        COOLING     = @COOLING,
        OPTION_TEXT = @OPTION_TEXT,
        PAGE_SIZE   = ISNULL(@PAGE_SIZE, PAGE_SIZE),
        DOC_VERSION = ISNULL(@DOC_VERSION, DOC_VERSION),
        UPT_ID      = @USER_ID,
        UPT_DT      = GETDATE()
    WHERE M_ID = @M_ID;

    SELECT Success = 1, ReturnMsg = N'OK';
END
GO

PRINT '33_model_name_datasheet.sql 완료';
GO
