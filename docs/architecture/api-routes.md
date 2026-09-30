# API 경로

SPA 화면 경로와 JSON API 경로를 분리한다. 화면의 직접 GET은 wwwroot/app/index.html로 fallback되며, 데이터 요청은 반드시 /api 아래로 보낸다.

| 영역 | 경로 | 메서드 | 용도 |
|---|---|---|---|
| 공통 | /api/health | GET | 상태 확인 |
| 공통 | /api/bootstrap | GET | 제목 기본값·본문 글꼴 등 서버 원본 값 |
| 인증 | /api/auth/csrf | GET | Antiforgery 토큰 발급 |
| 인증 | /api/auth/me | GET | 현재 세션 사용자 |
| 인증 | /api/auth/login, /api/auth/logout | POST | 로그인·로그아웃 |
| 문서 | /api/manual/list, /api/manual/find, /api/manual/datasheets, /api/manual/spec | GET | 목록·상세·datasheet |
| 문서 | /api/manual/create, /api/manual/header, /api/manual/notify, /api/manual/cover | POST | 생성·헤더·작성 요청·표지 |
| 문서 | /api/manual/delete, /api/manual/cover | DELETE | 문서·표지 삭제 |
| 문서 | /api/manual/document-html, /api/manual/pdf | GET | iframe 미리보기 HTML·PDF |
| 편집기 | /api/editor/data, /api/editor/sections, /api/editor/section/history, /api/editor/template-options | GET | 문서·목차·이력 조회 |
| 편집기 | /api/editor/section, /api/editor/template-section, /api/editor/section/order | POST | 목차 관리 |
| 편집기 | /api/editor/block, /api/editor/block/order, /api/editor/image, /api/editor/heading-style | POST | 블록·이미지·문서 스타일 저장 |
| 편집기 | /api/editor/section, /api/editor/block | DELETE | 목차·블록 삭제 |
| 관리 | /api/admin/setting/mail, /api/admin/setting/mail/log | GET | 메일 설정·발송 이력 |
| 관리 | /api/admin/section-template/list, /api/admin/user/list, /api/admin/code/list | GET | 관리 목록 |
| 관리 | /api/admin/setting/mail, /api/admin/setting/mail/test, /api/admin/section-template, /api/admin/section-template/order, /api/admin/section-template/image, /api/admin/user, /api/admin/user/password, /api/admin/user/authorized, /api/admin/user/restore, /api/admin/code, /api/admin/code/logo | POST | 관리 저장·업로드 |
| 관리 | /api/admin/section-template, /api/admin/user, /api/admin/code | DELETE | 관리 삭제 |

모든 쓰기 요청은 RequestVerificationToken 헤더를 포함한다. 문서 관련 쓰기 API는 서버에서 DenyIfNotEditable과 프로시저 권한 검사를 모두 거친다.
