# API(엔드포인트) 추가 체크리스트

가장 가까운 기존 액션을 찾아 복제한다. 문서/목차/블록은 `EditorController`, 문서 단위는 `ManualController`, 관리는 `AdminController`.

1. **프로시저 준비** — 필요하면 [change-database.md](change-database.md) 먼저. 조회면 DTO + DbSet 도 필요.
2. **요청 DTO** — 파라미터 3개 초과 또는 검증이 필요하면 `Input*` (한국어 ErrorMessage, ID 길이는 컬럼과 동일).
3. **액션 작성** — [backend.md](../architecture/backend.md) 의 표준 형태.
   - API: `[AjaxAuth]` (역할 제한이 있으면 문자열 인자: `"ADMIN, SUPPORTER"`). 페이지 액션은 만들지 않는다.
   - 쓰기: `[ValidateAntiForgeryToken]` + `DenyIfNotEditable` (문서 데이터일 때). Vue가 JSON DTO를 보내면 매개변수에 `[FromBody]`를 붙인다.
   - 응답은 `JsonOk`/`JsonFail` 만
4. **HTML 을 받으면** `_sanitizer.Clean` 후 저장.
5. **화면 연결** — `web/src/api/client.ts`의 `api`, `query`, `formData`를 사용한다. 토큰은 클라이언트가 자동으로 붙인다.
6. **권한 확인** — 읽기 전용 역할(READER), 담당 팀 아닌 사용자, DRAFT 아닌 문서로 접근 시 막히는지 (프로시저 단에서도).
7. **테스트** — 액션에 넣은 로직은 `Utils` 로 빼서 테스트한다 ([testing.md](testing.md)). 화면 확인은 [verification.md](verification.md). 문서 갱신이 필요하면 함께.

경로는 [api-routes.md](../architecture/api-routes.md)에 같은 변경으로 추가한다.

흔한 실수: 쓰기 액션에서 `GetManualAccess` 의 `CAN_READ` 만 확인 / 새 쓰기 프로시저에 `UFN_S_CAN_EDIT_SECTION` 누락 / `DBNull` 위치 인자로 binary 파라미터 전달 / `Ok(new {...})` 직접 반환.
