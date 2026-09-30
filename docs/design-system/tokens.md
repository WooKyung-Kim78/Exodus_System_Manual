# 앱 디자인 토큰

SPA UI 토큰의 원본은 `web/src/design-system/tokens.css`다. 앱 껍데기와 문서(PDF·미리보기)의 스타일은 서로 분리하며, 문서 글꼴 크기는 계속 `wwwroot/css/doc-type.css`에서만 관리한다.

## 원칙

- 색상, 간격, 반경, 포커스 색상은 `--ex-*` CSS 변수만 사용한다.
- 라이트 테마만 지원한다. 다크 모드 변수나 `prefers-color-scheme` 분기는 추가하지 않는다.
- 새 컴포넌트는 기본 상태, keyboard focus, disabled 상태를 함께 제공한다.

## 주요 토큰

| 범주 | 토큰 |
|---|---|
| 색상 | `--ex-color-primary`, `--ex-color-danger`, `--ex-color-surface`, `--ex-color-text`, `--ex-color-border` |
| 상태 | `--ex-color-{warning,success,info,danger}-subtle` |
| 간격 | `--ex-space-1` ~ `--ex-space-8` |
| 형태 | `--ex-radius-sm`, `--ex-radius`, `--ex-shadow` |
| 접근성 | `--ex-color-focus` |
