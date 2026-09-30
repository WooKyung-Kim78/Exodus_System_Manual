# 프런트엔드

프런트엔드는 `web/`의 Vue 3 + TypeScript + Vite SPA다. 서버는 JSON API, 업로드 정적 파일, PDF 생성만 담당한다.

## 실행과 빌드

```bash
cd web
npm ci
npm run dev
npm run typecheck
npm run build
```

Node 24를 사용한다(`web/.nvmrc`). Vite는 `:5173`에서 `/api`, `/Upload`를 `https://localhost:7177`로 프록시한다. `dotnet publish`는 기본적으로 프런트 빌드도 실행하며 `-p:SkipWebBuild=true`로 생략할 수 있다.

## 구조와 API

`web/src/api`는 HTTP 클라이언트와 DTO, `pages`는 라우트 화면, `features`는 도메인 공통 기능, `stores`는 Pinia 세션 상태를 둔다. 기존 URL은 SPA 라우트로 유지한다.

모든 요청은 `api/client.ts`를 사용한다. 앱 시작 시 `/api/auth/csrf`에서 받은 토큰을 모든 비-GET 요청의 `RequestVerificationToken` 헤더에 붙인다. `/api/auth/me`는 라우터 UX 가드용이며 실제 권한은 API의 `[AjaxAuth]`와 프로시저가 결정한다. JSON 속성명은 UPPER_SNAKE를 유지한다.

## 문서와 편집기

문서 HTML은 Vue가 만들지 않는다. `DocumentHtmlBuilder`가 만든 `/api/manual/document-html`을 미리보기 iframe과 PDF가 함께 쓴다. 문서 CSS는 `wwwroot/css/doc-base.css`, `fonts.css`, `doc-type.css`, `ds-spec.css`, `preview.css`이며 크기는 `doc-type.css`의 변수만 수정한다.

`features/editor/BlockEditor.vue`는 공식 CKEditor Vue 컴포넌트와 GPL `ckeditor5`를 사용한다. 블록은 `ROW_VER` 낙관적 동시성으로 저장하고, 편집 가능 여부는 서버가 준 `CAN_EDIT`, `CAN_EDIT_SEC`만 사용한다. 새 에디터 기능은 `HtmlSanitize` 허용 목록과 함께 갱신한다.

## E2E

`/dev/styleguide`는 서버 환경이 Development일 때만 연다. SPA 라우터는 `/api/bootstrap`의 `isDevelopment` 값으로 화면 전환을 막고, 서버 SPA fallback도 Production에서 해당 직접 요청을 404로 처리한다.

`npm run e2e`는 서버를 띄우지 않는다. 먼저 `dotnet watch run --launch-profile https`와 `npm run dev`를 실행한다. `e2e/global-setup.ts`가 `/api/health`를 검사해 서버가 없으면 즉시 실행 방법을 알린다. 기본 URL은 `http://localhost:5173`이고 `E2E_BASE_URL`로 바꿀 수 있다.
