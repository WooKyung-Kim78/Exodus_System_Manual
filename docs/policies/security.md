# 보안 정책

이미 내려진 결정을 **되돌리지 않기 위한** 목록. 편해 보여도 우회하지 않는다.

## 코드에서 지킬 것

| 영역 | 규칙 | 근거 위치 |
|---|---|---|
| 인증 | 특정 아이디(admin 등)를 통과시키는 분기 금지. 실패 메시지는 "아이디 또는 비밀번호" 하나로 | AuthController |
| 비밀번호 | `PasswordHelper` (PBKDF2)만 사용. 평문/무염 해시 금지. 프로시저는 평문을 받지 않는다 | Utils/PasswordHelper |
| 로그인 제한 | 계정+IP 15분 5회 (`LoginThrottle`) | Utils/LoginThrottle |
| 세션 | 로그인 성공 시 `Session.Clear()` 후 재작성 (세션 고정 방어) | AuthController |
| 리다이렉트 | `returnUrl` 은 `IsLocalUrl` 검사 후에만 사용 | AuthController |
| CSRF | 쓰기 액션 `[ValidateAntiForgeryToken]`. 화면은 `ajaxSetting.js` 가 헤더 자동 부착 | Program.cs |
| HTML | 사용자 HTML 은 **저장 시 + 렌더 직전 두 번** `HtmlSanitize.Clean`. 화이트리스트 밖 태그/속성/CSS/스킴(`javascript:`, `data:`)은 제거됨 | Utils/HtmlSanitize |
| Razor 출력 | `@Html.Raw` 를 새로 쓰지 않는다. 불가피하면 반드시 정제된 값만 | Views |
| 업로드 | 확장자 + **매직 바이트** 검사, 크기 제한, 업로드 경로는 서버가 생성(사용자 파일명으로 경로 만들지 않음) | Utils/ImageUpload |
| SQL | `FromSqlRaw` 는 위치 인자(`{0}`)나 `SqlParameter` 로만. 문자열 보간/연결로 SQL 조립 금지 | database.md |
| 권한 | 서버에서 항상 재검사. 클라이언트가 보낸 사용자 ID·역할·권한 플래그를 믿지 않는다 | permissions.md |
| 캐시 | 로그인 사용자별 JSON 은 `JsonOk/JsonFail` 이 `no-store` 를 붙인다. 직접 `Ok(...)` 로 우회하지 않는다 (CKEditor 업로드 응답처럼 규약이 정해진 경우만 예외) | BaseController |
| PDF | Chromium 은 가상 origin 외 모든 요청을 차단. 이 차단을 풀지 않는다 (SSRF/내부망 접근 방지) | Utils/PdfRenderer |
| 메일 | SMTP 비밀번호는 DataProtection 암호화 저장, 화면에 다시 내려주지 않는다 | Utils/SendMail |

## 비밀 값

- 접속 문자열은 **User Secrets**. `appsettings*.json` 에 실제 값을 커밋하지 않는다.
  - 현재 작업 트리의 `appsettings.Development.json` 은 로컬에서 실제 DB 접속 정보가 들어간 채 수정 상태일 수 있다. **읽더라도 출력·인용·문서화하지 말고, 커밋에 포함하지 않는다** (`git add` 시 파일 단위로 지정하고 이 파일은 제외). 노출 이력이 있다면 사용자에게 자격 증명 교체를 권한다.
- `App_Data/`(DataProtection 키, mail-drop), `wwwroot/Upload/` 는 gitignore 대상 — 예외 없이 유지.
- 로그·오류 응답·문서·테스트 데이터에 비밀번호, 토큰, 접속 문자열, 사용자 개인정보를 넣지 않는다.

## 에이전트 행동 제한

- `seed-admin` 은 비밀번호를 콘솔에서 직접 입력받는 명령이다. 입력을 파이프/리다이렉트로 우회해 실행하지 않는다.
- 운영/공유 DB 에 SQL 스크립트를 실행하지 않는다. `05_seed_testusers.sql` 은 운영 실행 금지.
- 운영 배포 전 항목(테스트 계정 삭제, DataProtection 키 암호화, `TrustServerCertificate` 제거, 실발송 전환)을 임의로 "해결됨" 처리하지 않는다.
