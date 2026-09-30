using ExodusSystemManual.Models;

namespace ExodusSystemManual.Tests.Models;

public class PreviewViewModelTests
{
    [Fact]
    public void ParseStyles_empty_or_invalid_json_returns_defaults()
    {
        var empty = PreviewViewModel.ParseStyles(null);
        var invalid = PreviewViewModel.ParseStyles("{not-json");

        Assert.Equal(13, empty[1].Size);
        Assert.Equal("#3f4254", empty[3].Color);
        Assert.Equal(HeadingStyle.Defaults()[2].ToCss(), invalid[2].ToCss());
    }

    [Fact]
    public void ParseStyles_applies_saved_levels_and_keeps_default_levels()
    {
        var styles = PreviewViewModel.ParseStyles("""
            { "1": { "size": 18, "color": "#123456", "bold": false, "underline": true } }
            """);

        Assert.Equal(18, styles[1].Size);
        Assert.Equal("#123456", styles[1].Color);
        Assert.False(styles[1].Bold);
        Assert.True(styles[1].Underline);
        Assert.Equal(13, styles[2].Size);
        Assert.True(styles[2].Bold);
    }

    [Fact]
    public void ParseStyles_preserves_additional_numeric_levels_and_ignores_non_numeric_keys()
    {
        var styles = PreviewViewModel.ParseStyles("""
            { "4": { "size": 20 }, "cover": { "size": 30 } }
            """);

        Assert.Equal(20, styles[4].Size);
        Assert.DoesNotContain("cover", styles.Keys.Select(key => key.ToString()));
    }
}
