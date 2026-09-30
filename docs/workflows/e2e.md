# E2E 실행

Playwright는 개발 서버를 띄우지 않는다. 전용 개발/테스트 DB를 사용하는 서버와 Vite를 먼저 실행한다.

```bash
dotnet watch run --launch-profile https

# 다른 터미널
cd web
npm run dev
npm run e2e
```

`global-setup.ts`는 `http://localhost:5173/api/health`를 3초 안에 확인한다. 다른 주소는 `E2E_BASE_URL`로 지정한다.

```bash
E2E_BASE_URL=http://localhost:5173 npm run e2e
```

Development 자동 로그인은 loopback 요청과 `Dev:AutoLoginUserId` 로컬 설정에서만 동작한다. 역할 전환이 필요하면 `X-Dev-User` 헤더를 사용한다. 기본 스모크 테스트는 `E2E_DEV_USER` 또는 `admin`을 보낸다. 로그인 자체를 검증하는 테스트에서는 `X-Dev-User: none`으로 자동 로그인을 끈다.

E2E가 문서를 만들면 `E2E-<timestamp>` 접두사를 쓰고 테스트가 끝날 때 삭제한다. 운영·공유 DB에는 E2E 쓰기 테스트를 실행하지 않는다.

PDF 회귀 테스트의 골든 PNG는 `web/e2e/__golden__/`에 둔다. 대표 A4/Letter 문서, 사양 목차, 이미지와 표를 포함해야 하며, 변경 사유와 함께만 갱신한다.
