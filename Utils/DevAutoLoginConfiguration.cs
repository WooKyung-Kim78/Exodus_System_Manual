namespace ExodusSystemManual.Utils;

public static class DevAutoLoginConfiguration
{
    public static bool ShouldRegister(IHostEnvironment environment) => environment.IsDevelopment();

    public static void Validate(IHostEnvironment environment, IConfiguration configuration)
    {
        if (!environment.IsDevelopment()
            && !string.IsNullOrWhiteSpace(configuration["Dev:AutoLoginUserId"]))
            throw new InvalidOperationException("Dev:AutoLoginUserId 는 Development 환경에서만 설정할 수 있습니다.");
    }
}
