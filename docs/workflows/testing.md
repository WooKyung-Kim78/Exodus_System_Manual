# 백엔드 테스트

프로젝트: `tests/ExodusSystemManual.Tests` (xUnit, net8.0). 메인 csproj 는 `tests\**` 를 컴파일에서 제외한다.

```bash
dotnet test tests/ExodusSystemManual.Tests                      # 단위 테스트 (DB 불필요)
EXODUS_TEST_DB="<전용 테스트 DB 접속 문자열>" dotnet test tests/ExodusSystemManual.Tests   # 통합 테스트 포함
```

## 정책: 코드를 짜면 테스트도 같이 짠다

| 변경 | 요구되는 테스트 |
|---|---|
| `Utils/` 의 로직, 정적 함수, 파싱/변환 | 단위 테스트 필수 (정상 + 경계 + 거부 케이스) |
| 보안 관련 (`HtmlSanitize`, `ImageUpload`, `PasswordHelper`, `LoginThrottle`) | 단위 테스트 필수. **막아야 하는 입력이 막히는지**를 반드시 포함 |
| 권한 규칙 (`UFN_S_*`, `USP_S_SELECT_MANUAL_ACCESS`) 변경 | `Integration/` 테스트: 역할·담당 팀·상태 조합별 결과 |
| 컨트롤러 액션 | 로직이 있으면 `Utils`/서비스로 빼서 그쪽을 테스트한다. 얇은 액션 자체는 테스트하지 않는다 |
| 버그 수정 | 재현하는 실패 테스트를 먼저 추가 |

- 테스트 없이 끝냈다면 이유를 보고한다 (예: DB 없이 검증 불가).
- 테스트를 통과시키려고 **기대값을 코드에 맞춰 바꾸지 않는다.** 기대값이 틀렸다는 근거가 있을 때만.

## 구조·규칙

- 폴더는 대상 코드와 대응: `Utils/XxxTests.cs`, `Integration/…`. 클래스명 `<대상>Tests`, 메서드명은 `동작_조건` 형태의 서술.
- 파일 시스템은 임시 폴더(`Path.GetTempPath()`) + `IDisposable` 정리. 저장소 안 `wwwroot/Upload` 를 건드리지 않는다.
- 시간·랜덤·외부 서비스(SMTP, Playwright, datasheet DB)는 단위 테스트에서 호출하지 않는다.
- 새 정적/순수 로직은 처음부터 테스트 가능하게 (의존성은 생성자 주입, 컨트롤러에 로직 넣지 않기).

## DB 통합 테스트

- `[RequiresDbFact]` 를 쓰면 `EXODUS_TEST_DB` 가 없을 때 자동으로 건너뛴다.
- **전용 테스트 DB 에만** 연결한다. 운영/공유 DB 금지. `Database/` 스크립트를 번호 순서로 적용한 빈 DB 를 쓴다.
- 데이터를 만드는 테스트는 트랜잭션으로 감싸 롤백하거나, 고유 ID 로 만들고 정리한다.
- 접속 문자열을 코드·로그·문서에 남기지 않는다.

## HTTP·E2E

Playwright E2E는 `web/e2e/`에 있으며, 전용 개발/테스트 DB에서만 실행한다. 실행 방법과 골든 이미지 갱신은 [e2e.md](e2e.md)를 따른다. 컨트롤러 HTTP 수준 테스트(`WebApplicationFactory`) 확대는 [known-issues.md](../known-issues.md)에 남아 있다.
