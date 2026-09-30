using ExodusSystemManual.Utils;
using Microsoft.AspNetCore.Http;

namespace ExodusSystemManual.Tests.Utils;

public class SpaFallbackPolicyTests
{
    [Theory]
    [InlineData("GET", "/manual", false, true)]
    [InlineData("POST", "/manual", true, false)]
    [InlineData("GET", "/api/manual/list", true, false)]
    [InlineData("GET", "/Upload/sample.png", true, false)]
    [InlineData("GET", "/app/assets/index.js", true, false)]
    [InlineData("GET", "/dev/styleguide", true, true)]
    [InlineData("GET", "/dev/styleguide", false, false)]
    public void Spa_fallback_is_limited_to_allowed_routes(string method, string path, bool isDevelopment, bool expected)
    {
        var context = new DefaultHttpContext();
        context.Request.Method = method;
        context.Request.Path = path;

        Assert.Equal(expected, SpaFallbackPolicy.ShouldServe(context.Request, isDevelopment));
    }
}
