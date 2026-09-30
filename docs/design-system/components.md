# 앱 공통 컴포넌트

공통 UI는 `web/src/design-system/`에 둔다. 화면마다 버튼, 상태 배지, 다이얼로그 또는 아이콘의 동작을 다시 구현하지 않는다.

| 컴포넌트 | 용도 |
|---|---|
| `AppIcon` | MDI 아이콘. `name="file-document-outline"`처럼 접두사 없이 전달 |
| `AppButton` | primary, secondary, danger, ghost 버튼 |
| `AppInput` | 공통 입력과 포커스 상태 |
| `AppBadge` | 문서 상태 배지. 상태 라벨은 `features/manual/status.ts`가 원본 |
| `AppTable` | 스크롤 가능한 테이블 컨테이너와 footer 슬롯 |
| `EmptyState` / `Skeleton` | 빈 결과와 로딩 자리 표시 |
| `AppDialog` / `ConfirmDialog` | 접근 가능한 모달과 확인 동작 |
| `AppDrawer` | 화면 보조 작업 패널 |
| `AppTabs` / `AppTooltip` / `AppToast` | 탭, 짧은 설명, 일시적 피드백 |

`/dev/styleguide`는 Development 환경에서 토큰, 공통 컴포넌트, 오버레이 동작을 확인하는 화면이다. E2E는 탭·Drawer·Toast 같은 상호작용을 검증하며, 로컬 스크린샷은 저장소에 커밋하지 않는다.
