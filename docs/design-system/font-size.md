# 매뉴얼 글자 크기 정리

매뉴얼 문서(미리보기 · PDF · 편집기)의 글자 크기가 **어디서 정해지고, 무엇을 고치면 바뀌는지** 정리한 문서입니다.

---

## 1. 한눈에 보기

| 구분 | 요소 | 현재 값 | 정하는 곳 |
|---|---|---|---|
| 제목 | 대제목 (1단계) | 13pt | `HeadingStyle.Defaults()` → 문서별 `HEADING_STYLE_JSON` → 목차별 `STYLE_JSON` |
| 제목 | 중제목 (2단계) | 13pt | 〃 |
| 제목 | 소제목 (3단계) | 13pt | 〃 |
| 본문 | 텍스트 블록 | 12pt | `TB_S_MANUAL.BODY_FONT_SIZE` (없으면 `--doc-font-size`) |
| 본문 | 표 (CKEditor 표 · 표 블록) | 10pt | `--doc-size-table` |
| 본문 | 이미지 캡션 | 10pt | `--doc-size-small` |
| 표지 | 제목 문구 | 14pt | `--doc-size-cover` |
| 표지 | 문서번호 · Rev · 날짜 | 10pt | `--doc-size-small` |
| 목차 | "Table of Contents" | 12pt | `--doc-size-toc-title` |
| 목차 | 목차 줄 | 본문과 같음 (12pt) | `--doc-font-size` 상속 |
| 사양표 | category 이름 | 10pt | `--ds-size-category` |
| 사양표 | category 옆 머리말 · 표 아래 꼬리말 | 9pt | `--ds-size-note` |
| 사양표 | 표 머리글 | 10pt | `--ds-size-thead` |
| 사양표 | 표 본문 | 10pt | `--ds-size-body` |
| 사양표 | 위첨자 · 아래첨자 | 75% | `ds-spec.css` |
| PDF | 꼬리말 "1 \| Page - Ver. 1.0" | 9pt | `ManualController.BuildPdfFooter()` |

> 사양표(SPECIFICATIONS)는 처음에 exodus_datasheet 원본(px)에 0.8을 곱한 값(8.4 / 8 / 8 / 7.2pt)으로 맞췄다가,
> 본문과 같은 10pt 기준으로 키운 값입니다.

---

## 2. 크기를 바꾸는 방법

### 2-1. 고정 크기 (본문 표 · 캡션 · 표지 · 목차 · 사양표)

**[wwwroot/css/doc-type.css](../../wwwroot/css/doc-type.css) 한 파일만 고칩니다.**

```css
:root {
    --doc-font-size: 12pt;       /* 본문 기본값 (DB 값이 없을 때) */
    --doc-size-table: 10pt;
    --doc-size-small: 10pt;
    --doc-size-cover: 14pt;
    --doc-size-toc-title: 12pt;

    --ds-size-body: 10pt;
    --ds-size-thead: 10pt;
    --ds-size-category: 10pt;
    --ds-size-note: 9pt;
}
```

미리보기 · PDF · 편집기 · 문서 정보 화면이 모두 이 파일을 읽습니다.
(`_LayoutMain.cshtml`, `Views/Manual/Pdf.cshtml` 에서 링크)

### 2-2. 본문 크기

본문은 문서마다 `TB_S_MANUAL.BODY_FONT_SIZE` 값을 씁니다. 화면에서는 바꿀 수 없고 **DB 에서 12 로 고정**합니다. (`Database/30_body_font_size_12.sql`)

바꾸려면 새 SQL 스크립트에서 아래 세 가지를 함께 고칩니다.

1. 기본값 제약 `DF_TB_S_MANUAL_BODY_FONT_SIZE` (현재 12)
2. `USP_S_UPDATE_DOC_STYLE` 의 `BODY_FONT_SIZE = 12`
3. 기존 문서 `UPDATE dbo.TB_S_MANUAL SET BODY_FONT_SIZE = <값>`

흐름:

```
TB_S_MANUAL.BODY_FONT_SIZE
 ├─ 미리보기·PDF : PreviewViewModel.BodyFontSize → _DocSheet.cshtml 의 --doc-font-size
 ├─ 편집기       : editor.js bodyFontSize → applyBodyStyle() 가 :root 에 --doc-font-size 설정
 └─ 문서 정보    : detail.js bodyFontSize → 스타일 미리보기(bodyCss)
```

> 문서마다 다르게 하고 싶다면 문서 정보 화면에 입력칸을 만들고 `USP_S_UPDATE_DOC_STYLE` 이 값을 받게 하면 됩니다.
> 나머지 경로는 이미 이 값을 읽고 있습니다.

### 2-3. 제목 크기

| 범위 | 방법 |
|---|---|
| 모든 새 문서의 기본값 | [Models/PreviewModels.cs](../../Models/PreviewModels.cs) `HeadingStyle.Defaults()` |
| 한 문서 전체 | 문서 정보 › 문서 스타일 (→ `TB_S_MANUAL.HEADING_STYLE_JSON`) |
| 목차 하나 | 편집기 › 목차 수정 › 개별 스타일 (→ `TB_S_SECTION.STYLE_JSON`) |

