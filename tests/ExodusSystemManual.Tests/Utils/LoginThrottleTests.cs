using ExodusSystemManual.Utils;
using Microsoft.Extensions.Caching.Memory;

namespace ExodusSystemManual.Tests.Utils;

public class LoginThrottleTests
{
    private static LoginThrottle Create() => new(new MemoryCache(new MemoryCacheOptions()));

    private static void Fail(LoginThrottle t, int times, string user = "u1", string? ip = "1.1.1.1")
    {
        for (var i = 0; i < times; i++) t.RecordFailure(user, ip);
    }

    [Fact]
    public void Blocks_after_five_failures_only()
    {
        var t = Create();
        Fail(t, 4);
        Assert.False(t.IsBlocked("u1", "1.1.1.1"));

        Fail(t, 1);
        Assert.True(t.IsBlocked("u1", "1.1.1.1"));
    }

    [Fact]
    public void Counts_per_user_and_ip_and_ignores_user_id_case()
    {
        var t = Create();
        Fail(t, 5, user: "User1");

        Assert.True(t.IsBlocked("user1", "1.1.1.1"));
        Assert.False(t.IsBlocked("user1", "2.2.2.2"));
        Assert.False(t.IsBlocked("other", "1.1.1.1"));
    }

    [Fact]
    public void Reset_unblocks()
    {
        var t = Create();
        Fail(t, 5);
        t.Reset("u1", "1.1.1.1");

        Assert.False(t.IsBlocked("u1", "1.1.1.1"));
    }
}
