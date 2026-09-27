# EXODUS System Manual

여러 팀이 함께 시스템 매뉴얼을 작성하고, 승인을 거쳐 PDF로 배포하기 위한 사내 웹 애플리케이션입니다.

문서를 만든 사람이 기본 정보와 목차를 정하면, 목차마다 지정된 담당 팀이 자기 몫의 내용을 채웁니다.
작성이 끝나면 미리보기에서 확인하고 PDF로 내려받습니다.

---

## 기술 구성

| 영역 | 사용 기술 |
|---|---|
| 런타임 | .NET 8 (ASP.NET Core MVC + Razor) |
| 데이터 접근 | EF Core 8 (SqlServer) — 모든 읽기/쓰기를 저장 프로시저로 처리 |
| 데이터베이스 | SQL Server |
| 프런트엔드 | Vue 2.7 (전역 스크립트), jQuery, Bootstrap 5, Metronic 8 |
| 본문 편집기 | CKEditor 5 (ESM 빌드, import map 으로 로드) |
| PDF | Microsoft.Playwright (서버에서 Headless Chromium 으로 생성) |
| 메일 | MailKit |
| HTML 정제 | HtmlSanitizer (Ganss.Xss) |

Razor 런타임 컴파일을 켜 두어 `.cshtml` 수정은 새로고침만으로 반영됩니다. `.cs` 는 재시작이 필요합니다.

---

## 처음 설치하기

### 1. 데이터베이스

`Database/` 폴더의 스크립트를 **번호 순서대로** 실행합니다. 모두 반복 실행해도 안전합니다.

```
00_alter_user.sql              기존 TB_S_USER 보정 (PK/UNIQUE/제약)
01_tables.sql                  테이블 생성
02_procedures.sql              기본 프로시저
03_seed.sql                    관리자 계정 뼈대, SMTP 설정 행
04_procedures_phase2.sql       목록 조회 프로시저 분리
05_seed_testusers.sql          테스트 사용자 5명 (운영 배포 전 삭제)
06_procedures_notify.sql       메일 수신자 조회
07_alter_document_model.sql    캔버스 → 문서형 전환 (목차 계층/블록 순서)
08_alter_section_style.sql     목차별 제목 스타일
09_label_cooling_template_role.sql  Label/Cooling 고정, 목차 템플릿, 역할
10_template_assignee.sql       템플릿 담당 지정
11_template_team_only.sql      템플릿 담당자 제거 (팀만 유지)
12_section_team_permission.sql 목차 담당 팀 기반 편집 권한
13_drop_member_model.sql       참여자 테이블 사용 중단, 팀 기반으로 전환
14_manual_visibility.sql       문서 열람 범위 제한
15_section_history.sql         목차 수정 이력 조회
16_cover_page.sql              표지 구성 (로고·고정 문구·제품 이미지)
17_body_font.sql               본문 글꼴
18_body_spacing.sql            행간·자간, 글자 크기 고정
19_font_calibri.sql            Calibri 추가
28_font_carlito.sql            본문 글꼴 Calibri → Carlito (오픈 라이선스)
```

> 05 번은 테스트 계정입니다. 운영 환경에 올리기 전에 삭제하거나 비밀번호를 교체하세요.

### 2. 접속 문자열

저장소에는 접속 정보가 포함되어 있지 않습니다. User Secrets 에 등록합니다.

```powershell
dotnet user-secrets set "ConnectionStrings:DefaultConnection" `
  "Server=<호스트>;Database=exodus;User ID=<계정>;Password=<비밀번호>;Encrypt=True;TrustServerCertificate=True"
```

`Encrypt=True` 는 필수입니다. 자체 서명 인증서를 쓰는 서버라면 `TrustServerCertificate=True` 도 함께 지정합니다.

Job Number 목록과 SPECIFICATIONS 사양은 exodus_datasheet DB 의 `USP_DS_SELECT_MAIN_PUBLISHED`,
`USP_DS_SELECT_DATASHEET_DETAIL` 에서 읽습니다. 다른 DB 에 있다면 아래도 등록합니다.
등록하지 않으면 `DefaultConnection` 을 그대로 사용합니다.

```powershell
dotnet user-secrets set "ConnectionStrings:DatasheetConnection" `
  "Server=<호스트>;Database=exodus_datasheet;User ID=<계정>;Password=<비밀번호>;Encrypt=True;TrustServerCertificate=True"
```

