# 앱 공통 컴포넌트

공통 UI는 `web/src/design-system/`에 둔다. 화면에서 같은 구조를 복사하지 않고 이 컴포넌트를 우선 사용한다.

| 컴포넌트 | 용도 |
|---|---|
| `AppButton` | primary, secondary, danger, ghost 버튼과 focus·disabled 상태 |
| `AppInput` | 문자열 `v-model` 입력과 공통 focus 스타일 |
| `AppBadge` | 문서 상태 배지. 라벨 원본은 `web/src/features/manual/status.ts` |
| `EmptyState` | 빈 목록·검색 결과 안내 |
| `Skeleton` | 데이터 로딩 자리 표시 |

`/dev/styleguide`는 Development 환경에서만 위 컴포넌트와 토큰 상태를 확인하는 화면이다. 모달·드로어·탭·툴팁은 Reka UI 기반으로 추가할 때 동일 문서에 함께 기록한다.
