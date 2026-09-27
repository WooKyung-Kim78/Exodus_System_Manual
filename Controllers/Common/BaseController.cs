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
    private void NoStore()
        => Response.Headers.CacheControl = "no-store, no-cache, must-revalidate";

    protected string FirstError()
        => ModelState.Values.SelectMany(v => v.Errors).FirstOrDefault()?.ErrorMessage ?? "입력값을 확인하세요.";
}
