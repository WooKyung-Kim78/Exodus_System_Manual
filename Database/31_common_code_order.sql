/* 공통 코드의 분류별 순서 변경 API. 반복 실행 가능. */
SET NOCOUNT ON;
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

        IF @ORDER_NUM <= 0
            SET @ORDER_NUM = ISNULL((SELECT MAX(ORDER_NUM) FROM dbo.TB_S_MASTER_COMMON_CODE
                                     WHERE CATEGORY = @CATEGORY AND IS_DELETED = 'N'), 0) + 1;

        INSERT INTO dbo.TB_S_MASTER_COMMON_CODE (CATEGORY, CODE, NAME, ORDER_NUM, REG_ID)
        VALUES (@CATEGORY, @CODE, @NAME, @ORDER_NUM, @USER_ID);

        SELECT Success = 1, ReturnMsg = CAST(SCOPE_IDENTITY() AS nvarchar(4000));
        RETURN;
    END

    UPDATE dbo.TB_S_MASTER_COMMON_CODE
    SET NAME      = @NAME,
        ORDER_NUM = CASE WHEN @ORDER_NUM > 0 THEN @ORDER_NUM ELSE ORDER_NUM END,
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

/* @ORDERS: 'IDX:ORDER_NUM' 을 콤마로 이어붙인 문자열 */
CREATE OR ALTER PROCEDURE dbo.USP_S_UPDATE_COMMON_CODE_ORDER
    @ORDERS  nvarchar(max),
    @USER_ID varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH parsed AS (
        SELECT IDX       = TRY_CAST(LEFT(value, CHARINDEX(':', value) - 1) AS bigint),
               ORDER_NUM = TRY_CAST(SUBSTRING(value, CHARINDEX(':', value) + 1, 20) AS int)
        FROM STRING_SPLIT(@ORDERS, ',')
        WHERE CHARINDEX(':', value) > 0
    )
    UPDATE c
    SET c.ORDER_NUM = p.ORDER_NUM,
        c.UPT_ID    = @USER_ID,
        c.UPT_DT    = GETDATE()
    FROM dbo.TB_S_MASTER_COMMON_CODE c
    INNER JOIN parsed p ON p.IDX = c.IDX
    WHERE c.IS_DELETED = 'N';

    SELECT Success = 1, ReturnMsg = CAST(@@ROWCOUNT AS nvarchar(4000));
END
GO
