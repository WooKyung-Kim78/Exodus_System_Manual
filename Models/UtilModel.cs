using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ExodusSystemManual.Models;

/// 모든 쓰기 저장 프로시저의 공통 반환 형태.
public class ResultModel
{
    public int Success { get; set; }
    public string? ReturnMsg { get; set; }
}

[Table("TB_S_SETTING")]
public class SettingItem
{
    [Key]
    public long IDX { get; set; }
    public string CATEGORY { get; set; } = null!;
    public string TYPE { get; set; } = null!;
    public string? VALUE { get; set; }
    public string REG_ID { get; set; } = null!;
    public DateTime REG_DT { get; set; }
    public string? UPT_ID { get; set; }
    public DateTime? UPT_DT { get; set; }
}

[Table("TB_S_MASTER_COMMON_CODE")]
public class CommonCode
{
    [Key]
    public long IDX { get; set; }
    public string CATEGORY { get; set; } = null!;
    public string CODE { get; set; } = null!;
    public string NAME { get; set; } = null!;
    public int ORDER_NUM { get; set; }
    public string IS_DELETED { get; set; } = "N";
    public string REG_ID { get; set; } = null!;
    public DateTime REG_DT { get; set; }
}

[Table("TB_S_UPLOAD_FILE")]
public class UploadFile
{
    [Key]
    public long IDX { get; set; }
    public string F_TB_NAME { get; set; } = null!;
    public string F_CODE { get; set; } = null!;
    public string FILE_NAME { get; set; } = null!;
    public string PATH { get; set; } = null!;
    public string WEB_PATH { get; set; } = null!;
    public string? CONTENT_TYPE { get; set; }
    public long SIZE { get; set; }
    public string IS_DELETED { get; set; } = "N";
    public string REG_ID { get; set; } = null!;
    public DateTime REG_DT { get; set; }
}

[Table("TB_S_MAIL_LOG")]
public class MailLog
{
    [Key]
    public long IDX { get; set; }
    public string? M_ID { get; set; }
    public string MAIL_TYPE { get; set; } = null!;
    public string TO_LIST { get; set; } = null!;
    public string? CC_LIST { get; set; }
    public string SUBJECT { get; set; } = null!;
    public string IS_SUCCESS { get; set; } = "N";
    public string? ERROR_MSG { get; set; }
    public string REG_ID { get; set; } = null!;
    public DateTime REG_DT { get; set; }
}
