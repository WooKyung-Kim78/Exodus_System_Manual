namespace ExodusSystemManual.Tests.Integration;

/// 환경 변수 EXODUS_TEST_DB(전용 테스트 DB 접속 문자열)가 없으면 건너뛴다.
/// 운영/공유 DB 를 절대 가리키지 않는다.
public sealed class RequiresDbFactAttribute : FactAttribute
{
    public const string EnvName = "EXODUS_TEST_DB";

    public RequiresDbFactAttribute()
    {
        if (string.IsNullOrWhiteSpace(ConnectionString))
            Skip = $"{EnvName} 환경 변수가 없어 건너뜀";
    }

    public static string? ConnectionString => Environment.GetEnvironmentVariable(EnvName);
}
