namespace ExodusSystemManual.Models;

public class TeamItem
{
    public string DIVISION { get; set; } = null!;
    public string TEAM { get; set; } = null!;
    public int CNT { get; set; }
}

public class UserSearchItem
{
    public string USER_ID { get; set; } = null!;
    public string FULL_NAME { get; set; } = null!;
    public string? EMAIL { get; set; }
    public string? DIVISION { get; set; }
    public string? TEAM { get; set; }
}
