using ExodusSystemManual.Utils;

namespace ExodusSystemManual.Tests.Utils;

public class PasswordHelperTests
{
    [Fact]
    public void Hash_then_verify_succeeds_and_hash_is_salted()
    {
        var a = PasswordHelper.Hash("Abcd1234!");
        var b = PasswordHelper.Hash("Abcd1234!");

        Assert.NotEqual(a, b);
        Assert.True(PasswordHelper.Verify(a, "Abcd1234!"));
    }

    [Fact]
    public void Verify_rejects_wrong_password()
        => Assert.False(PasswordHelper.Verify(PasswordHelper.Hash("Abcd1234!"), "abcd1234!"));

    [Theory]
    [InlineData(null, "x")]
    [InlineData("", "x")]
    [InlineData("hash", null)]
    [InlineData("hash", "")]
    [InlineData(PasswordHelper.BootstrapSentinel, "x")]
    public void Verify_rejects_missing_or_bootstrap_values(string? stored, string? plain)
        => Assert.False(PasswordHelper.Verify(stored, plain));

    [Theory]
    [InlineData("Abc123!@", true)]
    [InlineData("Abc12!", false)]        // 8자 미만
    [InlineData("Abcdefg1", false)]      // 특수문자 없음
    [InlineData("abcdefg!", false)]      // 숫자 없음
    [InlineData("12345678!", false)]     // 영문 없음
    [InlineData(null, false)]
    public void IsStrongEnough_follows_policy(string? password, bool expected)
    {
        Assert.Equal(expected, PasswordHelper.IsStrongEnough(password, out var message));
        Assert.Equal(expected, message.Length == 0);
    }
}
