# EXODUS 앱 디자인 시스템

SPA 관리 화면의 단일 디자인 기준은 `web/src/design-system/tokens.css`와 `web/src/styles.css`다. 기존 화면별 CSS 값이나 과거 디자인 문서는 기준으로 사용하지 않는다. 문서 미리보기·PDF CSS(`wwwroot/css/doc-*.css`)는 인쇄용 산출물이므로 이 시스템과 분리한다.

## 방향

- 라이트 모드 전용의 차분하고 밀도 높은 업무용 UI를 사용한다. 캔버스는 아주 옅은 회색, 작업 표면은 흰색, 강조는 파랑으로 한정한다.
- 글꼴은 Pretendard Variable을 우선한다. `web/index.html`의 CDN 링크가 로드되지 않는 환경에서는 `Pretendard`, `Noto Sans KR`, 시스템 sans-serif 순으로 대체한다.
- 아이콘은 Material Design Icons(MDI)만 사용한다. `AppIcon`에 이름에서 `mdi-`를 뺀 값을 전달한다. 아이콘 단독 버튼에는 반드시 `aria-label`을 둔다.
- 수치형 색·간격·모서리·그림자는 `--ex-*` 토큰만 쓴다. 화면 컴포넌트에서 새 hex 값이나 임의의 spacing 값을 만들지 않는다.

## 토큰

| 역할 | 토큰 |
|---|---|
| 앱 배경 / 표면 | `--ex-color-canvas`, `--ex-color-surface` |
| 본문 / 보조 텍스트 | `--ex-color-text`, `--ex-color-text-muted` |
| 테두리 / 입력 테두리 | `--ex-color-border`, `--ex-color-border-strong` |
| 주 행동 | `--ex-color-primary`, `--ex-color-primary-hover`, `--ex-color-primary-subtle` |
| 의미 상태 | `--ex-color-{danger,warning,success,info}` 및 `-subtle` |
| 내비게이션 | `--ex-sidebar`, `--ex-sidebar-hover`, `--ex-sidebar-text` |
| 형태 | `--ex-radius-xs`, `--ex-radius-sm`, `--ex-radius`, `--ex-radius-lg` |
| 간격 | `--ex-space-1` ~ `--ex-space-10` |
| 고도 / 접근성 | `--ex-shadow`, `--ex-shadow-lg`, `--ex-color-focus` |

## 레이아웃 규칙

- 데스크톱은 264px 고정 좌측 내비게이션, sticky 상단 헤더, 최대 1440px의 본문 작업 영역을 사용한다.
- 태블릿(960px 이하)에서는 좌측 메뉴가 슬라이드 패널로 바뀌고, 편집기·관리자 2열은 1열이 된다.
- 모바일(680px 이하)에서는 제목과 행동 영역을 세로 배치하고, 필터·폼·스타일 그리드는 1열이다. 테이블은 가로 스크롤을 허용하며 내용을 축소해 숨기지 않는다.
- 페이지는 `page-title`(제목·설명·주 행동) → `toolbar`(필터) → 표/패널 순서로 구성한다. 읽기 전용·오류는 각각 `readonly-notice`, `error`로 명시한다.
- 필터 툴바에서 checkbox는 독립 필드처럼 보이되, select·input의 하단 기준선과 맞춘다. `check-label`에 임의의 폭이나 상단 여백을 추가하지 않는다.
- 로그인 화면은 데스크톱에서 폼과 제품 소개를 2열 카드로 구성한다. `web/src/assets/login-blueprint-background.png`의 낮은 대비 기술 배경을 전체 캔버스와 소개 패널에 함께 사용하며, 모바일에서는 소개 패널을 숨겨 폼에 집중한다.

## 상태와 상호작용

- 기본 컨트롤 높이는 40px이다. primary는 생성·저장·확정, secondary는 보조·취소, danger는 삭제에만 쓴다.
- 모든 포커스 가능 요소는 3px 포커스 링을 제공한다. hover와 disabled도 기본 상태와 함께 구현한다.
- 테이블 헤더는 고정된 옅은 표면색, 행 hover는 아주 옅은 파란색을 사용한다. 상태는 `AppBadge`로 표현한다.
- 행 내부의 연속된 작은 작업 버튼(`.inline`) 사이에는 `--ex-space-2`보다 작은 일정한 간격을 둔다. 버튼을 붙이거나 음수 여백으로 겹치지 않는다.
- 데이터가 없을 때는 `EmptyState`, 비동기 로딩에는 `Skeleton` 또는 명확한 로딩 문구를 사용한다.