### 3. 관리자 비밀번호

`03_seed.sql` 은 admin 계정을 만들되 비밀번호는 넣지 않습니다. 아래 명령으로 직접 지정합니다.

```powershell
dotnet run -- seed-admin admin
```

이 명령은 **터미널에서 직접** 실행해야 합니다. 입력이 리다이렉트된 환경(스크립트·자동화 도구)에서는 실행을 거부합니다.

### 4. 실행

```powershell
dotnet watch run --launch-profile https
```

`https://localhost:7177` 로 접속합니다.

---

## 권한 모델

### 사용자 역할 — `TB_S_ROLE`

| 역할 | 설명 |
|---|---|
| ADMIN | 전체 열람·수정, 관리 메뉴 사용 |
| USER | 담당 팀 문서만 열람·수정 |
| READER | 열람 전용 |

`Admin › User Roles` 에서 변경합니다. 마지막 관리자는 강등할 수 없습니다.

### 문서 접근 — 목차의 담당 팀이 기준

참여자를 따로 등록하지 않습니다. **목차에 지정된 담당 팀이 곧 참여 범위**입니다.

```
열람  ADMIN / READER 역할, 문서를 만든 사람, 목차 담당 팀 소속
수정  위 대상 중 DRAFT 상태에서, 목차에 팀이 있으면 그 팀만
```

판정은 `UFN_S_CAN_READ_MANUAL`, `UFN_S_IS_MANUAL_PARTICIPANT`, `UFN_S_CAN_EDIT_SECTION` 세 함수가 담당하고,
화면과 저장 프로시저가 같은 함수를 참조합니다. 화면의 버튼 비활성화는 편의일 뿐이고 **실제 차단은 프로시저에서** 이뤄집니다.

---

## 주요 기능

### 목차 템플릿 — `Admin › Section Templates`

Label(Exodus/OEM) · Cooling(Air/Liquid) 조합별로 목차를 미리 정의합니다.
둘 다 비우면 모든 조합에 적용되는 공통 항목이 됩니다.

- **필수** — 문서를 만들 때 자동으로 삽입
- **옵션** — 작성자가 `템플릿` 버튼으로 골라서 추가

이미 추가한 항목도 목록에 남고 `추가됨` 으로 표시됩니다. 목차를 지우면 다시 추가할 수 있습니다.

### 문서 편집

목차 관리는 **문서 정보** 화면에서, 본문 작성은 **편집기**에서 합니다.

본문은 블록 단위입니다. 블록 하나가 `TB_S_ELEMENT` 한 행이며, 텍스트(CKEditor)와 이미지 두 종류가 있습니다.
저장은 블록 단위 낙관적 동시성(`ROW_VER`)으로 처리되어, 같은 목차라도 서로 다른 블록이면 충돌하지 않습니다.

### 문서 스타일 — 문서 정보 › 기본 정보

문서 전체에 동일하게 적용됩니다.

| 항목 | 값 |
|---|---|
| 본문 글꼴 | Arial · Carlito(Calibri 호환) · Verdana · Tahoma · Georgia · Times New Roman (기본 Carlito) |
| 본문 글자 크기 | 10pt 고정 (편집기에서 변경 불가) |
| 행간 | 1.0 ~ 3.0 |
| 자간 | -1.0 ~ 3.0px |
| 제목 스타일 | 대/중/소제목별 크기·색·굵기·밑줄 |

제목 스타일은 목차마다 개별 지정할 수도 있습니다. 지정하지 않은 항목은 공통값을 따라가므로,
나중에 공통 설정을 바꾸면 함께 바뀝니다.

### 미리보기 · PDF

표지 → 목차 → 본문 순으로 실제 인쇄 크기(Letter 216mm / A4 210mm) 그대로 그립니다.
대제목마다 새 페이지에서 시작합니다.

표지의 로고와 고정 문구는 `Admin › Common Codes` 의 `COVER` 분류에서 관리하고,
제품 사진은 문서마다 따로 올립니다.

