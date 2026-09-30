# docs 색인

에이전트용 작업 문서. 코드에서 알 수 없는 **의도·제약·함정**만 적는다. 코드를 읽으면 아는 내용은 적지 않는다.

| 폴더/파일 | 내용 |
|---|---|
| [architecture/backend.md](architecture/backend.md) | 요청 흐름, BaseController 계약, 응답 규약, DI |
| [architecture/api-routes.md](architecture/api-routes.md) | SPA와 JSON API 경로표 |
| [architecture/database.md](architecture/database.md) | 프로시저 호출·매핑 규칙, SQL 스크립트 버전 관리, 함정 |
| [architecture/permissions.md](architecture/permissions.md) | 인증·역할·문서/목차 편집 권한 판정 경로 |
| [architecture/frontend.md](architecture/frontend.md) | Vue SPA 구조, API 클라이언트, Vite·E2E 규칙 |
| [architecture/document-rendering.md](architecture/document-rendering.md) | 미리보기·PDF 파이프라인, 스타일 상속, datasheet 사양 |
| [policies/coding-standards.md](policies/coding-standards.md) | 일관성·DRY·명명·주석 정책 |
| [policies/security.md](policies/security.md) | 지켜야 할 보안 결정과 금지 사항 |
| [workflows/add-endpoint.md](workflows/add-endpoint.md) | API 추가 체크리스트 |
| [workflows/change-database.md](workflows/change-database.md) | 스키마/프로시저 변경 체크리스트 |
| [workflows/add-screen.md](workflows/add-screen.md) | 화면 추가 체크리스트 |
| [workflows/testing.md](workflows/testing.md) | 백엔드 테스트 정책·실행·작성 규칙 |
| [workflows/verification.md](workflows/verification.md) | 테스트로 커버되지 않는 부분(화면·PDF)의 수동 검증 |
| [known-issues.md](known-issues.md) | 현재 이슈 (처리 대기 항목만, 해결하면 삭제) |
| [design-system/](design-system/tokens.md) | 앱 토큰·공통 컴포넌트·문서 글자 크기 정의 |

문서를 고칠 때: 코드 변경으로 문서가 틀려졌다면 **같은 변경에서 함께 고친다.**
