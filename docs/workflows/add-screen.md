# 화면 추가 체크리스트

1. **컨트롤러 액션** — `[Auth]` + 접근 확인 후 `View()` (예: `ManualController.Detail`). `ViewData["MID"]` 처럼 필요한 최소 값만 전달.
2. **뷰** `Views/<영역>/<화면>.cshtml` — `ViewData["Title"]`, `<div id="app" v-cloak>`, Vue 바인딩의 `@` 는 `@@`. 레이아웃은 `_LayoutMain`(기본, `_ViewStart` 참고).
3. **스크립트** `wwwroot/js/custom/<영역>/<화면>.js` — `new Vue({ el:'#app' ... })`, 데이터 로딩은 `mounted` 에서 `callXxx()`. `@section scripts` 에서 `asp-append-version="true"` 로 로드.
4. **네비게이션** — 사이드바 항목은 `_LayoutMain.cshtml` (`path` 비교로 active 처리).
5. **상태/라벨/포맷** — 이미 있는 공통 것 재사용. 없으면 `js/common/` 에 추가하고 기존 중복도 여기로 모은다.
6. **문서 모양이 바뀌면** — 미리보기·PDF 영향 확인: [document-rendering.md](../architecture/document-rendering.md).
7. Vue 마운트 실패 시 `v-cloak` 때문에 백지가 되는 것을 `ajaxSetting.js` 가 3초 뒤 풀어주며 콘솔에 오류를 남긴다 → 백지면 콘솔부터 본다.

`.cshtml` 은 런타임 컴파일이라 새로고침으로 반영, `.cs` 는 재시작.
