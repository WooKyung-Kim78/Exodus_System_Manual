using System.Net;
using ExodusSystemManual.Utils;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging.Abstractions;

namespace ExodusSystemManual.Tests.Utils;

public class DevAutoLoginConfigurationTests
{
    [Fact]
    public void Production_environment_does_not_register_auto_login()
    {
        var environment = new TestHostEnvironment { EnvironmentName = "Production" };

        Assert.False(DevAutoLoginConfiguration.ShouldRegister(environment));
    }

    [Fact]
    public void Development_auto_login_setting_in_non_development_environment_is_rejected()
    {
        var environment = new TestHostEnvironment { EnvironmentName = "Production" };
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?> { ["Dev:AutoLoginUserId"] = "dev-admin" })
            .Build();

        Assert.Throws<InvalidOperationException>(() => DevAutoLoginConfiguration.Validate(environment, configuration));
    }

    [Fact]
    public async Task Non_loopback_request_is_passed_through_without_database_access()
    {
        var called = false;
        var middleware = new DevAutoLogin(
            _ => { called = true; return Task.CompletedTask; },
            new ConfigurationBuilder().Build(),
            NullLogger<DevAutoLogin>.Instance);
        var context = new DefaultHttpContext();
        context.Connection.RemoteIpAddress = IPAddress.Parse("10.0.0.10");

        await middleware.InvokeAsync(context, null!);

        Assert.True(called);
    }

    [Fact]
    public async Task None_header_disables_auto_login_without_touching_the_session()
    {
        var called = false;
        var middleware = new DevAutoLogin(
            _ => { called = true; return Task.CompletedTask; },
            new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Dev:AutoLoginUserId"] = "dev-admin",
            }).Build(),
            NullLogger<DevAutoLogin>.Instance);
        var context = new DefaultHttpContext();
        context.Connection.RemoteIpAddress = IPAddress.Loopback;
        context.Request.Headers["X-Dev-User"] = "none";

        await middleware.InvokeAsync(context, null!);

        Assert.True(called);
    }

    private sealed class TestHostEnvironment : IHostEnvironment
    {
        public string EnvironmentName { get; set; } = "Development";
        public string ApplicationName { get; set; } = "ExodusSystemManual.Tests";
        public string ContentRootPath { get; set; } = Path.GetTempPath();
        public IFileProvider ContentRootFileProvider { get; set; } = new NullFileProvider();
    }
}
