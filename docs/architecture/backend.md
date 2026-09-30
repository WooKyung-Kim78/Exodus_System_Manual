# 백엔드 구조

## 요청 흐름

```
브라우저(Vue/jQuery) ─ AJAX(JSON) ─▶ Controller ─ FromSqlRaw("EXECUTE dbo.USP_...") ─▶ SQL Server
                    ◀─ {success,data|message}
페이지 요청: [Auth] → View(cshtml) 만 반환. 데이터는 화면이 다시 AJAX 로 가져온다.
```

- 페이지 액션(`[Auth]`)은 권한만 확인하고 빈 View 를 돌려준다. 데이터 조회는 별도 `[AjaxAuth]` GET 엔드포인트.
- 라우팅은 컨트롤러 `[Route("manual")]` + 액션 `[HttpGet("detail")]` 식의 **명시적 attribute routing**, 경로는 소문자 kebab. (`/auth/sign-in`, `/editor/section/history`)
- 컨트롤러는 `BaseController<T>` 를 상속하고 생성자에서 `db, env, logger, config` 를 부모로 넘긴다.

## BaseController 계약 ([Controllers/Common/BaseController.cs](../../Controllers/Common/BaseController.cs))

| 멤버 | 용도 |
|---|---|
| `CurrentUserId`, `CurrentRole` | 세션에서 읽음. 요청 본문의 사용자 ID 는 **신뢰하지 않는다** |
| `GetManualAccess(mId)` | `USP_S_SELECT_MANUAL_ACCESS` 호출 → `CAN_READ`/`CAN_EDIT`/`USER_ROLE`/`MEMBER_ROLE` |
| `JsonOk(data)` / `JsonFail(status, msg)` | **모든 AJAX 응답은 이 둘로만.** `no-store` 헤더가 여기서 붙는다 |
| `DenyIfNotReadable(mid[, out access])` | 읽기 API 검사. 통과 시 null, 아니면 404/403 응답 |
| `DenyPageIfNotReadable(mid)` | 페이지 요청용 (404 / `/auth/error403` 리다이렉트) |
| `DenyIfNotEditable(mid)` | 쓰기 API 검사 (문서 단위) |
| `ToJson(ResultModel?)` | 쓰기 프로시저 결과 → 응답 (`Success==0` 이면 400 + `ReturnMsg`) |
| `CurrentUserName` | 세션 `FullName` (없으면 ID) |
| `FirstError()` | ModelState 첫 오류 메시지 |

**응답 규약**: 성공 `{ success:true, data }`, 실패 `{ success:false, message }` + HTTP 상태. JS 는 `res.data.xxx`, `getErrorMessage(xhr)` 로 읽는다.
JSON 은 `PropertyNamingPolicy = null` — **C# 속성명 그대로(UPPER_SNAKE)** 나간다. camelCase 로 바꾸지 않는다.

상태 코드 관례: 입력/업무 오류 400, 문서 없음 404, 권한 없음 403, 동시성 충돌 409(`ReturnMsg == "CONFLICT"`), 외부(datasheet) 장애 503.
단, 로그인 화면의 권한 오류는 전역 AJAX 핸들러가 403 을 오류 페이지로 보내버리므로 400 을 쓴다 (AuthController 주석 참고).

## 쓰기 액션 표준 형태

```csharp
[AjaxAuth] [HttpPost("x")] [ValidateAntiForgeryToken] [Produces("application/json")]
public IActionResult DoX(InputX input)
{
    if (!ModelState.IsValid) return JsonFail(400, FirstError());
    var denied = DenyIfNotEditable(input.M_ID);      // 권한 (BaseController, 프로시저 결과 기반)
    if (denied is not null) return denied;
    var result = _db.ResultModel.FromSqlRaw("EXECUTE dbo.USP_S_...", ...).AsEnumerable().FirstOrDefault();
    return ToJson(result);                           // Success==0 이면 400 + ReturnMsg
}
```

`ResultModel { Success, ReturnMsg }` 가 모든 쓰기 프로시저의 공통 반환. `ReturnMsg` 는 실패 메시지이거나, 성공 시 **새로 만든 ID** 를 문자열로 담는 용도로도 쓴다.

권한 검사·결과 변환은 **BaseController 의 위 헬퍼만** 쓴다. 컨트롤러에 `GetManualAccess` + 404/403 시퀀스를 직접 쓰거나 private 사본을 만들지 않는다. 여러 컨트롤러가 쓸 공통 동작이 생기면 여기에 올린다.

## DI ([Program.cs](../../Program.cs))

- Singleton: `LoginThrottle`, `HtmlSanitize`, `PdfRenderer`(브라우저 1개 재사용, 동시 페이지 2개 제한)
- Scoped: `SendMail`, `DatasheetSpec`, 두 DbContext
- `DatasheetConnection` 이 비어 있으면 `DefaultConnection` 재사용.
- 세션 4시간, 쿠키 `ExodusSystemManual.SESSION`. Antiforgery 헤더명 `RequestVerificationToken` (`ajaxSetting.js` 와 짝).
- DataProtection 키는 `App_Data/keys` (gitignore). SMTP 비밀번호 암호화에 쓰이므로 키 폴더를 지우면 저장된 SMTP 비밀번호를 복호화 못 한다.

## 외부 의존

- **PDF**: Playwright Chromium. 서버에 브라우저 필요 → [document-rendering.md](document-rendering.md)
- **Datasheet DB**: `DatasheetDbContext` 는 **읽기 전용** 프로시저 3개만 호출. 스키마를 이쪽에서 바꾸지 않는다.
- **메일**: `SendMail` — 설정은 `TB_S_SETTING`(CATEGORY=SMTP). `SYSTEM_SMTP_SCOPE=T` 면 실발송 대신 `App_Data/mail-drop/*.eml`. 모든 발송은 `TB_S_MAIL_LOG` 기록.
- **업로드**: `ImageUpload.SaveAsync` → `wwwroot/Upload/` (gitignore), `TB_S_UPLOAD_FILE` 에 기록. 최대 크기 `APP:MAX_UPLOAD_BYTES`.
