namespace ExodusSystemManual.Common;

public static class SessionKeys
{
    public const string IsLogin = "IS_LOGIN";
    public const string UserId = "USER_ID";
    public const string FullName = "FULL_NAME";
    public const string Email = "EMAIL";
    public const string Role = "ROLE";
    public const string Division = "USER_DIVISION";
    public const string Team = "USER_TEAM";
}

public static class UserRoles
{
    public const string Admin = "ADMIN";
    public const string Supporter = "SUPPORTER";
    public const string User = "USER";
    public const string Reader = "READER";

    public static readonly string[] All = { Admin, Supporter, User, Reader };
}
