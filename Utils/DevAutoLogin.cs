using ExodusSystemManual.Common;
using ExodusSystemManual.Data;
using Microsoft.EntityFrameworkCore;

namespace ExodusSystemManual.Utils;

/// Development의 loopback 요청에서만 실제 사용자 레코드로 세션을 채운다.
public sealed class DevAutoLogin
{
    private readonly RequestDelegate _next;
    private readonly IConfiguration _config;
    private readonly ILogger<DevAutoLogin> _logger;

    public DevAutoLogin(RequestDelegate next, IConfiguration config, ILogger<DevAutoLogin> logger)
    {
        _next = next;
        _config = config;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context, ApplicationDbContext db)
    {
        if (!IsLoopback(context.Connection.RemoteIpAddress))
        {
            await _next(context);
            return;
        }

        var requestedUserId = context.Request.Headers["X-Dev-User"].FirstOrDefault();
        if (string.Equals(requestedUserId, "none", StringComparison.OrdinalIgnoreCase))
        {
            // 이 헤더는 자동 로그인을 억제한다. 로그인 E2E에서 모든 요청에 붙으므로
            // 여기서 세션을 지우면 로그인 POST 직후의 /api/auth/me도 로그아웃된다.
            await _next(context);
            return;
        }

        var userId = requestedUserId ?? _config["Dev:AutoLoginUserId"];
        if (!string.IsNullOrWhiteSpace(requestedUserId) || context.Session.GetString(SessionKeys.IsLogin) != "TRUE")
            if (!string.IsNullOrWhiteSpace(userId))
            await SetSessionAsync(context, db, userId);

        await _next(context);
    }

    private async Task SetSessionAsync(HttpContext context, ApplicationDbContext db, string userId)
    {
        var user = await db.TB_S_USER.SingleOrDefaultAsync(u => u.USER_ID == userId && u.IS_DELETED == "N");
        if (user is null || user.AUTHORIZED != "Y") return;

        var role = await db.TB_S_ROLE
            .Where(r => r.USER_ID == user.USER_ID && r.IS_DELETED == "N")
            .Select(r => r.ROLE_NAME)
            .FirstOrDefaultAsync() ?? UserRoles.User;

        context.Session.Clear();
        context.Session.SetString(SessionKeys.IsLogin, "TRUE");
        context.Session.SetString(SessionKeys.UserId, user.USER_ID);
        context.Session.SetString(SessionKeys.FullName, user.FULL_NAME);
        context.Session.SetString(SessionKeys.Email, user.EMAIL ?? string.Empty);
        context.Session.SetString(SessionKeys.Role, role);
        context.Session.SetString(SessionKeys.Division, user.DIVISION ?? string.Empty);
        context.Session.SetString(SessionKeys.Team, user.TEAM ?? string.Empty);
        _logger.LogWarning("DEV AUTO LOGIN user={UserId}", user.USER_ID);
    }

    internal static bool IsLoopback(System.Net.IPAddress? address)
        => address is not null && System.Net.IPAddress.IsLoopback(address);
}
