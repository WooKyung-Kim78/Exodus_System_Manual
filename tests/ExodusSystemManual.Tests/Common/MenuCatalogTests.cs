using ExodusSystemManual.Common;

namespace ExodusSystemManual.Tests.Common;

public class MenuCatalogTests
{
    [Theory]
    [InlineData(UserRoles.Admin, new[] { "dashboard", "manual", "admin.setting", "admin.code", "admin.table-param", "admin.section-template", "admin.user" })]
    [InlineData(UserRoles.Supporter, new[] { "dashboard", "manual", "admin.setting", "admin.code" })]
    [InlineData(UserRoles.User, new[] { "dashboard", "manual" })]
    [InlineData(UserRoles.Reader, new[] { "dashboard", "manual" })]
    public void GetAccessibleMenus_returns_only_role_allowed_menu(string role, string[] expectedKeys)
    {
        var menus = MenuCatalog.GetAccessibleMenus(role);

        Assert.Equal(expectedKeys, menus.Select(item => item.KEY));
    }

    [Fact]
    public void GetAccessibleMenus_returns_empty_for_unknown_role()
    {
        Assert.Empty(MenuCatalog.GetAccessibleMenus("UNKNOWN"));
    }

    [Fact]
    public void GetAccessibleMenus_returns_navigation_metadata()
    {
        var manual = MenuCatalog.GetAccessibleMenus(UserRoles.User).Single(item => item.KEY == "manual");

        Assert.Equal("Manuals", manual.LABEL);
        Assert.Equal("Workspace", manual.GROUP);
        Assert.Equal("file-document-outline", manual.ICON);
        Assert.False(string.IsNullOrWhiteSpace(manual.DESCRIPTION));
    }
}
