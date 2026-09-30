namespace ExodusSystemManual.Common;

public sealed record MenuLink(string KEY, string PATH);

public static class MenuCatalog
{
    private sealed record MenuDefinition(string Key, string Path, IReadOnlySet<string> Roles);

    private static readonly IReadOnlyList<MenuDefinition> Definitions =
    [
        new("dashboard", "/", new HashSet<string>(UserRoles.All)),
        new("manual", "/manual", new HashSet<string>(UserRoles.All)),
        new("admin.setting", "/admin/setting", new HashSet<string> { UserRoles.Admin, UserRoles.Supporter }),
        new("admin.code", "/admin/code", new HashSet<string> { UserRoles.Admin, UserRoles.Supporter }),
        new("admin.section-template", "/admin/section-template", new HashSet<string> { UserRoles.Admin }),
        new("admin.user", "/admin/user", new HashSet<string> { UserRoles.Admin }),
    ];

    public static IReadOnlyList<MenuLink> GetAccessibleMenus(string role) => Definitions
        .Where(item => item.Roles.Contains(role))
        .Select(item => new MenuLink(item.Key, item.Path))
        .ToList();
}
