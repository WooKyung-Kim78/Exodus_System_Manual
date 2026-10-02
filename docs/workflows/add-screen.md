# 화면 추가 체크리스트

1. 라우트의 최상위 도메인에 맞는 `web/src/pages/` 하위 폴더에 Vue 3 `<script setup>` 화면을 만든다. 한 라우트 전용 하위 컴포넌트가 둘 이상이면 해당 라우트 이름으로 한 단계 더 묶고, 화면 간 공통 기능만 `features/`에 둔다.
2. `router.ts`에 기존 URL을 유지하는 라우트를 추가하고, 역할 가드는 UX 용도로만 둔다.
3. API는 `web/src/api/client.ts`와 DTO를 통해 호출한다. CSRF·401·403 처리를 화면에 복사하지 않는다.
4. 공통 UI는 `components/` 또는 `design-system/`으로 올려 중복을 만들지 않는다.
5. 문서 모양이 바뀌면 미리보기 iframe과 PDF 둘 다 확인한다.
6. `npm run format && npm run typecheck && npm run build` 및 해당 E2E를 실행한다.
