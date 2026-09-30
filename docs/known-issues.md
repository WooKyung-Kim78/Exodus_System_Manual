# 현재 이슈 (처리 대기)

**해결해야 할 항목만** 둔다. 해결하면 삭제한다. 지켜야 할 규칙은 이 파일이 아니라 `policies/`·`architecture/` 에 있다.
작업 중 새 문제를 발견했는데 그 작업 범위 밖이면 여기에 한 줄 추가하고 넘어간다.

## 백엔드 · DB

- [ ] 사용처 없는 엔티티 정리 후보: `ManualMember`, `ElementTableRow`, `Comment`, `Presence` (+ 대응 테이블/프로시저). 삭제 전 프로시저 사용처 확인
- [ ] 권한 함수 통합 테스트 확대 (`Integration/`): 역할·담당 팀·상태 조합별 (전용 테스트 DB 필요)
- [ ] 컨트롤러 HTTP 수준 테스트(`WebApplicationFactory`) 확대
- [ ] 로컬 개발 DB의 일부 매뉴얼/템플릿 이미지 참조 파일이 `wwwroot/Upload`에 없음 → PDF 생성 시 해당 이미지를 생략한다. 개발 데이터와 업로드 파일을 함께 복원한 뒤 PDF 시각 비교를 수행한다.

## 운영 전

- [ ] 로컬 `appsettings.Development.json` 에 실제 DB 자격 증명이 있음 → User Secrets 로 이전하고 자격 증명 교체 검토
- [ ] DataProtection 키 암호화 설정 (현재 시작 시 경고)
- [ ] `05_seed_testusers.sql` 계정 삭제 또는 비밀번호 교체
- [ ] `TrustServerCertificate=True` 제거 (정식 인증서 적용 후)
- [ ] `SYSTEM_SMTP_SCOPE` 를 실제 발송으로 전환
