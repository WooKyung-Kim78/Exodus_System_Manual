using Microsoft.Extensions.Caching.Memory;

namespace ExodusSystemManual.Utils;

/// 로그인 무작위 대입 방어. 계정 + 원격 IP 조합으로 실패 횟수를 센다.
public class LoginThrottle
{
    private const int MaxAttempts = 5;
    private static readonly TimeSpan Window = TimeSpan.FromMinutes(15);

    private readonly IMemoryCache _cache;

    public LoginThrottle(IMemoryCache cache) => _cache = cache;

    public bool IsBlocked(string userId, string? remoteIp)
        => _cache.TryGetValue(Key(userId, remoteIp), out int count) && count >= MaxAttempts;

    public void RecordFailure(string userId, string? remoteIp)
    {
        var key = Key(userId, remoteIp);
        var count = _cache.TryGetValue(key, out int current) ? current + 1 : 1;

        // 실패할 때마다 창을 갱신해 연속 시도를 계속 차단한다.
        _cache.Set(key, count, Window);
    }

    public void Reset(string userId, string? remoteIp) => _cache.Remove(Key(userId, remoteIp));

    private static string Key(string userId, string? remoteIp)
        => $"login-fail:{userId.ToLowerInvariant()}:{remoteIp ?? "unknown"}";
}
