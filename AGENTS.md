# EXODUS System Manual — 에이전트 작업 지침

.NET 8 JSON API + SQL Server 저장 프로시저 + Vue 3 SPA로 만든 사내 매뉴얼 작성/PDF 발행 앱.
이 파일은 **에이전트가 작업 전에 알아야 할 것**만 담는다. 상세는 [docs/](docs/README.md).

## 작업 전 체크 (순서대로)

1. 무엇을 바꾸는지에 맞는 문서를 먼저 읽는다 (아래 표). 문서와 코드가 다르면 **코드가 맞다** — 다르다고 알리고 같은 변경에서 문서를 고친다. 범위 밖 문제를 발견하면 [docs/known-issues.md](docs/known-issues.md) 에 한 줄 추가하고 넘어간다.
2. 바꾸려는 것과 가장 비슷한 기존 코드를 찾아 **그 패턴을 그대로 따른다**. 새 방식을 도입하지 않는다.
3. 같은 로직이 2곳 이상이면 복사하지 말고 공통으로 올린다 ([docs/policies/coding-standards.md](docs/policies/coding-standards.md)).
4. **백엔드 코드는 테스트를 같이 작성**하고 `dotnet test tests/ExodusSystemManual.Tests` 를 통과시킨다 ([docs/workflows/testing.md](docs/workflows/testing.md)). 그 밖의 검증은 [verification.md](docs/workflows/verification.md).

| 작업 | 먼저 읽을 문서 |
|---|---|
| 컨트롤러/API 추가·수정 | [architecture/backend.md](docs/architecture/backend.md), [workflows/add-endpoint.md](docs/workflows/add-endpoint.md) |
| DB 스키마·프로시저 변경 | [architecture/database.md](docs/architecture/database.md), [workflows/change-database.md](docs/workflows/change-database.md) |
| 권한/역할 관련 | [architecture/permissions.md](docs/architecture/permissions.md) |
| 화면(cshtml/JS/CSS) | [architecture/frontend.md](docs/architecture/frontend.md), [workflows/add-screen.md](docs/workflows/add-screen.md) |
| 미리보기·PDF·글자 크기·스타일 | [architecture/document-rendering.md](docs/architecture/document-rendering.md), [design-system/font-size.md](docs/design-system/font-size.md) (개편 예정) |
| 테스트 작성·실행 | [workflows/testing.md](docs/workflows/testing.md) |
| 보안/HTML/업로드/비밀 값 | [policies/security.md](docs/policies/security.md) |
| 코드 스타일·DRY·명명 | [policies/coding-standards.md](docs/policies/coding-standards.md) |

## 절대 규칙

- **DB 접근은 저장 프로시저만.** 테이블 직접 CRUD·인라인 SQL 을 새로 만들지 않는다. (기존 예외는 database.md 참고)
- **권한은 서버(프로시저 결과)가 결정한다.** 쓰기 API 는 반드시 `DenyIfNotEditable` 류 검사를 먼저 거친다. 화면 버튼 숨김은 편의일 뿐이다.
- **본문 HTML 은 `HtmlSanitize.Clean` 을 거쳐 저장/렌더**한다. 우회하는 경로를 만들지 않는다.
- **`Database/NN_*.sql` 은 이미 실행된 이력이다.** 기존 파일을 수정하지 말고 다음 번호로 새 파일을 만든다. 프로시저 최신 정의는 번호가 가장 큰 파일에 있다.
- **비밀 값(접속 문자열, SMTP 비밀번호)을 커밋·출력·로그·문서에 넣지 않는다.** 로컬 `appsettings.Development.json` 에 실제 접속 정보가 들어 있을 수 있다 — 읽더라도 인용하지 말고, 커밋 대상에서 제외한다.
- 커밋·푸시는 사용자가 요청할 때만 한다.

## 자주 쓰는 명령

```bash
dotnet build                                # 컴파일 검증 (.cs 변경 시 필수)
dotnet test tests/ExodusSystemManual.Tests  # 단위 테스트 (DB 통합 테스트는 EXODUS_TEST_DB 필요, 없으면 자동 skip)
dotnet watch run --launch-profile https     # https://localhost:7177
npm run dev --prefix web                    # http://localhost:5173
npm run typecheck --prefix web
npm run test --prefix web
npm run e2e --prefix web                    # 서버와 Vite를 먼저 실행
dotnet run -- seed-admin admin              # 관리자 비밀번호 (반드시 사람이 터미널에서. 에이전트는 실행 금지)
```

전제: .NET 8 SDK 설치됨 (`dotnet --version` 이 8.x). 없으면 임의로 설치하지 말고 사용자에게 알린다.

접속 문자열은 User Secrets (`ConnectionStrings:DefaultConnection`, 선택 `DatasheetConnection`). DB 스크립트를 에이전트가 운영/공유 DB 에 실행하지 않는다 — 스크립트만 작성하고 실행은 사용자에게 맡긴다.

## 코드 지도

```
Program.cs                 DI·세션·Antiforgery. seed-admin 분기가 맨 위
Controllers/Common/BaseController.cs   모든 컨트롤러의 부모 (JsonOk/JsonFail, GetManualAccess)
Controllers/Attributes/    [Auth] 페이지용 / [AjaxAuth] API용
Controllers/               Manual(문서·미리보기·PDF) · Editor(목차·블록) · Admin · Auth · Home
Data/                      ApplicationDbContext(exodus) · DatasheetDbContext(읽기 전용, 외부 DB)
Models/                    엔티티 + 프로시저 결과 DTO + Input* 요청 DTO
tests/ExodusSystemManual.Tests   xUnit 테스트 (메인 csproj 는 tests\** 제외)
Utils/                     HtmlSanitize · PdfRenderer · DatasheetSpec · SendMail · ImageUpload ...
Database/                  번호순 idempotent SQL (CREATE OR ALTER)
web/src/pages/ + web/src/features/           화면 1개 = Vue 페이지 + 기능 컴포넌트
wwwroot/css/doc-type.css   문서 글자 크기 단일 진실 공급원
wwwroot/assets/fonts/      문서(PDF/미리보기)용 Carlito·Poppins 글꼴
```

## 도메인 한 줄 요약

문서(`TB_S_MANUAL`) → 목차(`TB_S_SECTION`, 3단계, 담당 팀 지정) → 블록(`TB_S_ELEMENT`, 텍스트/이미지).
문서 상태 `DRAFT → REVIEW → APPROVED → PUBLISHED / OBSOLETE`, **DRAFT 에서만 수정 가능**.
Job Number·SPECIFICATIONS 사양은 별도 DB(exodus_datasheet)에서 **저장 없이 볼 때마다** 읽어 그린다.
