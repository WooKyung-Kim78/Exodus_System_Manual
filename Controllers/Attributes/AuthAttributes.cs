using ExodusSystemManual.Common;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace ExodusSystemManual.Controllers.Attributes;

/// 페이지 요청용. 미인증이면 로그인 화면으로 리다이렉트한다.
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class AuthAttribute : ActionFilterAttribute
{
    private readonly string[] _roles;

    public AuthAttribute(string roles = "") => _roles = SplitRoles(roles);

    public override void OnActionExecuting(ActionExecutingContext context)
    {
        base.OnActionExecuting(context);
        var session = context.HttpContext.Session;

        if (session.GetString(SessionKeys.IsLogin) != "TRUE")
        {
            var returnUrl = context.HttpContext.Request.Path + context.HttpContext.Request.QueryString;
            context.Result = new RedirectResult($"/auth/sign-in?returnUrl={Uri.EscapeDataString(returnUrl)}");
            return;
        }

        if (_roles.Length > 0 && !_roles.Contains(session.GetString(SessionKeys.Role) ?? string.Empty))
        {
            context.Result = new RedirectResult("/auth/error403");
        }
    }

    internal static string[] SplitRoles(string roles)
        => string.IsNullOrWhiteSpace(roles)
            ? Array.Empty<string>()
            : roles.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
}

/// AJAX 요청용. 리다이렉트 대신 401/403 상태 코드를 반환한다.
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class AjaxAuthAttribute : ActionFilterAttribute
{
    private readonly string[] _roles;

    public AjaxAuthAttribute(string roles = "") => _roles = AuthAttribute.SplitRoles(roles);

    public override void OnActionExecuting(ActionExecutingContext context)
    {
        base.OnActionExecuting(context);
        var session = context.HttpContext.Session;

        if (session.GetString(SessionKeys.IsLogin) != "TRUE")
        {
            context.Result = new ObjectResult(new { success = false, message = "Unauthorized" })
            {
                StatusCode = StatusCodes.Status401Unauthorized
            };
            return;
        }

        if (_roles.Length > 0 && !_roles.Contains(session.GetString(SessionKeys.Role) ?? string.Empty))
        {
            context.Result = new ObjectResult(new { success = false, message = "Forbidden" })
            {
                StatusCode = StatusCodes.Status403Forbidden
            };
        }
    }
}
