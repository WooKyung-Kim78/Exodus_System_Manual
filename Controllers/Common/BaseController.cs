using ExodusSystemManual.Common;
using ExodusSystemManual.Data;
using ExodusSystemManual.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace ExodusSystemManual.Controllers.Common;

public abstract class BaseController<T> : Controller where T : BaseController<T>
{
    protected readonly ApplicationDbContext _db;
    protected readonly IWebHostEnvironment _env;
    protected readonly ILogger<T> _logger;
    protected readonly IConfiguration _config;

    protected BaseController(
        ApplicationDbContext db,
        IWebHostEnvironment env,
        ILogger<T> logger,
        IConfiguration config)
    {
        _db = db;
        _env = env;
        _logger = logger;
        _config = config;
    }

    protected string? CurrentUserId => HttpContext.Session.GetString(SessionKeys.UserId);
    protected string CurrentRole => HttpContext.Session.GetString(SessionKeys.Role) ?? UserRoles.User;

    protected User? GetCurrentUser()
    {
        var userId = CurrentUserId;
        if (string.IsNullOrEmpty(userId)) return null;

        return _db.TB_S_USER.SingleOrDefault(u => u.USER_ID == userId && u.IS_DELETED == "N");
    }

    /// 문서 단위 권한. 쓰기 API 는 호출 전에 반드시 CAN_EDIT 을 확인한다.
    protected ManualAccess? GetManualAccess(string mId)
    {
        var userId = CurrentUserId;
        if (string.IsNullOrEmpty(mId) || string.IsNullOrEmpty(userId)) return null;

        return _db.USP_S_SELECT_MANUAL_ACCESS
            .FromSqlRaw("EXECUTE dbo.USP_S_SELECT_MANUAL_ACCESS {0}, {1}", mId, userId)
            .AsEnumerable()
            .FirstOrDefault();
    }

    protected string CurrentUserName
        => HttpContext.Session.GetString(SessionKeys.FullName) ?? CurrentUserId ?? "시스템";

    /// 읽기 API 용. 통과하면 null, 아니면 404/403 응답을 돌려준다.
    protected IActionResult? DenyIfNotReadable(string mId, out ManualAccess? access)
    {
        access = GetManualAccess(mId);
        if (access is null) return JsonFail(StatusCodes.Status404NotFound, "문서를 찾을 수 없습니다.");
        if (access.CAN_READ != "Y") return JsonFail(StatusCodes.Status403Forbidden, "열람 권한이 없습니다.");
        return null;
    }

    protected IActionResult? DenyIfNotReadable(string mId) => DenyIfNotReadable(mId, out _);

    /// 쓰기 API 용. 통과하면 null. 문서 단위 검사이며 목차 단위는 프로시저가 다시 검사한다.
    protected IActionResult? DenyIfNotEditable(string mId)
    {
        var access = GetManualAccess(mId);
        if (access is null) return JsonFail(StatusCodes.Status404NotFound, "문서를 찾을 수 없습니다.");
        if (access.MEMBER_ROLE is null && access.USER_ROLE != UserRoles.Admin)
            return JsonFail(StatusCodes.Status403Forbidden, "이 문서의 참여자가 아닙니다.");
        if (access.CAN_EDIT != "Y")
            return JsonFail(StatusCodes.Status403Forbidden, "작성(DRAFT) 상태의 문서만 수정할 수 있습니다.");
        return null;
    }

    /// 쓰기 프로시저의 ResultModel 을 응답으로 바꾼다.
    protected IActionResult ToJson(ResultModel? result)
        => result is null || result.Success == 0
            ? JsonFail(StatusCodes.Status400BadRequest, result?.ReturnMsg ?? "요청을 처리하지 못했습니다.")
            : JsonOk();

    protected IActionResult JsonOk(object? data = null)
    {
        NoStore();
        return Ok(new { success = true, data });
    }

    protected IActionResult JsonFail(int statusCode, string message)
    {
        NoStore();
        return StatusCode(statusCode, new { success = false, message });
    }

    /// 로그인 사용자별 데이터라 브라우저/프록시에 남으면 안 된다.
    protected void NoStore()
        => Response.Headers.CacheControl = "no-store, no-cache, must-revalidate";

    protected string FirstError()
        => ModelState.Values.SelectMany(v => v.Errors).FirstOrDefault()?.ErrorMessage ?? "입력값을 확인하세요.";
}
