using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ExodusSystemManual.Models;

[Table("TB_S_SECTION")]
public class Section
{
    [Key]
    public long SEC_ID { get; set; }
    public string M_ID { get; set; } = null!;
    public int ORDER_NUM { get; set; }
    public string TITLE { get; set; } = null!;
    public int CANVAS_X { get; set; }
    public int CANVAS_Y { get; set; }
    public int BOARD_W { get; set; } = 816;
    public int BOARD_H { get; set; } = 1056;
    public string? ASSIGNED_TEAM { get; set; }
    public string SEC_STATUS { get; set; } = "EMPTY";
    public string IS_DELETED { get; set; } = "N";

    [Timestamp]
    public byte[]? ROW_VER { get; set; }

    public string REG_ID { get; set; } = null!;
    public DateTime REG_DT { get; set; }
    public string? UPT_ID { get; set; }
    public DateTime? UPT_DT { get; set; }
}

[Table("TB_S_ELEMENT")]
public class CanvasElement
{
    [Key]
    public long ELE_ID { get; set; }
    public string M_ID { get; set; } = null!;
    public long SEC_ID { get; set; }
    public string ELE_TYPE { get; set; } = "TEXT";
    public double POS_X { get; set; }
    public double POS_Y { get; set; }
    public double WIDTH { get; set; }
    public double HEIGHT { get; set; }
    public double ROTATION { get; set; }
    public int Z_INDEX { get; set; }
    public string? GROUP_ID { get; set; }

    /// CKEditor5 원본. 저장 전 반드시 HtmlSanitizer 를 통과시킨다.
    public string? CONTENT_HTML { get; set; }

    public string? IMAGE_PATH { get; set; }
    public string? CAPTION { get; set; }
    public string? STYLE_JSON { get; set; }
    public string IS_DELETED { get; set; } = "N";

    [Timestamp]
    public byte[]? ROW_VER { get; set; }

    public string REG_ID { get; set; } = null!;
    public DateTime REG_DT { get; set; }
    public string? UPT_ID { get; set; }
    public DateTime UPT_DT { get; set; }
}

[Table("TB_S_ELEMENT_TABLE_ROW")]
public class ElementTableRow
{
    [Key]
    public long ROW_ID { get; set; }
    public long ELE_ID { get; set; }
    public int ORDER_NUM { get; set; }
    public string? ITEM { get; set; }
    public string? SPEC { get; set; }
    public string? UNIT { get; set; }
    public string? MIN_VAL { get; set; }
    public string? TYP_VAL { get; set; }
    public string? MAX_VAL { get; set; }
    public string? REMARK { get; set; }
    public string IS_DELETED { get; set; } = "N";
}

[Table("TB_S_ELEMENT_HISTORY")]
public class ElementHistory
{
    [Key]
    public long HIS_ID { get; set; }
    public string M_ID { get; set; } = null!;
    public long? SEC_ID { get; set; }
    public long? ELE_ID { get; set; }
    public string ACTION { get; set; } = null!;
    public string? FIELD_NAME { get; set; }
    public string? BEFORE_VALUE { get; set; }
    public string? AFTER_VALUE { get; set; }
    public string REG_ID { get; set; } = null!;
    public DateTime REG_DT { get; set; }
}

[Table("TB_S_COMMENT")]
public class Comment
{
    [Key]
    public long CMT_ID { get; set; }
    public string M_ID { get; set; } = null!;
    public long? SEC_ID { get; set; }
    public long? ELE_ID { get; set; }
    public double? PIN_X { get; set; }
    public double? PIN_Y { get; set; }
    public long? PARENT_CMT_ID { get; set; }
    public string BODY { get; set; } = null!;
    public string IS_RESOLVED { get; set; } = "N";
    public string IS_DELETED { get; set; } = "N";
    public string REG_ID { get; set; } = null!;
    public DateTime REG_DT { get; set; }
}

[Table("TB_S_PRESENCE")]
public class Presence
{
    public string M_ID { get; set; } = null!;
    public string CLIENT_ID { get; set; } = null!;
    public string USER_ID { get; set; } = null!;
    public long? SEC_ID { get; set; }
    public long? EDITING_ELE_ID { get; set; }
    public DateTime LAST_PING_DT { get; set; }
}
