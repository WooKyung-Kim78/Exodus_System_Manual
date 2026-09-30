# 현재 이슈 (처리 대기)

**해결해야 할 항목만** 둔다. 해결하면 삭제한다. 지켜야 할 규칙은 이 파일이 아니라 `policies/`·`architecture/` 에 있다.
작업 중 새 문제를 발견했는데 그 작업 범위 밖이면 여기에 한 줄 추가하고 넘어간다.

## 프런트엔드 (개편 예정 — 개편 때 함께 처리, 지금은 손대지 않음)

- [ ] `STATUS_LABEL` / `statusLabel()` 이 `index.js`, `detail.js`, `editor.js` 에 각각 정의됨 → `js/common/`
- [ ] 세션 키 리터럴(`"ROLE"`, `"FULL_NAME"` 등)이 `_LayoutMain.cshtml`, `Home/Index.cshtml` 에 남아 있음
- [ ] `wwwroot/assets/js/common/ajaxSetting.js` 는 레이아웃이 로드하지 않는 중복 파일로 보임 → 확인 후 정리
- [ ] `wwwroot/lib/*`, `Views/Shared/_ValidationScriptsPartial.cshtml` (기본 템플릿 산출물) 사용처 없어 보임 → 확인 후 삭제
- [ ] `docs/design-system/font-size.md` 표 값이 `doc-type.css` 와 다름 (문서 12pt 표, 사양표 11pt 등) → 디자인 시스템 문서 개편 때 코드 기준으로 재작성

## 백엔드 · DB

- [ ] 사용처 없는 엔티티 정리 후보: `ManualMember`, `ElementTableRow`, `Comment`, `Presence` (+ 대응 테이블/프로시저). 삭제 전 프로시저 사용처 확인
- [ ] 테스트 미작성 대상: `DatasheetSpec.BuildHtml`, `PdfTocMarks.Read`, `HeadingStyle.ParseStyles`
- [ ] 권한 함수 통합 테스트 확대 (`Integration/`): 역할·담당 팀·상태 조합별 (전용 테스트 DB 필요)
- [ ] 컨트롤러 HTTP 수준 테스트(`WebApplicationFactory`)와 Playwright e2e 도입 (프런트 개편 후)

## 운영 전

- [ ] 로컬 `appsettings.Development.json` 에 실제 DB 자격 증명이 있음 → User Secrets 로 이전하고 자격 증명 교체 검토
- [ ] DataProtection 키 암호화 설정 (현재 시작 시 경고)
- [ ] `05_seed_testusers.sql` 계정 삭제 또는 비밀번호 교체
- [ ] `TrustServerCertificate=True` 제거 (정식 인증서 적용 후)
- [ ] `SYSTEM_SMTP_SCOPE` 를 실제 발송으로 전환
