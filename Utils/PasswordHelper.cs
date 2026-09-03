using ExodusSystemManual.Models;
using Microsoft.AspNetCore.Identity;

namespace ExodusSystemManual.Utils;

/// PBKDF2(ASP.NET Core Identity v3) 기반 해시. 솔트·반복횟수는 해시 문자열에 함께 저장된다.
public static class PasswordHelper
{
    private static readonly PasswordHasher<User> Hasher = new();

    public const string BootstrapSentinel = "!NEEDS_BOOTSTRAP";

    public static string Hash(string plainPassword) => Hasher.HashPassword(null!, plainPassword);

    public static bool Verify(string? storedHash, string? plainPassword)
    {
        if (string.IsNullOrEmpty(storedHash) || string.IsNullOrEmpty(plainPassword))
            return false;

        try
        {
            var result = Hasher.VerifyHashedPassword(null!, storedHash, plainPassword);
            return result is PasswordVerificationResult.Success
                or PasswordVerificationResult.SuccessRehashNeeded;
        }
        catch (FormatException)
        {
            // 부트스트랩 표식처럼 Base64 가 아닌 값이 저장된 경우.
            return false;
        }
    }

    /// 8자 이상, 영문·숫자·특수문자 각 1자 이상.
    public static bool IsStrongEnough(string? password, out string message)
    {
        message = string.Empty;

        if (string.IsNullOrWhiteSpace(password) || password.Length < 8)
        {
            message = "비밀번호는 8자 이상이어야 합니다.";
            return false;
        }
        if (!password.Any(char.IsLetter) || !password.Any(char.IsDigit)
            || password.All(char.IsLetterOrDigit))
        {
            message = "영문, 숫자, 특수문자를 각각 1자 이상 포함해야 합니다.";
            return false;
        }
        return true;
    }
}