> PDF 는 **서버에서** Chromium 으로 만들어져 글자가 벡터로 들어갑니다(확대·검색·복사 가능).
> 브라우저는 `appsettings.json` 의 `PDF:BROWSER_CHANNEL` 로 고릅니다.
> `msedge`(기본) / `chrome` 은 서버에 설치된 브라우저를 쓰고, 비우면 Playwright 전용 Chromium 을 씁니다.
> 전용 Chromium 은 빌드 후 `pwsh bin/Debug/net8.0/playwright.ps1 install chromium` 으로 한 번 설치합니다.
>
> Carlito 는 웹 글꼴(`wwwroot/assets/fonts/carlito`, SIL OFL 1.1)라 서버에 설치하지 않아도 됩니다.
> Arial 등 나머지 글꼴과 한글(맑은 고딕)은 PDF 를 만드는 서버에 설치된 글꼴을 씁니다.

### 수정 이력

편집기에서 목차를 선택하고 `이력` 버튼을 누르면 누가·언제·어떤 블록을 손댔는지 최근 100건을 봅니다.
본문 내용 자체는 보관하지 않습니다.

### 메일

`Admin › Settings` 에서 SMTP 를 설정합니다. 비밀번호는 DataProtection 으로 암호화해 저장하며 화면으로 다시 내려주지 않습니다.

발송 범위(`SYSTEM_SMTP_SCOPE`)가 `T` 이면 실제로 보내지 않고 `App_Data/mail-drop/` 에 `.eml` 파일로 떨어집니다.

---

## 보안 관련 결정

참고한 기존 사내 코드에서 의도적으로 바꾼 부분입니다.

- 관리자 우회 로그인 제거 — 아이디가 `admin` 이면 통과시키는 분기를 넣지 않았습니다
- 비밀번호는 PBKDF2 (기존 무염 SHA512 대체)
- 로그인 시도 제한 — 계정+IP 기준 15분에 5회
- 로그인 성공 시 세션 재발급 (세션 고정 방어)
- `returnUrl` 은 `IsLocalUrl` 로 검사 (오픈 리다이렉트 방어)
- 본문 HTML 은 저장할 때와 렌더 직전 두 번 정제
- 이미지 업로드는 확장자뿐 아니라 **매직 바이트**까지 확인
- 권한 검사를 컨트롤러와 저장 프로시저 양쪽에서 수행

### 운영 배포 전 확인할 것

- [ ] `05_seed_testusers.sql` 로 만든 계정 삭제 또는 비밀번호 교체
- [ ] DataProtection 키 암호화 설정 (현재 시작 시 경고 로그가 남습니다)
- [ ] 정식 인증서 적용 후 `TrustServerCertificate=True` 제거
- [ ] `SYSTEM_SMTP_SCOPE` 를 실제 발송으로 전환

---

## 폴더 구조

```
Bootstrap/          seed-admin 명령
Common/             세션 키, 역할 상수
Controllers/        Auth · Manual · Editor · Admin · Home
  Attributes/       [Auth] [AjaxAuth]
  Common/           BaseController
Data/               ApplicationDbContext (프로시저 결과 매핑 포함)
Database/           00~19 SQL 스크립트
Models/             엔티티 및 DTO
Utils/              PasswordHelper · LoginThrottle · HtmlSanitize · ImageUpload · SendMail · MailTemplates
Views/              Razor 뷰
wwwroot/
  assets/           Metronic 템플릿
  css/              app · editor · preview
  js/custom/        화면별 Vue 스크립트
```

### 알아두면 좋은 점

**저장 프로시저 결과 매핑** — 프로시저 결과는 키 없는 엔티티(`HasNoKey`)로 받습니다.
모델의 모든 속성에 해당하는 컬럼이 결과 집합에 있어야 하며, 하나라도 없으면 500 오류가 납니다.
모델에 속성을 추가했다면 대응하는 SQL 스크립트를 먼저 실행하세요.

**여러 결과 집합** — `FromSqlRaw` 는 첫 번째 결과 집합만 읽습니다. 프로시저 하나가 여러 개를 반환하도록 만들지 마세요.

**바이너리 파라미터** — `binary(8)` 같은 타입에 `DBNull.Value` 를 위치 인자로 넘기면 nvarchar 로 전달되어 변환 오류가 납니다.
`SqlParameter` 로 타입을 명시해야 합니다.
