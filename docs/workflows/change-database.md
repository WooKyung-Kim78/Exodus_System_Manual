# DB 변경 체크리스트

1. **다음 번호 결정** — `ls Database/ | tail -3` 의 최대 번호 + 1. (`NN_<snake_case_설명>.sql`)
2. **프로시저 수정이면** 최신 정의부터 가져온다: `grep -l "CREATE OR ALTER PROCEDURE dbo.<이름>\b" Database/*.sql` 중 번호가 가장 큰 파일에서 **전체 복사** 후 수정. 다른 프로시저가 같은 함수를 쓰면 영향 범위도 확인.
3. **파일 작성** — 머리 주석(목적, 반복 실행 가능), `SET NOCOUNT ON; GO`, 컬럼 추가는 `IF NOT EXISTS (sys.columns ...)`, 기본값 제약은 이름 있는 제약 + 존재 확인, 데이터 보정은 조건부 `UPDATE`.
4. **C# 동기화 (같은 변경에서)**
   - 결과 컬럼 변경 → `Models/*Dtos.cs` 속성 추가/삭제 (모든 속성 ↔ 컬럼 1:1)
   - 새 조회 프로시저 → `ApplicationDbContext` 에 DbSet(이름 = 프로시저명) + `HasNoKey().ToView(null)`
   - 새 파라미터 → 호출부 `FromSqlRaw` 인자 순서/개수 확인 (`{0}, {1}` 위치 인자는 순서가 곧 계약)
5. **쓰기 프로시저** — `@USER_ID` 마지막 인자, 감사 컬럼 갱신, 소프트 삭제, 권한 함수 호출, `SELECT Success, ReturnMsg` 로 종료.
6. **실행은 사용자에게 맡긴다.** 실행 순서와 영향(기존 데이터 보정 여부)을 요약해 알린다.

주의: 이미 존재하는 결과 DTO 에 컬럼을 추가하고 SQL 을 아직 실행하지 않은 환경에서는 앱이 500 을 낸다. 배포 순서 = SQL 먼저, 앱 나중.
