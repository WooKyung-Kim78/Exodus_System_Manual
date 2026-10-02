using System.Text.Json;
using ExodusSystemManual.Utils;

namespace ExodusSystemManual.Tests.Utils;

public class TableStyleJsonSanitizerTests
{
    private readonly HtmlSanitize _sanitizer = new();

    [Fact]
    public void Clean_sanitizes_only_rich_cells()
    {
        var json = "{\"rich\":[false,true],\"rows\":[[\"<b>plain</b>\",\"<p>x</p><script>alert(1)</script>\"]]}";

        var result = TableStyleJsonSanitizer.Clean(json, _sanitizer)!;
        using var document = JsonDocument.Parse(result);
        var cells = document.RootElement.GetProperty("rows")[0];

        Assert.Equal("<b>plain</b>", cells[0].GetString());
        Assert.DoesNotContain("script", cells[1].GetString(), StringComparison.OrdinalIgnoreCase);
    }

    [Theory]
    [InlineData("{")]
    [InlineData("[]")]
    public void Clean_rejects_invalid_table_shape(string json)
        => Assert.Null(TableStyleJsonSanitizer.Clean(json, _sanitizer));
}
