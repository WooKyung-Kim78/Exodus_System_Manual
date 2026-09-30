using ExodusSystemManual.Utils;

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
}
