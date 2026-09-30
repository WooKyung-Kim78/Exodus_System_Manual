using System.Reflection;
using ExodusSystemManual.Controllers;
using ExodusSystemManual.Controllers.Attributes;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Routing;

namespace ExodusSystemManual.Tests.Controllers;

public class ApiAuthorizationTests
{
    [Fact]
    public void Api_actions_declare_ajax_or_anonymous_access()
    {
        var violations = typeof(AuthController).Assembly
            .GetTypes()
            .Where(t => t.Namespace == "ExodusSystemManual.Controllers")
            .Where(t => t.GetCustomAttributes<RouteAttribute>().Any(a => a.Template?.StartsWith("api/", StringComparison.Ordinal) == true))
            .SelectMany(t => t.GetMethods(BindingFlags.Instance | BindingFlags.Public | BindingFlags.DeclaredOnly))
            .Where(m => m.GetCustomAttributes<HttpMethodAttribute>().Any())
            .Where(m => !m.GetCustomAttributes<AjaxAuthAttribute>().Any() && !m.GetCustomAttributes<AllowAnonymousAttribute>().Any())
            .Select(m => $"{m.DeclaringType!.Name}.{m.Name}")
            .ToList();

        Assert.Empty(violations);
    }
}
