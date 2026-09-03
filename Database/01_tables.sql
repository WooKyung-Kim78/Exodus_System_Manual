/* ============================================================
   01_tables.sql
   EXODUS System Manual — 신규 테이블 (반복 실행 가능)
   접두사 규칙: TB_S_ / USP_S_
   ============================================================ */
SET NOCOUNT ON;
GO

/* ------------------------------------------------------------
   권한 / 설정 / 공통
   ------------------------------------------------------------ */
IF OBJECT_ID('dbo.TB_S_ROLE', 'U') IS NULL
CREATE TABLE dbo.TB_S_ROLE (
    IDX         bigint        IDENTITY(1,1) NOT NULL,
    USER_ID     varchar(20)   NOT NULL,
    ROLE_NAME   varchar(20)   NOT NULL,
    IS_DELETED  varchar(1)    NOT NULL CONSTRAINT DF_TB_S_ROLE_IS_DELETED DEFAULT ('N'),
    REG_ID      varchar(20)   NOT NULL,
    REG_DT      datetime      NOT NULL CONSTRAINT DF_TB_S_ROLE_REG_DT DEFAULT (GETDATE()),
    UPT_ID      varchar(20)   NULL,
    UPT_DT      datetime      NULL,
    CONSTRAINT PK_TB_S_ROLE PRIMARY KEY CLUSTERED (IDX),
    CONSTRAINT CK_TB_S_ROLE_NAME CHECK (ROLE_NAME IN ('ADMIN', 'SUPPORTER', 'USER', 'READER'))
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_TB_S_ROLE_USER' AND object_id = OBJECT_ID('dbo.TB_S_ROLE'))
    CREATE UNIQUE NONCLUSTERED INDEX UX_TB_S_ROLE_USER ON dbo.TB_S_ROLE (USER_ID) WHERE IS_DELETED = 'N';
GO

IF OBJECT_ID('dbo.TB_S_SETTING', 'U') IS NULL
CREATE TABLE dbo.TB_S_SETTING (
    IDX       bigint         IDENTITY(1,1) NOT NULL,
    CATEGORY  varchar(50)    NOT NULL,
    TYPE      varchar(50)    NOT NULL,
    VALUE     nvarchar(1000) NULL,
    REG_ID    varchar(20)    NOT NULL,
    REG_DT    datetime       NOT NULL CONSTRAINT DF_TB_S_SETTING_REG_DT DEFAULT (GETDATE()),
    UPT_ID    varchar(20)    NULL,
    UPT_DT    datetime       NULL,
    CONSTRAINT PK_TB_S_SETTING PRIMARY KEY CLUSTERED (IDX),
    CONSTRAINT UX_TB_S_SETTING_TYPE UNIQUE (TYPE)
);
GO

IF OBJECT_ID('dbo.TB_S_MASTER_COMMON_CODE', 'U') IS NULL
CREATE TABLE dbo.TB_S_MASTER_COMMON_CODE (
    IDX         bigint        IDENTITY(1,1) NOT NULL,
    CATEGORY    varchar(50)   NOT NULL,
    CODE        varchar(50)   NOT NULL,
    NAME        nvarchar(200) NOT NULL,
    ORDER_NUM   int           NOT NULL CONSTRAINT DF_TB_S_CODE_ORDER DEFAULT (0),
    IS_DELETED  varchar(1)    NOT NULL CONSTRAINT DF_TB_S_CODE_IS_DELETED DEFAULT ('N'),
    REG_ID      varchar(20)   NOT NULL,
    REG_DT      datetime      NOT NULL CONSTRAINT DF_TB_S_CODE_REG_DT DEFAULT (GETDATE()),
    CONSTRAINT PK_TB_S_MASTER_COMMON_CODE PRIMARY KEY CLUSTERED (IDX),
    CONSTRAINT UX_TB_S_CODE UNIQUE (CATEGORY, CODE)
);
GO

IF OBJECT_ID('dbo.TB_S_UPLOAD_FILE', 'U') IS NULL
CREATE TABLE dbo.TB_S_UPLOAD_FILE (
    IDX         bigint        IDENTITY(1,1) NOT NULL,
    F_TB_NAME   varchar(50)   NOT NULL,
    F_CODE      varchar(50)   NOT NULL,
    FILE_NAME   nvarchar(300) NOT NULL,
    PATH        nvarchar(500) NOT NULL,
    WEB_PATH    nvarchar(500) NOT NULL,
    CONTENT_TYPE varchar(100) NULL,
    SIZE        bigint        NOT NULL,
    IS_DELETED  varchar(1)    NOT NULL CONSTRAINT DF_TB_S_UPLOAD_IS_DELETED DEFAULT ('N'),
    REG_ID      varchar(20)   NOT NULL,
    REG_DT      datetime      NOT NULL CONSTRAINT DF_TB_S_UPLOAD_REG_DT DEFAULT (GETDATE()),
    CONSTRAINT PK_TB_S_UPLOAD_FILE PRIMARY KEY CLUSTERED (IDX)
);
GO

IF OBJECT_ID('dbo.TB_S_MAIL_LOG', 'U') IS NULL
CREATE TABLE dbo.TB_S_MAIL_LOG (
    IDX          bigint         IDENTITY(1,1) NOT NULL,
    M_ID         varchar(10)    NULL,
    MAIL_TYPE    varchar(30)    NOT NULL,
    TO_LIST      nvarchar(2000) NOT NULL,
    CC_LIST      nvarchar(2000) NULL,
    SUBJECT      nvarchar(500)  NOT NULL,
    IS_SUCCESS   varchar(1)     NOT NULL,
    ERROR_MSG    nvarchar(2000) NULL,
    REG_ID       varchar(20)    NOT NULL,
    REG_DT       datetime       NOT NULL CONSTRAINT DF_TB_S_MAIL_LOG_REG_DT DEFAULT (GETDATE()),
    CONSTRAINT PK_TB_S_MAIL_LOG PRIMARY KEY CLUSTERED (IDX)
);
GO

/* ------------------------------------------------------------
   문서 헤더 / 참여 멤버
   ------------------------------------------------------------ */
IF OBJECT_ID('dbo.TB_S_MANUAL', 'U') IS NULL
CREATE TABLE dbo.TB_S_MANUAL (
    M_ID              varchar(10)   NOT NULL,
    DOC_NUM           varchar(50)   NULL,
    JOB_NUMBER        nvarchar(50)  NULL,
    MODEL_NAME        nvarchar(100) NOT NULL,
    LABEL             nvarchar(200) NULL,
    COOLING           nvarchar(100) NULL,
    OPTION_TEXT       nvarchar(500) NULL,
    REVISION          varchar(10)   NOT NULL CONSTRAINT DF_TB_S_MANUAL_REVISION DEFAULT ('A'),
    STATUS            varchar(20)   NOT NULL CONSTRAINT DF_TB_S_MANUAL_STATUS DEFAULT ('DRAFT'),
    PAGE_SIZE         varchar(10)   NOT NULL CONSTRAINT DF_TB_S_MANUAL_PAGE_SIZE DEFAULT ('LETTER'),
    PAGE_ORIENTATION  varchar(10)   NOT NULL CONSTRAINT DF_TB_S_MANUAL_PAGE_ORI DEFAULT ('PORTRAIT'),
    REQUESTER_ID      varchar(20)   NOT NULL,
    APPROVER_ID       varchar(20)   NULL,
    ORIGINAL_M_ID     varchar(10)   NULL,
    REQUEST_DATE      datetime      NULL,
    APPROVED_DATE     datetime      NULL,
    PUBLISH_DATE      datetime      NULL,
    OBSOLETE_DATE     datetime      NULL,
    IS_DELETED        varchar(1)    NOT NULL CONSTRAINT DF_TB_S_MANUAL_IS_DELETED DEFAULT ('N'),
    REG_ID            varchar(20)   NOT NULL,
    REG_DT            datetime      NOT NULL CONSTRAINT DF_TB_S_MANUAL_REG_DT DEFAULT (GETDATE()),
    UPT_ID            varchar(20)   NULL,
    UPT_DT            datetime      NULL,
    CONSTRAINT PK_TB_S_MANUAL PRIMARY KEY CLUSTERED (M_ID),
    CONSTRAINT CK_TB_S_MANUAL_STATUS CHECK (STATUS IN ('DRAFT', 'REVIEW', 'APPROVED', 'PUBLISHED', 'OBSOLETE')),
    CONSTRAINT CK_TB_S_MANUAL_PAGE_SIZE CHECK (PAGE_SIZE IN ('LETTER', 'A4'))
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_TB_S_MANUAL_STATUS' AND object_id = OBJECT_ID('dbo.TB_S_MANUAL'))
    CREATE NONCLUSTERED INDEX IX_TB_S_MANUAL_STATUS ON dbo.TB_S_MANUAL (STATUS, REG_DT DESC) WHERE IS_DELETED = 'N';
GO

IF OBJECT_ID('dbo.TB_S_MANUAL_MEMBER', 'U') IS NULL
CREATE TABLE dbo.TB_S_MANUAL_MEMBER (
    IDX          bigint        IDENTITY(1,1) NOT NULL,
    M_ID         varchar(10)   NOT NULL,
    USER_ID      varchar(20)   NOT NULL,
    TEAM         nvarchar(100) NULL,
    MEMBER_ROLE  varchar(20)   NOT NULL,
    IS_DELETED   varchar(1)    NOT NULL CONSTRAINT DF_TB_S_MEMBER_IS_DELETED DEFAULT ('N'),
    REG_ID       varchar(20)   NOT NULL,
    REG_DT       datetime      NOT NULL CONSTRAINT DF_TB_S_MEMBER_REG_DT DEFAULT (GETDATE()),
    CONSTRAINT PK_TB_S_MANUAL_MEMBER PRIMARY KEY CLUSTERED (IDX),
    CONSTRAINT FK_TB_S_MEMBER_MANUAL FOREIGN KEY (M_ID) REFERENCES dbo.TB_S_MANUAL (M_ID),
    CONSTRAINT CK_TB_S_MEMBER_ROLE CHECK (MEMBER_ROLE IN ('OWNER', 'EDITOR', 'REVIEWER', 'APPROVER'))
);
GO
-- 멤버십 검증(모든 쓰기 API의 권한 체크 경로)이 자주 타는 인덱스
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_TB_S_MEMBER_LOOKUP' AND object_id = OBJECT_ID('dbo.TB_S_MANUAL_MEMBER'))
    CREATE NONCLUSTERED INDEX IX_TB_S_MEMBER_LOOKUP ON dbo.TB_S_MANUAL_MEMBER (M_ID, USER_ID) WHERE IS_DELETED = 'N';
GO

/* ------------------------------------------------------------
   캔버스: 섹션 보드 / 요소
   ------------------------------------------------------------ */
IF OBJECT_ID('dbo.TB_S_SECTION', 'U') IS NULL
CREATE TABLE dbo.TB_S_SECTION (
    SEC_ID            bigint        IDENTITY(1,1) NOT NULL,
    M_ID              varchar(10)   NOT NULL,
    ORDER_NUM         int           NOT NULL CONSTRAINT DF_TB_S_SECTION_ORDER DEFAULT (0),
    TITLE             nvarchar(200) NOT NULL,
    CANVAS_X          int           NOT NULL CONSTRAINT DF_TB_S_SECTION_CX DEFAULT (0),
    CANVAS_Y          int           NOT NULL CONSTRAINT DF_TB_S_SECTION_CY DEFAULT (0),
    BOARD_W           int           NOT NULL CONSTRAINT DF_TB_S_SECTION_BW DEFAULT (816),
    BOARD_H           int           NOT NULL CONSTRAINT DF_TB_S_SECTION_BH DEFAULT (1056),
    ASSIGNED_TEAM     nvarchar(100) NULL,
    ASSIGNED_USER_ID  varchar(20)   NULL,
    SEC_STATUS        varchar(20)   NOT NULL CONSTRAINT DF_TB_S_SECTION_STATUS DEFAULT ('EMPTY'),
    IS_DELETED        varchar(1)    NOT NULL CONSTRAINT DF_TB_S_SECTION_IS_DELETED DEFAULT ('N'),
    ROW_VER           rowversion    NOT NULL,
    REG_ID            varchar(20)   NOT NULL,
    REG_DT            datetime      NOT NULL CONSTRAINT DF_TB_S_SECTION_REG_DT DEFAULT (GETDATE()),
    UPT_ID            varchar(20)   NULL,
    UPT_DT            datetime      NULL,
    CONSTRAINT PK_TB_S_SECTION PRIMARY KEY CLUSTERED (SEC_ID),
    CONSTRAINT FK_TB_S_SECTION_MANUAL FOREIGN KEY (M_ID) REFERENCES dbo.TB_S_MANUAL (M_ID),
    CONSTRAINT CK_TB_S_SECTION_STATUS CHECK (SEC_STATUS IN ('EMPTY', 'WRITING', 'DONE'))
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_TB_S_SECTION_MANUAL' AND object_id = OBJECT_ID('dbo.TB_S_SECTION'))
    CREATE NONCLUSTERED INDEX IX_TB_S_SECTION_MANUAL ON dbo.TB_S_SECTION (M_ID, ORDER_NUM) WHERE IS_DELETED = 'N';
GO

IF OBJECT_ID('dbo.TB_S_ELEMENT', 'U') IS NULL
CREATE TABLE dbo.TB_S_ELEMENT (
    ELE_ID        bigint         IDENTITY(1,1) NOT NULL,
    M_ID          varchar(10)    NOT NULL,
    SEC_ID        bigint         NOT NULL,
    ELE_TYPE      varchar(20)    NOT NULL,
    POS_X         float          NOT NULL CONSTRAINT DF_TB_S_ELE_X DEFAULT (0),
    POS_Y         float          NOT NULL CONSTRAINT DF_TB_S_ELE_Y DEFAULT (0),
    WIDTH         float          NOT NULL CONSTRAINT DF_TB_S_ELE_W DEFAULT (240),
    HEIGHT        float          NOT NULL CONSTRAINT DF_TB_S_ELE_H DEFAULT (120),
    ROTATION      float          NOT NULL CONSTRAINT DF_TB_S_ELE_ROT DEFAULT (0),
    Z_INDEX       int            NOT NULL CONSTRAINT DF_TB_S_ELE_Z DEFAULT (0),
    GROUP_ID      varchar(36)    NULL,
    CONTENT_HTML  nvarchar(max)  NULL,
    IMAGE_PATH    nvarchar(500)  NULL,
    CAPTION       nvarchar(500)  NULL,
    STYLE_JSON    nvarchar(max)  NULL,
    IS_DELETED    varchar(1)     NOT NULL CONSTRAINT DF_TB_S_ELE_IS_DELETED DEFAULT ('N'),
    ROW_VER       rowversion     NOT NULL,
    REG_ID        varchar(20)    NOT NULL,
    REG_DT        datetime       NOT NULL CONSTRAINT DF_TB_S_ELE_REG_DT DEFAULT (GETDATE()),
    UPT_ID        varchar(20)    NULL,
    UPT_DT        datetime       NOT NULL CONSTRAINT DF_TB_S_ELE_UPT_DT DEFAULT (GETDATE()),
    CONSTRAINT PK_TB_S_ELEMENT PRIMARY KEY CLUSTERED (ELE_ID),
    CONSTRAINT FK_TB_S_ELEMENT_SECTION FOREIGN KEY (SEC_ID) REFERENCES dbo.TB_S_SECTION (SEC_ID),
    CONSTRAINT CK_TB_S_ELE_TYPE CHECK (ELE_TYPE IN ('TEXT', 'IMAGE', 'TABLE', 'SHAPE', 'LINE'))
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_TB_S_ELEMENT_SECTION' AND object_id = OBJECT_ID('dbo.TB_S_ELEMENT'))
    CREATE NONCLUSTERED INDEX IX_TB_S_ELEMENT_SECTION ON dbo.TB_S_ELEMENT (SEC_ID, Z_INDEX) WHERE IS_DELETED = 'N';
GO
-- 4초 주기 델타 폴링(USP_S_SELECT_CANVAS_DELTA)의 주 조회 경로
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_TB_S_ELEMENT_DELTA' AND object_id = OBJECT_ID('dbo.TB_S_ELEMENT'))
    CREATE NONCLUSTERED INDEX IX_TB_S_ELEMENT_DELTA ON dbo.TB_S_ELEMENT (M_ID, UPT_DT);
GO

IF OBJECT_ID('dbo.TB_S_ELEMENT_TABLE_ROW', 'U') IS NULL
CREATE TABLE dbo.TB_S_ELEMENT_TABLE_ROW (
    ROW_ID      bigint        IDENTITY(1,1) NOT NULL,
    ELE_ID      bigint        NOT NULL,
    ORDER_NUM   int           NOT NULL CONSTRAINT DF_TB_S_ROW_ORDER DEFAULT (0),
    ITEM        nvarchar(200) NULL,
    SPEC        nvarchar(500) NULL,
    UNIT        nvarchar(50)  NULL,
    MIN_VAL     nvarchar(50)  NULL,
    TYP_VAL     nvarchar(50)  NULL,
    MAX_VAL     nvarchar(50)  NULL,
    REMARK      nvarchar(500) NULL,
    IS_DELETED  varchar(1)    NOT NULL CONSTRAINT DF_TB_S_ROW_IS_DELETED DEFAULT ('N'),
    CONSTRAINT PK_TB_S_ELEMENT_TABLE_ROW PRIMARY KEY CLUSTERED (ROW_ID),
    CONSTRAINT FK_TB_S_ROW_ELEMENT FOREIGN KEY (ELE_ID) REFERENCES dbo.TB_S_ELEMENT (ELE_ID)
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_TB_S_ROW_ELEMENT' AND object_id = OBJECT_ID('dbo.TB_S_ELEMENT_TABLE_ROW'))
    CREATE NONCLUSTERED INDEX IX_TB_S_ROW_ELEMENT ON dbo.TB_S_ELEMENT_TABLE_ROW (ELE_ID, ORDER_NUM) WHERE IS_DELETED = 'N';
GO

/* ------------------------------------------------------------
   변경이력 / 코멘트 / 접속 표시
   ------------------------------------------------------------ */
IF OBJECT_ID('dbo.TB_S_ELEMENT_HISTORY', 'U') IS NULL
CREATE TABLE dbo.TB_S_ELEMENT_HISTORY (
    HIS_ID        bigint        IDENTITY(1,1) NOT NULL,
    M_ID          varchar(10)   NOT NULL,
    SEC_ID        bigint        NULL,
    ELE_ID        bigint        NULL,
    ACTION        varchar(20)   NOT NULL,
    FIELD_NAME    varchar(50)   NULL,
    BEFORE_VALUE  nvarchar(max) NULL,
    AFTER_VALUE   nvarchar(max) NULL,
    REG_ID        varchar(20)   NOT NULL,
    REG_DT        datetime      NOT NULL CONSTRAINT DF_TB_S_HIS_REG_DT DEFAULT (GETDATE()),
    CONSTRAINT PK_TB_S_ELEMENT_HISTORY PRIMARY KEY CLUSTERED (HIS_ID),
    CONSTRAINT CK_TB_S_HIS_ACTION CHECK (ACTION IN ('CREATE', 'UPDATE', 'MOVE', 'RESIZE', 'DELETE', 'RESTORE', 'REORDER', 'ASSIGN'))
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_TB_S_HIS_LOOKUP' AND object_id = OBJECT_ID('dbo.TB_S_ELEMENT_HISTORY'))
    CREATE NONCLUSTERED INDEX IX_TB_S_HIS_LOOKUP ON dbo.TB_S_ELEMENT_HISTORY (M_ID, SEC_ID, REG_DT DESC);
GO

IF OBJECT_ID('dbo.TB_S_COMMENT', 'U') IS NULL
CREATE TABLE dbo.TB_S_COMMENT (
    CMT_ID         bigint        IDENTITY(1,1) NOT NULL,
    M_ID           varchar(10)   NOT NULL,
    SEC_ID         bigint        NULL,
    ELE_ID         bigint        NULL,
    PIN_X          float         NULL,
    PIN_Y          float         NULL,
    PARENT_CMT_ID  bigint        NULL,
    BODY           nvarchar(max) NOT NULL,
    IS_RESOLVED    varchar(1)    NOT NULL CONSTRAINT DF_TB_S_CMT_RESOLVED DEFAULT ('N'),
    IS_DELETED     varchar(1)    NOT NULL CONSTRAINT DF_TB_S_CMT_IS_DELETED DEFAULT ('N'),
    REG_ID         varchar(20)   NOT NULL,
    REG_DT         datetime      NOT NULL CONSTRAINT DF_TB_S_CMT_REG_DT DEFAULT (GETDATE()),
    CONSTRAINT PK_TB_S_COMMENT PRIMARY KEY CLUSTERED (CMT_ID),
    CONSTRAINT FK_TB_S_CMT_MANUAL FOREIGN KEY (M_ID) REFERENCES dbo.TB_S_MANUAL (M_ID),
    CONSTRAINT FK_TB_S_CMT_PARENT FOREIGN KEY (PARENT_CMT_ID) REFERENCES dbo.TB_S_COMMENT (CMT_ID)
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_TB_S_CMT_LOOKUP' AND object_id = OBJECT_ID('dbo.TB_S_COMMENT'))
    CREATE NONCLUSTERED INDEX IX_TB_S_CMT_LOOKUP ON dbo.TB_S_COMMENT (M_ID, SEC_ID, REG_DT) WHERE IS_DELETED = 'N';
GO

IF OBJECT_ID('dbo.TB_S_PRESENCE', 'U') IS NULL
CREATE TABLE dbo.TB_S_PRESENCE (
    M_ID            varchar(10) NOT NULL,
    CLIENT_ID       varchar(36) NOT NULL,
    USER_ID         varchar(20) NOT NULL,
    SEC_ID          bigint      NULL,
    EDITING_ELE_ID  bigint      NULL,
    LAST_PING_DT    datetime    NOT NULL CONSTRAINT DF_TB_S_PRESENCE_PING DEFAULT (GETDATE()),
    CONSTRAINT PK_TB_S_PRESENCE PRIMARY KEY CLUSTERED (M_ID, CLIENT_ID)
);
GO

PRINT '01_tables.sql 완료';
GO
