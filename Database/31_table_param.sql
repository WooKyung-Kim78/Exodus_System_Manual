/* ============================================================
   31_table_param.sql
   표 블록 Title / Function 사전 등록 — 반복 실행 가능

     1) 관리자가 Title 과 Function 을 미리 등록한다. Function 은 글자색·굵기 등 서식이 있어 HTML 로 둔다.
        같은 Title 에 Function 이 여러 개일 수 있다 (예: RF OUTPUT 커넥터 종류).
     2) 편집기 표에서 Title 을 고르면 등록된 Function 이 채워지고, 그 뒤 편집기로 자유롭게 고친다.
     3) 초기값은 "2025 ~ 2026년 Parameter 정리.xlsx" 기준. 표가 비어 있을 때만 넣는다.
   ============================================================ */
SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.TB_S_TABLE_PARAM', 'U') IS NULL
CREATE TABLE dbo.TB_S_TABLE_PARAM (
    IDX         bigint         IDENTITY(1,1) NOT NULL,
    TITLE       nvarchar(200)  NOT NULL,
    FUNC_HTML   nvarchar(max)  NOT NULL,
    ORDER_NUM   int            NOT NULL CONSTRAINT DF_TB_S_TABLE_PARAM_ORDER DEFAULT (0),
    IS_DELETED  varchar(1)     NOT NULL CONSTRAINT DF_TB_S_TABLE_PARAM_IS_DELETED DEFAULT ('N'),
    REG_ID      varchar(20)    NOT NULL,
    REG_DT      datetime       NOT NULL CONSTRAINT DF_TB_S_TABLE_PARAM_REG_DT DEFAULT (GETDATE()),
    UPT_ID      varchar(20)    NULL,
    UPT_DT      datetime       NULL,
    CONSTRAINT PK_TB_S_TABLE_PARAM PRIMARY KEY CLUSTERED (IDX)
);
GO

