# 데이터베이스

SQL Server. 앱은 **저장 프로시저로만** 읽고 쓴다. 스키마 원본은 `Database/NN_*.sql`.

## 호출 규칙

- 조회: `_db.<DbSet 이름>.FromSqlRaw("EXECUTE dbo.<프로시저>", ...).AsEnumerable()...`
  - **DbSet 이름 = 프로시저 이름** ([ApplicationDbContext](../../Data/ApplicationDbContext.cs)). 새 조회 프로시저를 추가하면 DbSet + `HasNoKey().ToView(null)` 를 함께 추가한다.
  - 결과 DTO 는 `Models/*Dtos.cs`. **DTO 의 모든 속성에 대응하는 컬럼이 결과 집합에 있어야 한다** — 하나라도 없으면 런타임 500. 프로시저 컬럼과 DTO 를 같은 변경에서 맞춘다.
  - `FromSqlRaw` 는 **첫 번째 결과 집합만** 읽는다. 프로시저 하나에 SELECT 를 여러 개 두지 않는다.
  - `.AsEnumerable()` 후 LINQ 를 붙인다 (`FromSqlRaw` 위에 `Where` 를 얹으면 서브쿼리로 감싸져 프로시저에서 깨진다).
- 쓰기: `_db.ResultModel.FromSqlRaw("EXECUTE dbo.USP_S_MERGE_...")` → `ResultModel{Success,ReturnMsg}`.
- 위치 인자(`{0}, {1}`)는 문자열 보간이 아니라 EF 파라미터화이므로 안전하다. **`$"..."` 보간으로 SQL 을 조립하지 않는다.**
- NULL 은 `(object?)x ?? DBNull.Value`.
- **`binary`/`varbinary`/`bigint` 등 타입이 중요한 파라미터는 `SqlParameter` 로 타입을 명시**한다 (예: `ROW_VER binary(8)`). 위치 인자로 `DBNull` 을 주면 nvarchar 로 전송돼 변환 오류. 예시: `EditorController.MergeBlock` 의 `Param(...)` 헬퍼.
- EF 로 테이블을 직접 다루는 기존 예외: 로그인 사용자/역할 조회, `TB_S_SETTING`(SMTP), `TB_S_MAIL_LOG`, `TB_S_UPLOAD_FILE` 삽입. 이 범위를 넓히지 않는다.

## 명명·공통 컬럼

| 대상 | 규칙 |
|---|---|
| 테이블 | `TB_S_<이름>` |
| 프로시저 | `USP_S_{SELECT\|MERGE\|INSERT\|UPDATE\|DELETE\|UPSERT}_<대상>[_LIST]` |
| 함수 | `UFN_S_<이름>` (권한 판정 등 재사용 로직) |
| 컬럼 | UPPER_SNAKE. Y/N 플래그는 `varchar(1)` |
| 소프트 삭제 | `IS_DELETED` = `'Y'/'N'`. **행을 지우지 않는다.** 모든 조회에 `IS_DELETED='N'` 조건 |
| 감사 | `REG_ID, REG_DT, UPT_ID, UPT_DT`. 쓰기 프로시저는 마지막 인자로 `@USER_ID` |
| ID 길이 | `M_ID varchar(10)`, `USER_ID varchar(20)` — DTO 의 `[StringLength]` 와 맞춘다 |
| 동시성 | 블록은 `ROW_VER`(rowversion) 낙관적 잠금. 충돌 시 `ReturnMsg='CONFLICT'` |

## Database/ 스크립트 관리 (가장 흔한 실수 지점)

- 번호순 실행, **모두 idempotent**(`IF NOT EXISTS`, `CREATE OR ALTER`). 실행 이력을 남기는 마이그레이션 도구가 없다.
- **기존 파일 수정 금지. 항상 다음 번호(`31_...sql`)로 추가.** 파일 머리 주석에 목적과 "반복 실행 가능"을 적는다.
- 프로시저를 바꿀 때는 **가장 최근 정의(번호가 가장 큰 파일)를 통째로 복사해 필요한 부분만 수정**한다. `CREATE OR ALTER` 는 통째 교체라서, 옛 정의에서 복사하면 이후 변경이 조용히 사라진다.
  - 최신 정의 찾기: `grep -l "CREATE OR ALTER PROCEDURE dbo.<이름>\b" Database/*.sql` 후 **파일명 숫자가 가장 큰 것**. (예: `USP_S_UPDATE_DOC_STYLE` 은 30, `USP_S_INSERT_MANUAL` 은 27)
  - 정렬은 문자열이 아니라 숫자 기준.
- 모델(C# DTO)에 속성을 추가하면 대응 SQL 스크립트를 먼저(같은 변경에) 만든다.
- `03_seed.sql` 은 admin 비밀번호를 넣지 않는다. `05_seed_testusers.sql` 은 테스트 전용 — 운영에 실행하지 않는다.
- 스크립트를 **에이전트가 실행하지 않는다.** 작성 후 사용자에게 실행 순서를 알린다.

## 권한 함수 (변경 시 파급 큼)

`UFN_S_CAN_READ_MANUAL`(14), `UFN_S_IS_MANUAL_PARTICIPANT`(13), `UFN_S_CAN_EDIT_SECTION`(12→13). 화면·프로시저가 같은 함수를 공유한다. 정의를 바꾸면 목록/접근/목차 프로시저 결과가 모두 바뀌므로 [permissions.md](permissions.md) 를 먼저 읽는다.

## 레거시 잔재

`TB_S_MANUAL_MEMBER`(참여자), `TB_S_COMMENT`, `TB_S_PRESENCE`, `TB_S_ELEMENT_TABLE_ROW`, `USP_S_*CANVAS*` 는 이전 캔버스/참여자 모델의 흔적이다 (`TB_S_ELEMENT`·`TB_S_SECTION` 은 현역). 참여 범위는 이제 **목차의 담당 팀**이 정한다. 이쪽에 의존하는 신규 코드를 만들지 않는다.
