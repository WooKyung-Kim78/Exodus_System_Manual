using ExodusSystemManual.Common;
using ExodusSystemManual.Controllers.Common;
using ExodusSystemManual.Data;
using ExodusSystemManual.Models;
using ExodusSystemManual.Utils;
using Microsoft.AspNetCore.Mvc;

namespace ExodusSystemManual.Controllers;

public class AuthController : BaseController<AuthController>
{
    private readonly LoginThrottle _throttle;

    public AuthController(
        ApplicationDbContext db,
        IWebHostEnvironment env,
        ILogger<AuthController> logger,
        IConfiguration config,
        LoginThrottle throttle)
        : base(db, env, logger, config)
    {
        _throttle = throttle;
    }

    [HttpGet]
    [Route("/auth/sign-in")]
    public IActionResult SignIn(string? returnUrl)
    {
        if (HttpContext.Session.GetString(SessionKeys.IsLogin) == "TRUE")
            return Redirect("/");

        ViewData["ReturnUrl"] = IsLocalUrl(returnUrl) ? returnUrl : "/";
        return View();
    }

    [HttpGet]
    [Route("/auth/error403")]
    public IActionResult Error403() => View();

    [HttpGet]
    [Route("/auth/error404")]
    public IActionResult Error404() => View();

    [HttpGet]
    [Route("/auth/logout")]
    public IActionResult Logout()
    {
        HttpContext.Session.Clear();
        return Redirect("/auth/sign-in");
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [Produces("application/json")]
    public IActionResult UserLogin(UserLoginInputModel input)
    {
        if (!ModelState.IsValid)
            return JsonFail(StatusCodes.Status400BadRequest, "아이디와 비밀번호를 입력하세요.");

        var userId = input.USER_ID!.Trim();
        var remoteIp = HttpContext.Connection.RemoteIpAddress?.ToString();

        if (_throttle.IsBlocked(userId, remoteIp))
        {
            _logger.LogWarning("Login blocked by throttle. user={UserId} ip={Ip}", userId, remoteIp);
            return JsonFail(StatusCodes.Status429TooManyRequests,
                "로그인 시도가 너무 많습니다. 15분 후 다시 시도하세요.");
        }

        var user = _db.TB_S_USER.SingleOrDefault(u => u.USER_ID == userId && u.IS_DELETED == "N");

        // 계정 존재 여부를 노출하지 않도록 실패 응답을 하나로 통일한다.
        if (user is null || !PasswordHelper.Verify(user.PASSWORD, input.PASSWORD))
        {
            _throttle.RecordFailure(userId, remoteIp);
            return JsonFail(StatusCodes.Status400BadRequest, "아이디 또는 비밀번호를 확인하세요.");
        }

        if (user.AUTHORIZED != "Y")
        {
            _throttle.RecordFailure(userId, remoteIp);
            // 403 은 전역 AJAX 핸들러가 오류 페이지로 보내버리므로 400 으로 돌려준다.
            return JsonFail(StatusCodes.Status400BadRequest,
                "로그인 권한이 없습니다. 관리자에게 문의하세요.");
        }

        var roleName = _db.TB_S_ROLE
            .Where(r => r.USER_ID == user.USER_ID && r.IS_DELETED == "N")
            .Select(r => r.ROLE_NAME)
            .FirstOrDefault() ?? UserRoles.User;

        _throttle.Reset(userId, remoteIp);

        // 세션 고정 공격 방지: 인증 전 세션 상태를 모두 버린다.
        HttpContext.Session.Clear();
        HttpContext.Session.SetString(SessionKeys.IsLogin, "TRUE");
        HttpContext.Session.SetString(SessionKeys.UserId, user.USER_ID);
        HttpContext.Session.SetString(SessionKeys.FullName, user.FULL_NAME);
        HttpContext.Session.SetString(SessionKeys.Email, user.EMAIL ?? string.Empty);
        HttpContext.Session.SetString(SessionKeys.Role, roleName);
        HttpContext.Session.SetString(SessionKeys.Division, user.DIVISION ?? string.Empty);
        HttpContext.Session.SetString(SessionKeys.Team, user.TEAM ?? string.Empty);

        return JsonOk();
    }

    // 오픈 리다이렉트 차단: 외부 절대 URL 과 //evil.com 형태를 모두 거른다.
    private bool IsLocalUrl(string? url)
        => !string.IsNullOrEmpty(url)
           && url.StartsWith('/')
           && !url.StartsWith("//")
           && !url.StartsWith("/\\");
}