/* 초판(평문 FUNC_TEXT)을 이미 실행한 DB 는 HTML 로 옮긴다. 컬럼이 없을 때 컴파일 오류가 나지 않게 동적 SQL 로 돌린다. */
IF COL_LENGTH('dbo.TB_S_TABLE_PARAM', 'FUNC_TEXT') IS NOT NULL
BEGIN
    IF COL_LENGTH('dbo.TB_S_TABLE_PARAM', 'FUNC_HTML') IS NULL
        EXEC (N'ALTER TABLE dbo.TB_S_TABLE_PARAM ADD FUNC_HTML nvarchar(max) NULL;');

    EXEC (N'
        UPDATE dbo.TB_S_TABLE_PARAM
        SET FUNC_HTML = N''<p>'' +
            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(FUNC_TEXT,
                N''&'', N''&amp;''), N''<'', N''&lt;''), N''>'', N''&gt;''),
                N''  '', N'' &nbsp;''), NCHAR(13), N''''), NCHAR(10), N''<br>'') + N''</p>''
        WHERE FUNC_HTML IS NULL;

        UPDATE dbo.TB_S_TABLE_PARAM
        SET FUNC_HTML = N''<p>Ethernet Communication Female Connector, RJ-45<br><span style="color:#FF0000;">Ethernet port use warning</span><br><span style="color:#FF0000;">Do not use with PoE switch</span></p>''
        WHERE TITLE = N''ETHERNET''
          AND FUNC_HTML = N''<p>Ethernet Communication Female Connector, RJ-45<br>Ethernet port use warning<br>Do not use with PoE switch</p>'';

        ALTER TABLE dbo.TB_S_TABLE_PARAM ALTER COLUMN FUNC_HTML nvarchar(max) NOT NULL;
        ALTER TABLE dbo.TB_S_TABLE_PARAM DROP COLUMN FUNC_TEXT;');
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_TB_S_TABLE_PARAM_TITLE')
    CREATE INDEX IX_TB_S_TABLE_PARAM_TITLE ON dbo.TB_S_TABLE_PARAM (TITLE, ORDER_NUM) WHERE IS_DELETED = 'N';
GO

/* 초기값. 운영 중 고친 내용을 덮지 않도록 한 건도 없을 때만 넣는다. */
IF NOT EXISTS (SELECT 1 FROM dbo.TB_S_TABLE_PARAM)
INSERT INTO dbo.TB_S_TABLE_PARAM (TITLE, FUNC_HTML, ORDER_NUM, REG_ID)
SELECT s.TITLE, s.FUNC_HTML, s.ORDER_NUM, 'system'
FROM (VALUES
    (N'0dBm INPUT', N'<p>N-Female, 0dBm INPUT Connector.</p>', 1),
    (N'50Ω OUTPUT', N'<p>7/16 DIN-Female , 50Ω OUTPUT Connector.</p>', 1),
    (N'50Ω OUTPUT', N'<p>N-Female , 50Ω OUTPUT Connector.</p>', 2),
    (N'50Ω OUTPUT', N'<p>WRD650 Waveguide , 50Ω OUTPUT Connector.</p>', 3),
    (N'AC POWER CONNECTOR', N'<p>100 - 240VAC, 47/63Hz, 1500W MAX, IEC60320-14 Connector</p>', 1),
    (N'AC POWER CONNECTOR', N'<p>120 - 208VAC, 3-Phase 50/60Hz,1500W MAX MS3102E22-22P Connector.</p>', 2),
    (N'ATTEN DIAL', N'<p>0 ~ 20Db Attenuation Range Dial</p>', 1),
    (N'CONTORL POWER', N'<p>MS3102E-18 MIL Connector.</p>', 1),
    (N'CONTROL', N'<p>15Pin D-Sub Female Connector</p>', 1),
    (N'CONTROL 1', N'<p>15Pin D-Sub Female Connector</p>', 1),
    (N'CONTROL 2', N'<p>15Pin D-Sub Female Connector</p>', 1),
    (N'CONTROL 3', N'<p>15Pin D-Sub Female Connector.</p>', 1),
    (N'CONTROL 4', N'<p>15Pin D-Sub Female Connector.</p>', 1),
    (N'CONTROL POWER', N'<p>MS3102E-18 MIL Connector.</p>', 1),
    (N'Cooling FAN', N'<p>System Outlet Cooling FAN</p>', 1),
    (N'COOLING POWER', N'<p>MS3102E-22 MIL Connector.</p>', 1),
    (N'DEBUG', N'<p>System Controller Debugging Female Connector<br>Customer Should not use this port without permission from the factory</p>', 1),
    (N'DIV-1 CONNECTOR', N'<p>SMA Female Connector.</p>', 1),
    (N'DIV-2 CONNECTOR', N'<p>SMA Female Connector.</p>', 1),
    (N'DIV-3 CONNECTOR', N'<p>SMA Female Connector.</p>', 1),
    (N'DIV-4 CONNECTOR', N'<p>SMA Female Connector.</p>', 1),
    (N'DIV-5 CONNECTOR', N'<p>SMA Female Connector.</p>', 1),
    (N'DIV-6 CONNECTOR', N'<p>SMA Female Connector.</p>', 1),
    (N'DIV-7 CONNECTOR', N'<p>SMA Female Connector.</p>', 1),
    (N'DIV-8 CONNECTOR', N'<p>SMA Female Connector.</p>', 1),
    (N'ETHERNET', N'<p>Ethernet Communication Female Connector, RJ-45<br><span style="color:#FF0000;">Ethernet port use warning</span><br><span style="color:#FF0000;">Do not use with PoE switch</span></p>', 1),
    (N'FAN POWER', N'<p>MS3102E-18 MIL Connector.</p>', 1),
    (N'FAN1 POWER', N'<p>MS3102E-18 MIL Connector.</p>', 1),
    (N'FAN2 POWER', N'<p>MS3102E-22 MIL Connector.</p>', 1),
    (N'FAULT LED', N'<p>System Fault LED: Turn ON an LED when Over-Temp, Ext. Shutdown</p>', 1),
    (N'FWD SAMPLE', N'<p>N-Female, FWD SAMPLE Connector<br>(SAMPLE PORT MUST BE TERMNATED AT ALL TIME)</p>', 1),
    (N'GATE CONTROL', N'<p>CW mode - a TTL-high of 3.3-5.0vdc is applied to allow RF amplification<br>Pulse mode - a TTL-high/TTL-low Pulse signal at the required rep-rate and pulse<br>Width is applied to allow RF amplification</p>', 1),
    (N'GND', N'<p>Frame Ground</p>', 1),
    (N'GPIB', N'<p>IEEE-488 GPIB Interface Connector, Female</p>', 1),
    (N'HPA POWER 1', N'<p>MS3102E-22 MIL Connector.</p>', 1),
    (N'HPA POWER 2', N'<p>MS3102E-22 MIL Connector.</p>', 1),
    (N'I/O', N'<p>System I/O Female 9-Pin D-sub Connector<br>P1 : N/A &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;: P6 : N/A<br>P2 : N/A &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;: P7 : N/A<br>P3 : HPA Current Monitor &nbsp;: P8 : Ground<br>P4 : HPA Temp. Monitor &nbsp; &nbsp;: P9 : Ground<br>P5 : System Shutdown (TTL High, Open System Enable, TTL Low System Disable)</p>', 1),
    (N'INTERLOCK', N'<p>BNC Female, Safety Interlock Connector<br>Interlock Close Circuit : Normal operation<br>Interlock Open Circuit : RF Off operation</p>', 1),
    (N'J2 OUTPUT CONNECTOR', N'<p>7/16 DIN Female OUTPUT Connector.</p>', 1),
    (N'J4 CONNECTOR', N'<p>SMA Female Connector.</p>', 1),
    (N'LCD DISPLAY', N'<p>7" Touch screen LCD Display, System Control LCD Panel</p>', 1),
    (N'OUT-1', N'<p>N-Female, OUT-1 Connector.</p>', 1),
    (N'OUT-2', N'<p>N-Female, OUT-2 Connector.</p>', 1),
    (N'POWER LED', N'<p>Turn On a LED when the Power Supply on</p>', 1),
    (N'POWER SWITCH', N'<p>System Power Switch</p>', 1),
    (N'RACK FAN', N'<p>MS3102E-18 MIL Connector.</p>', 1),
    (N'REV SAMPLE', N'<p>N-Female, REV SAMPLE Connector.<br>(SAMPLE PORT MUST BE TERMNATED AT ALL TIME.)</p>', 1),
    (N'RF INPUT', N'<p>2.4mm Female, RF INPUT Connector</p>', 1),
    (N'RF INPUT', N'<p>2.92mm K Type Female, RF INPUT Connector.v</p>', 2),
    (N'RF INPUT', N'<p>N Famale, RF INPUT Connector</p>', 3),
    (N'RF INPUT', N'<p>SMA-Female, RF INPUT Connector</p>', 4),
    (N'RF OUTPUT', N'<p>1 5/8" EIA, RF OUTPUT Flange Connector</p>', 1),
    (N'RF OUTPUT', N'<p>7/16 DIN Female, RF OUTPUT Connector.</p>', 2),
    (N'RF OUTPUT', N'<p>N Famale, RF OUTPUT Connector</p>', 3),
    (N'RF OUTPUT', N'<p>SMA-Famale, RF OUTPUT Connector</p>', 4),
    (N'RF OUTPUT', N'<p>WR22 Waveguide, RF OUTPUT Connector</p>', 5),
    (N'RF OUTPUT', N'<p>WRD180 Waveguide, RF OUTPUT Connector.</p>', 6),
    (N'RF OUTPUT', N'<p>WRD28 Waveguide, RF OUTPUT Connector.</p>', 7),
    (N'RF OUTPUT', N'<p>WRD650 Waveguide, RF OUTPUT Connector.</p>', 8),
    (N'RF SAMPLE', N'<p>N-Female, RF SAMPLE Connector<br>(SAMPLE PORT MUST BE TERMNATED AT ALL TIME)</p>', 1),
    (N'RF SAMPLE', N'<p>SMA-Female, RF SAMPLE Connector<br>(SAMPLE PORT MUST BE TERMNATED AT ALL TIME)</p>', 2),
    (N'RF SYSTEM 1 POWER', N'<p>MS3102E-18 MIL Connector.</p>', 1),
    (N'RF SYSTEM 1 POWER', N'<p>MS3102E-22 MIL Connector</p>', 2),
    (N'RF SYSTEM 2 POWER', N'<p>MS3102E-18 MIL Connector.</p>', 1),
    (N'RF SYSTEM 2 POWER', N'<p>MS3102E-22 MIL Connector</p>', 2),
    (N'RF SYSTEM 3 POWER', N'<p>MS3102E-18 MIL Connector.</p>', 1),
    (N'RF SYSTEM 4 POWER', N'<p>MS3102E-18 MIL Connector.</p>', 1),
    (N'RS-422', N'<p>System RS-422 Communication / Female 9-Pin D-sub Connector.<br>P1 TX- &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;: P6 N/C<br>P2 TX+ &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;: P7 N/C<br>P3 RX+ &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;: P8 N/C<br>P4 RX- &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;: P9 N/C<br>P5 GND (RS-422)</p>', 1),
    (N'SELECTE BAND A', N'<p>Band A Operation LED</p>', 1),
    (N'SELECTE BAND B', N'<p>Band B Operation LED</p>', 1),
    (N'TX LED', N'<p>LED on when RF Power is output</p>', 1),
    (N'USB', N'<p>USB Communication Connector, Type A Female<br>(DO NOT CONNECT THE USB WHEN THE SYSTEM IS OFF)</p>', 1),
    (N'Handle Bolt', N'<p>Hex Sockethead Cap Screw M6-15mm</p>', 1)
) AS s (TITLE, FUNC_HTML, ORDER_NUM);
GO

/* 같은 Title 안에서는 ORDER_NUM 이 작은 Function 이 기본값이다. */
CREATE OR ALTER PROCEDURE dbo.USP_S_SELECT_TABLE_PARAM_LIST
AS
BEGIN
    SET NOCOUNT ON;

    SELECT p.IDX, p.TITLE, p.FUNC_HTML, p.ORDER_NUM, p.REG_DT, p.UPT_DT
    FROM dbo.TB_S_TABLE_PARAM p
    WHERE p.IS_DELETED = 'N'
    ORDER BY p.TITLE, p.ORDER_NUM, p.IDX;
END
GO

/* FUNC_HTML 은 앱에서 정제한 뒤 넘긴다. */
CREATE OR ALTER PROCEDURE dbo.USP_S_MERGE_TABLE_PARAM
    @IDX       bigint        = NULL,
    @TITLE     nvarchar(200),
    @FUNC_HTML nvarchar(max),
    @ORDER_NUM int           = 0,
    @USER_ID   varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    SET @TITLE = LTRIM(RTRIM(ISNULL(@TITLE, N'')));
    SET @FUNC_HTML = ISNULL(@FUNC_HTML, N'');

    IF @TITLE = N'' OR LTRIM(RTRIM(@FUNC_HTML)) = N''
    BEGIN
        SELECT Success = 0, ReturnMsg = N'Title 과 Function 은 필수입니다.';
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM dbo.TB_S_TABLE_PARAM
               WHERE TITLE = @TITLE AND FUNC_HTML = @FUNC_HTML AND IS_DELETED = 'N'
                 AND (@IDX IS NULL OR IDX <> @IDX))
    BEGIN
        SELECT Success = 0, ReturnMsg = N'같은 Title 에 같은 Function 이 이미 있습니다.';
        RETURN;
    END

    IF @IDX IS NULL
    BEGIN
        INSERT INTO dbo.TB_S_TABLE_PARAM (TITLE, FUNC_HTML, ORDER_NUM, REG_ID)
        VALUES (@TITLE, @FUNC_HTML, @ORDER_NUM, @USER_ID);

        SELECT Success = 1, ReturnMsg = CAST(SCOPE_IDENTITY() AS nvarchar(4000));
        RETURN;
    END

    UPDATE dbo.TB_S_TABLE_PARAM
    SET TITLE     = @TITLE,
        FUNC_HTML = @FUNC_HTML,
        ORDER_NUM = @ORDER_NUM,
        UPT_ID    = @USER_ID,
        UPT_DT    = GETDATE()
    WHERE IDX = @IDX AND IS_DELETED = 'N';

    IF @@ROWCOUNT = 0
    BEGIN
        SELECT Success = 0, ReturnMsg = N'항목을 찾을 수 없습니다.';
        RETURN;
    END

    SELECT Success = 1, ReturnMsg = CAST(@IDX AS nvarchar(4000));
END
GO

CREATE OR ALTER PROCEDURE dbo.USP_S_DELETE_TABLE_PARAM
    @IDX     bigint,
    @USER_ID varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.TB_S_TABLE_PARAM
    SET IS_DELETED = 'Y', UPT_ID = @USER_ID, UPT_DT = GETDATE()
    WHERE IDX = @IDX AND IS_DELETED = 'N';

    IF @@ROWCOUNT = 0
    BEGIN
        SELECT Success = 0, ReturnMsg = N'항목을 찾을 수 없습니다.';
        RETURN;
    END

    SELECT Success = 1, ReturnMsg = N'OK';
END
GO

PRINT '31_table_param.sql 완료';
GO
