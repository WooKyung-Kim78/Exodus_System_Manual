namespace ExodusSystemManual.Models;

public class SectionHistoryItem
{
    public long HIS_ID { get; set; }
    public long? SEC_ID { get; set; }
    public long? ELE_ID { get; set; }
    public string ACTION { get; set; } = null!;
    public string? FIELD_NAME { get; set; }
    public string? BEFORE_VALUE { get; set; }
    public string? AFTER_VALUE { get; set; }
    public string REG_ID { get; set; } = null!;
    public string REG_NAME { get; set; } = null!;
    public string? REG_TEAM { get; set; }
    public DateTime REG_DT { get; set; }
}
