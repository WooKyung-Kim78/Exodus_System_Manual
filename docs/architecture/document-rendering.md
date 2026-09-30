# 문서 렌더링 (미리보기 · PDF · 스타일)

## 파이프라인

```
ManualController.BuildPreviewModel(mid) ─▶ PreviewViewModel  (헤더+목차+블록+스타일 병합)
   └─ DocumentHtmlBuilder.Build() : 완전한 문서 HTML 문자열
       ├─ GET /api/manual/document-html : Vue 미리보기 iframe
       └─ PdfRenderer(Playwright Chromium) : 벡터 PDF
```

- 미리보기와 PDF 는 **`DocumentHtmlBuilder`가 만든 같은 HTML 문자열**을 사용한다. 동적 헤더·목차·본문 값은 빌더에서 HTML 인코딩하고, 본문·사양 HTML은 기존처럼 `HtmlSanitize.Clean`을 거쳐 넣는다. Preview/PDF 각각에 조건 분기를 넣지 않는다.
- `preview.css` 의 `@page` 여백과 `ManualController.RenderPdfAsync` 의 Playwright 여백 옵션은 **같아야 한다** (코드 주석 참고). 한쪽만 바꾸면 미리보기와 PDF 의 쪽 나눔이 달라진다.
- 페이지 크기: Letter(기본) / A4 — `TB_S_MANUAL.PAGE_SIZE`.

## PDF 목차 쪽 번호 (2-pass)

1차 렌더에서 `EmitTocMarks=true` 로 제목 위치에 표식을 찍고 → `PdfTocMarks.Read`(PdfPig)로 쪽 번호를 읽어 → `TocPages` 를 채워 2차 렌더. **목차 폭이 고정이라 1·2차의 쪽 배치가 같다는 전제**다. 목차 줄 높이/개수가 쪽 번호 채움 전후로 달라지는 변경(줄바꿈 가능 요소 추가 등)은 이 전제를 깬다.

## PdfRenderer 제약

- 문서 HTML 과 `wwwroot` 정적 파일만 가상 origin(`http://pdf.local`)으로 제공하고 **그 외 네트워크 요청은 전부 abort**. PDF 에 외부 URL 리소스(CDN 글꼴, 외부 이미지)를 쓰면 안 나온다. 새 리소스는 `wwwroot` 에 두고 상대 경로로.
- 이미지 등 업로드 파일도 `wwwroot/Upload/` 아래여야 렌더된다.
- 브라우저: `PDF:BROWSER_CHANNEL`(`msedge` 기본). 비우면 Playwright 전용 Chromium (`playwright.ps1 install chromium` 필요).
- 글꼴: Carlito와 Poppins 웹 글꼴을 `wwwroot/assets/fonts/`에 동봉한다. Arial·맑은 고딕 등은 PDF를 만드는 **서버 설치 글꼴**에 의존 → 개발 PC와 서버의 PDF가 다를 수 있다.
- 동시 렌더 2개 제한 (`MaxParallelPages`). 한 요청이 PDF 를 2번 렌더하므로 오래 걸릴 수 있다.

## 스타일이 정해지는 순서

| 대상 | 우선순위 (뒤가 앞을 덮어씀) |
|---|---|
| 제목 크기·색·굵기·밑줄 | `HeadingStyle.Defaults()` → `TB_S_MANUAL.HEADING_STYLE_JSON`(문서) → `TB_S_SECTION.STYLE_JSON`(목차, 값이 있는 항목만) |
| 제목 정렬/밑줄 | 목차 자체 컬럼 `TITLE_ALIGN` / `TITLE_UNDERLINE` (STYLE_JSON 과 별개) |
| 본문 글꼴/크기/행간/자간 | `doc-type.css` → `TB_S_MANUAL.BODY_FONT / BODY_FONT_SIZE / BODY_LINE_HEIGHT / BODY_LETTER_SPACING` |

- 본문 글자 크기는 화면에서 바꿀 수 없고 **DB 로 12 고정**(`30_body_font_size_12.sql`). 사용자 기능으로 열지 않는다.
- 제목 기본값은 **C# 이 원본**(`HeadingStyle.Defaults`), JS 는 `ClientDefaults()` 로 받는다. 새 기본값을 JS 에 복제하지 않는다.
- 본문 글꼴 목록은 `BodyFonts` (`Models/PreviewModels.cs`) 가 원본 — 글꼴 추가 시 `BodyFonts.Stacks`, `fonts.css`, (웹 글꼴이면) 폰트 파일, 필요하면 DB 스크립트를 함께 손본다.
- 크기 변경 상세와 현재 값은 [../design-system/font-size.md](../design-system/font-size.md). 코드 기준값은 `doc-type.css` 다.

## SPECIFICATIONS 사양 (datasheet 연동)

- 제목에 `SPECIFICATION` 이 들어간 목차(`DatasheetSpec.IsSpecSection`)에만 사양을 그린다. **미리보기·편집기·PDF 가 같은 판정 함수**를 써야 한다.
- 문서에 `PROCESS_ID` 를 저장해 두고(없는 옛 문서는 `JOB_NUMBER` 로 재탐색) **저장 없이 볼 때마다 외부 DB 에서 읽어** HTML 을 만든다. 결과 HTML 은 `HtmlSanitize.Clean` 을 통과시킨다.
- 생성 블록은 `ds-spec-block` 표식 클래스로 식별. datasheet 목록·사양 조회 API 는 DB 장애 시 503 + 안내 메시지로 응답한다 (`try/catch` + 로그).
- 핀 배치 카테고리 목록(`PinCategories`)은 datasheet 프로젝트의 `constants.js` 와 동일해야 한다.
