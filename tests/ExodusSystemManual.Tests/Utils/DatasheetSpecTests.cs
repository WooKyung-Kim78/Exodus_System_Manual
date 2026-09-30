using ExodusSystemManual.Utils;
using ExodusSystemManual.Models;

namespace ExodusSystemManual.Tests.Utils;

public class DatasheetSpecTests
{
    [Theory]
    [InlineData("SPECIFICATIONS", true)]
    [InlineData("3. Specification", true)]
    [InlineData("Overview", false)]
    [InlineData("", false)]
    [InlineData(null, false)]
    public void IsSpecSection_matches_keyword_case_insensitively(string? title, bool expected)
        => Assert.Equal(expected, DatasheetSpec.IsSpecSection(title));

    [Fact]
    public void BuildHtml_encodes_plain_values_and_marks_categories()
    {
        var spec = new DatasheetSpecResult
        {
            BandNum = 2,
            BandNames = new List<string> { "Low", "High" },
        };
        var category = new DatasheetSpecCategory
        {
            CATEGORY = "Voltage <limits>",
            TITLE_1 = "Specification",
            TITLE_2 = "Notes",
            HEADER = "<i>trusted header</i>",
            FOOTER = "<em>trusted footer</em>",
        };
        category.ROWS.Add(new DatasheetSpecRow
        {
            DMP_ID = "row-1",
            PARAMETER = "Input <V>",
            SPECS = new List<DatasheetSpecValue>
            {
                new("<b>1 V</b>", "Y"),
            },
            NOTES = new List<DatasheetSpecValue>
            {
                new("<script>not markup</script>", "N"),
            },
        });
        spec.Categories.Add(category);

        var html = DatasheetSpec.BuildHtml(spec, markCategories: true);

        Assert.Contains("QZXC0XZQ", html);
        Assert.Contains("Voltage &lt;limits&gt;", html);
        Assert.Contains("Input &lt;V&gt;", html);
        Assert.Contains("<b>1 V</b>", html);
        Assert.Contains("&lt;script&gt;not markup&lt;/script&gt;", html);
        Assert.Contains("<i>trusted header</i>", html);
        Assert.Contains("<em>trusted footer</em>", html);
        Assert.Contains("colspan=\"2\"", html);
    }

    [Fact]
    public void BuildHtml_uses_pin_table_shape_without_notes_cells()
    {
        var spec = new DatasheetSpecResult { BandNum = 2 };
        var category = new DatasheetSpecCategory
        {
            CATEGORY = "PIN ASSIGNMENT",
            IS_PIN = true,
        };
        category.ROWS.Add(new DatasheetSpecRow
        {
            DMP_ID = "row-1",
            PIN = "1",
            PARAMETER = "Power",
            SPECS = new List<DatasheetSpecValue> { new("Supply", "N") },
            NOTES = new List<DatasheetSpecValue> { new("ignored", "N") },
        });
        spec.Categories.Add(category);

        var html = DatasheetSpec.BuildHtml(spec);

        Assert.Contains("<div class=\"ds-cell\">Pin</div>", html);
        Assert.Contains("Function", html);
        Assert.Contains("Description", html);
        Assert.DoesNotContain("ignored", html);
    }
}
