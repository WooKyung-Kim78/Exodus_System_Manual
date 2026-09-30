using ExodusSystemManual.Utils;

namespace ExodusSystemManual.Tests.Utils;

public class HtmlSanitizeTests
{
    private readonly HtmlSanitize _sut = new();

    [Theory]
    [InlineData("<p>a</p><script>alert(1)</script>", "script")]
    [InlineData("<p onclick=\"x()\">a</p>", "onclick")]
    [InlineData("<a href=\"javascript:alert(1)\">a</a>", "javascript:")]
    [InlineData("<img src=\"data:image/png;base64,AAAA\">", "data:")]
    public void Removes_dangerous_content(string html, string forbidden)
        => Assert.DoesNotContain(forbidden, _sut.Clean(html), StringComparison.OrdinalIgnoreCase);

    [Theory]
    [InlineData("<strong>a</strong>", "<strong>")]
    [InlineData("<table><tbody><tr><td>a</td></tr></tbody></table>", "<td>")]
    [InlineData("<span style=\"color:red\">a</span>", "color")]
    [InlineData("<a href=\"https://example.com\">a</a>", "https://example.com")]
    public void Keeps_editor_output(string html, string expected)
        => Assert.Contains(expected, _sut.Clean(html));

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    public void Returns_blank_input_unchanged(string? html)
        => Assert.Equal(html, _sut.Clean(html));
}
