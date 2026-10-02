namespace ExodusSystemManual.Common;

public sealed record MenuLink(string KEY, string PATH, string LABEL, string? GROUP, string ICON, string? DESCRIPTION);

public static class MenuCatalog
{
    private sealed record MenuDefinition(string Key, string Path, string Label, string? Group, string Icon, string? Description, IReadOnlySet<string> Roles);

    private static readonly IReadOnlyList<MenuDefinition> Definitions =
    [
        new("dashboard", "/", "Dashboard", null, "view-dashboard-outline", "시스템 매뉴얼 작성과 관리 업무를 시작합니다.", new HashSet<string>(UserRoles.All)),
        new("manual", "/manual", "Manuals", "Workspace", "file-document-outline", "시스템 매뉴얼을 조회하고 관리합니다.", new HashSet<string>(UserRoles.All)),
        new("admin.setting", "/admin/setting", "Settings", "Administration", "cog-outline", "SMTP 발송 환경과 발송 이력을 관리합니다.", new HashSet<string> { UserRoles.Admin, UserRoles.Supporter }),
        new("admin.code", "/admin/code", "Common Codes", "Administration", "code-tags", "미리보기 표지 문구와 로고를 관리합니다.", new HashSet<string> { UserRoles.Admin, UserRoles.Supporter }),
        new("admin.section-template", "/admin/section-template", "Section Templates", "Administration", "format-list-bulleted-square", "문서를 새로 만들 때 필수 목차가 자동으로 들어갑니다. 옵션 목차는 작성자가 편집기에서 골라 추가합니다.", new HashSet<string> { UserRoles.Admin }),
        new("admin.user", "/admin/user", "Users", "Administration", "account-group-outline", "계정, 역할, 승인 상태를 관리합니다.", new HashSet<string> { UserRoles.Admin }),
    ];

    public static IReadOnlyList<MenuLink> GetAccessibleMenus(string role) => Definitions
        .Where(item => item.Roles.Contains(role))
        .Select(item => new MenuLink(item.Key, item.Path, item.Label, item.Group, item.Icon, item.Description))
        .ToList();
}
