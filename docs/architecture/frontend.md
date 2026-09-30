# 프런트엔드

서버 렌더 Razor + **화면당 Vue 2 인스턴스 1개**(빌드 도구 없음, 전역 스크립트). 번들러·ESM 은 CKEditor 로더 하나만 예외다.

## 화면 구성 규칙

- 화면 1개 = `Views/<영역>/<화면>.cshtml` + `wwwroot/js/custom/<영역>/<화면>.js`. 루트는 `<div id="app" v-cloak>`, JS 는 `new Vue({ el:'#app', ... })`.
- 스크립트는 뷰의 `@section scripts { ... }` 에서 `asp-append-version="true"` 로 로드한다 (캐시 무효화).
- 서버 값을 JS 로 넘길 때는 `window.XXX = @Json.Serialize(...)` 한 줄 (예: `HEADING_DEFAULTS` ← `HeadingStyle.ClientDefaults()`). **기본값을 JS 에 다시 하드코딩하지 않는다.**
- **Razor 에서 `@` 는 `@@` 로 이스케이프**: `@@click`, `@@change`. Vue 문법 `:prop`, `v-*`, `{{ }}` 는 그대로.

## 스크립트 로딩 (`_LayoutMain.cshtml`)

`vue.2.7.14.min` → `plugins.bundle`(jQuery, Bootstrap) → `scripts.bundle` → datatables → jquery-toast → `constants`/`jsUtils` → `js/common/ajaxSetting` → `js/common/shell` → 화면 스크립트.

- `js/common/ajaxSetting.js`: 모든 비-GET 요청에 Antiforgery 헤더 자동 부착, 401 → 로그인, 403 → 오류 페이지. **직접 토큰을 붙이는 코드를 화면 JS 에 쓰지 않는다.**
- 공통 함수(전역): `getErrorMessage(xhr)`, `toastOk()`, `toastError()`. 알림/오류 표시는 이것만 쓴다.
- `assets/js/common/*` (Metronic 기반 `jsUtils`, `vueMixins`, `vueComponents`) 는 벤더 성격 — 새 공통 코드는 `wwwroot/js/common/` 에 둔다.

## AJAX 패턴 (기존 코드와 동일하게)

```js
$.get('/manual/list', params)
  .done(function (res) { self.list = res.data.list; })
  .fail(function (xhr) { toastError(getErrorMessage(xhr)); })
  .always(function () { self.loading = false; });
```
- 응답은 `{success, data}` — 값은 항상 `res.data.*`. 저장 후 토스트는 `toastOk()`.
- 문법: 화면 스크립트는 **ES5 스타일**(`var`, `function`, `self = this`) 이 주류다. 파일 안에서 스타일을 섞지 않고, 새 파일도 주변 화면과 맞춘다.
- 모달은 `this._modals` 캐시 + `new bootstrap.Modal(el)` 패턴 (`index.js` 의 `modal(id)`).
- 서버 JSON 필드는 UPPER_SNAKE 그대로 (`item.MODEL_NAME`).
- 공통 상수·함수(상태 라벨 등)는 화면 JS 마다 복사하지 않고 `js/common/` 에 둔다. (프런트는 개편 예정 — 기존 중복을 지금 정리하지 않는다.)

## 본문 편집기 (CKEditor 5)

- ESM 빌드를 import map 으로 로드 (`Views/Editor/Index.cshtml` 하단) → `ckeditor-factory.js`(type=module) 가 인스턴스 생성을 담당. 편집기 설정 변경은 여기서만.
- 허용 태그/속성/CSS 는 `HtmlSanitize` 화이트리스트와 **반드시 일치**해야 한다. CKEditor 에 기능(예: 새 서식)을 추가하면 서버 화이트리스트에도 추가하지 않으면 저장 시 조용히 지워진다.
- 저장은 블록 단위 + `ROW_VER` 낙관적 동시성. 409 를 받으면 재시도하지 말고 사용자에게 새로고침을 안내한다.

## CSS

- 문서(미리보기/PDF/편집기) 시각 요소: `doc-type.css`(크기 토큰), `preview.css`, `ds-spec.css`(사양표), `editor.css`, `fonts.css`. 앱 껍데기: `theme.css`(1000+ 줄), `app.css`, `site.css`.
- **글자 크기는 `doc-type.css` 의 CSS 변수만 수정**한다. 다른 CSS 에 pt 값을 새로 박지 않는다 → [document-rendering.md](document-rendering.md).
- `wwwroot/assets/**`, `wwwroot/lib/**` 는 벤더 코드 — 수정하지 않는다 (덮어써질 수 있음).
