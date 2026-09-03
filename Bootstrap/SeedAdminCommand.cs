using ExodusSystemManual.Data;
using ExodusSystemManual.Utils;
using Microsoft.EntityFrameworkCore;

namespace ExodusSystemManual.Bootstrap;

/// `dotnet run -- seed-admin` 진입점. 비밀번호는 인자로 받지 않고 콘솔에서만 입력받는다
/// (명령행 인자는 셸 히스토리와 프로세스 목록에 남는다).
public static class SeedAdminCommand
{
    public static async Task<int> RunAsync(string[] args)
    {
        var config = new ConfigurationBuilder()
            .SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile("appsettings.json", optional: false)
            .AddJsonFile("appsettings.Development.json", optional: true)
            .AddUserSecrets(typeof(SeedAdminCommand).Assembly, optional: true)
            .AddEnvironmentVariables()
            .Build();

        var connectionString = config.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            Console.Error.WriteLine("커넥션 문자열이 비어 있습니다. 아래 명령으로 먼저 설정하세요:");
            Console.Error.WriteLine("  dotnet user-secrets set \"ConnectionStrings:DefaultConnection\" \"<연결문자열>\"");
            return 1;
        }

        var userId = args.Length > 1 && !string.IsNullOrWhiteSpace(args[1]) ? args[1].Trim() : "admin";

        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseSqlServer(connectionString)
            .Options;

        await using var db = new ApplicationDbContext(options);

        var user = await db.TB_S_USER.SingleOrDefaultAsync(u => u.USER_ID == userId && u.IS_DELETED == "N");
        if (user is null)
        {
            Console.Error.WriteLine($"'{userId}' 계정을 찾을 수 없습니다. 03_seed.sql 을 먼저 실행하세요.");
            return 1;
        }

        Console.WriteLine($"'{userId}' 계정의 비밀번호를 설정합니다.");

        string password, confirm;
        try
        {
            password = ReadHidden("새 비밀번호: ");
            if (!PasswordHelper.IsStrongEnough(password, out var message))
            {
                Console.Error.WriteLine(message);
                return 1;
            }

            confirm = ReadHidden("비밀번호 확인: ");
        }
        catch (InvalidOperationException ex)
        {
            Console.Error.WriteLine(ex.Message);
            return 1;
        }

        if (!string.Equals(password, confirm, StringComparison.Ordinal))
        {
            Console.Error.WriteLine("두 비밀번호가 일치하지 않습니다.");
            return 1;
        }

        user.PASSWORD = PasswordHelper.Hash(password!);
        user.AUTHORIZED = "Y";
        user.UPT_ID = "system";
        user.UPT_DT = DateTime.Now;
        await db.SaveChangesAsync();

        Console.WriteLine($"완료되었습니다. '{userId}' 계정으로 로그인할 수 있습니다.");
        return 0;
    }

    private static string ReadHidden(string prompt)
    {
        // 입력이 리다이렉트되면 ReadKey/ReadLine 이 즉시 반환되어 빈 값이 그대로 저장된다.
        if (Console.IsInputRedirected)
            throw new InvalidOperationException(
                "이 명령은 대화형 터미널에서만 실행할 수 있습니다. " +
                "VS Code 터미널 패널이나 PowerShell 창에서 직접 실행하세요.");

        Console.Write(prompt);

        var buffer = new System.Text.StringBuilder();
        while (true)
        {
            var key = Console.ReadKey(intercept: true);
            if (key.Key == ConsoleKey.Enter) break;

            if (key.Key == ConsoleKey.Backspace)
            {
                if (buffer.Length > 0) buffer.Length--;
                continue;
            }
            if (!char.IsControl(key.KeyChar)) buffer.Append(key.KeyChar);
        }
        Console.WriteLine();
        return buffer.ToString();
    }
}
