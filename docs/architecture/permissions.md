# 인증·권한

권한은 **3단 방어**이며 실제 차단은 마지막(프로시저)이다.

| 단계 | 위치 | 역할 |
|---|---|---|
| 1. 로그인/역할 | `[Auth]` / `[AjaxAuth("ADMIN, SUPPORTER")]` | 세션 `IS_LOGIN`, `ROLE` 확인. 페이지는 리다이렉트, AJAX 는 401/403 |
| 2. 문서 단위 | `GetManualAccess(mid)` → `CAN_READ` / `CAN_EDIT` | `USP_S_SELECT_MANUAL_ACCESS` 가 판정 |
| 3. 목차/블록 단위 | 쓰기 프로시저 내부 `UFN_S_CAN_EDIT_SECTION` | 목차 담당 팀이 아니면 프로시저가 `Success=0` 반환 |

## 역할 ([Common/SessionKeys.cs](../../Common/SessionKeys.cs))

`ADMIN` · `SUPPORTER` · `USER` · `READER`.
- 관리 화면: `ADMIN, SUPPORTER` 는 코드/설정/템플릿 일부, 사용자·역할 관리는 `ADMIN` 만 — 컨트롤러 `[Auth]` 인자로 구분돼 있다. 기존 액션의 지정을 기준으로 삼는다.
- 역할은 로그인 시 세션에 **복사**된다. 역할을 바꿔도 대상 사용자가 다시 로그인해야 반영된다.
- 사용자는 문자열 세션 키를 `SessionKeys` 상수로만 접근한다. 문자열 리터럴(`GetString("ROLE")`)은 `_LayoutMain.cshtml`, `Home/Index.cshtml`, `ManualController.CurrentUserName` 에 남아 있다 — 새로 늘리지 않는다.

## 문서 접근 규칙 (DB 함수가 원본)

```
읽기 (UFN_S_CAN_READ_MANUAL)  ADMIN/SUPPORTER/READER 역할 | 문서 생성자 | 목차 담당 팀 소속
편집 (CAN_EDIT)               DRAFT 상태 AND 참여자(UFN_S_IS_MANUAL_PARTICIPANT: ADMIN | 생성자 | 담당 팀)
목차 편집 (UFN_S_CAN_EDIT_SECTION)  DRAFT AND ADMIN | 생성자 | (참여자 AND (담당 팀 없음 OR 내 팀 == 담당 팀))
```

- **참여자 테이블은 없다.** 목차에 `ASSIGNED_TEAM` 을 지정하는 것이 곧 참여 범위. 팀은 `TB_S_USER.TEAM` 문자열 일치로 판정.
- 상태가 `DRAFT` 가 아니면 누구도 수정할 수 없다 (ADMIN 포함).
- READER/SUPPORTER 는 읽기 전용이다. `SUPPORTER` 는 편집 함수에서 특별 취급되지 않는다.
- **문서 생성은 로그인한 모든 역할에게 허용**한다. `USP_S_INSERT_MANUAL`은 역할을 제한하지 않으며, 생성 뒤의 수정 권한은 위 문서·목차 규칙으로 판정한다.

## 새 API 를 만들 때

- 문서에 속한 데이터 **읽기**: `GetManualAccess` → `null` 이면 404, `CAN_READ != "Y"` 이면 403.
- 문서에 속한 데이터 **쓰기**: `DenyIfNotEditable(mid)` 를 먼저. 그리고 목차/블록 단위 쓰기는 프로시저가 `UFN_S_CAN_EDIT_SECTION` 을 호출해야 한다 — **새 쓰기 프로시저를 만들면 이 검사를 빼먹지 않는다.**
- 목차별 편집 가능 여부를 화면에 내려줄 땐 `CAN_EDIT_SEC` 컬럼을 쓴다 (프로시저가 계산한 값). JS 에서 팀 비교를 다시 구현하지 않는다.
- 로그인/세션 처리(`AuthController`)는 보안 결정이 얽혀 있다: 관리자 우회 없음, 실패 응답 단일화, 15분 5회 제한, 로그인 성공 시 세션 `Clear()` 후 재작성. 이 흐름을 단순화하지 않는다.