- 적용 순서: `Defaults()` ← `HEADING_STYLE_JSON` ← `STYLE_JSON` (뒤가 앞을 덮어씀)
- 목차 설정의 "밑줄" 스위치(`TITLE_UNDERLINE`)는 크기와 별개로 밑줄만 켭니다.
- 화면(JS)은 기본값을 따로 갖지 않고, 페이지를 그릴 때 서버가 넣어 준 `window.HEADING_DEFAULTS` 를 씁니다.
  (`HeadingStyle.ClientDefaults()` → `Views/Manual/Detail.cshtml`, `Views/Editor/Index.cshtml`)

### 2-4. PDF 꼬리말

[Controllers/ManualController.cs](../../Controllers/ManualController.cs) `BuildPdfFooter()` 의 `font-size:9pt`.
브라우저의 쪽 번호 템플릿은 페이지의 CSS 를 읽지 못해 C# 안에 직접 적혀 있습니다.

---

## 3. 적용 규칙 (고칠 때 주의)

### 3-1. 본문은 인라인 서식을 무시한다

과거에 저장된 글자 크기(CKEditor 인라인 `font-size`)가 섞여 있어도 문서 전체가 같은 크기로 나오도록 `!important` 로 덮어씁니다.

```css
/* preview.css */
.doc-block, .doc-block *                 { font-size: var(--doc-font-size) !important; }   /* 0,1,0 */
.doc-block table, .doc-block table *     { font-size: var(--doc-size-table) !important; }  /* 0,1,1 */
.doc-block .block-caption                { font-size: var(--doc-size-small) !important; }  /* 0,2,0 */

/* editor.css — 편집기도 같은 규칙 */
.block-body .ck-editor__editable *       { font-size: var(--doc-font-size) !important; }
.block-body .ck-editor__editable table * { font-size: var(--doc-size-table) !important; }
```

본문 블록 안에 새 요소의 크기를 따로 주려면, **위 규칙보다 구체적인 선택자 + `!important`** 가 필요합니다.
그렇지 않으면 `.doc-block *` 에 덮여 10pt 로 나옵니다.

### 3-2. 사양표는 본문 규칙을 이겨야 한다

사양표(`.ds-spec-block`)도 본문 블록 안에 있으므로 [ds-spec.css](../../wwwroot/css/ds-spec.css) 는 다음처럼 작성되어 있습니다.

- 모든 자식: `.doc-block .ds-spec-block * { font-size: inherit !important }` — 본문 10pt 대신 부모 크기를 물려받게 함
- 각 부분: `.ds-spec-block .ds-spec-cat` / `.ds-spec-table > thead` / `> tbody` / `.ds-spec-foot` 에 `--ds-size-*` 지정
- 위첨자 · 아래첨자: `75% !important` (inherit 규칙보다 구체적으로)

### 3-3. 목차 쪽 번호 표식

`.toc-mark` 의 `2px` 는 PDF 1차 생성 때 쪽 번호를 찾기 위한 **보이지 않는 표식**입니다. 글자 크기 정리 대상이 아닙니다.

### 3-4. 편집 화면 전용 크기

`editor.css` 의 `.heading-preview-1/2/3` (rem 단위) 등은 편집 화면 UI 용이며 문서 결과(미리보기 · PDF)와는 관계없습니다.

---

## 4. 관련 파일

| 파일 | 내용 |
|---|---|
| [wwwroot/css/doc-type.css](../../wwwroot/css/doc-type.css) | **크기 기준값 (CSS 변수)** |
| [wwwroot/css/preview.css](../../wwwroot/css/preview.css) | 미리보기 · PDF 문서 스타일 (본문 · 표지 · 목차 · 표 · 캡션) |
| [wwwroot/css/editor.css](../../wwwroot/css/editor.css) | 편집기 CKEditor 본문 |
| [wwwroot/css/ds-spec.css](../../wwwroot/css/ds-spec.css) | SPECIFICATIONS 사양표 |
| [Models/PreviewModels.cs](../../Models/PreviewModels.cs) | `HeadingStyle.Defaults()`, `ClientDefaults()`, `PreviewViewModel.BodyFontSize` |
| [Views/Manual/_DocSheet.cshtml](../../Views/Manual/_DocSheet.cshtml) | `--doc-font-size` 등 문서별 값을 CSS 변수로 전달 |
| [wwwroot/js/custom/manual/editor.js](../../wwwroot/js/custom/manual/editor.js) | `applyBodyStyle()` — 편집기에 `--doc-font-size` 설정 |
| [wwwroot/js/custom/manual/detail.js](../../wwwroot/js/custom/manual/detail.js) | 문서 스타일 미리보기 (`bodyCss`, `headingCss`) |
| [Controllers/ManualController.cs](../../Controllers/ManualController.cs) | PDF 꼬리말 `BuildPdfFooter()` |
| `Database/24_body_font_default.sql`, `Database/28_font_carlito.sql` | `BODY_FONT_SIZE` 기본값 · 고정값 |
