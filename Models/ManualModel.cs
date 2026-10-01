using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ExodusSystemManual.Models;

[Table("TB_S_MANUAL")]
public class Manual
{
    [Key]
    public string M_ID { get; set; } = null!;
    public string? DOC_NUM { get; set; }
    public string? JOB_NUMBER { get; set; }

    /// 고른 datasheet 의 PROCESS_ID (exodus_datasheet 의 TB_DS_DOCUMENT.D_ID 와 같은 값).
    public string? PROCESS_ID { get; set; }

    public string MODEL_NAME { get; set; } = null!;
    public string? LABEL { get; set; }
    public string? COOLING { get; set; }
    public string? OPTION_TEXT { get; set; }
    public string REVISION { get; set; } = "A";
    public string STATUS { get; set; } = "DRAFT";
    public string PAGE_SIZE { get; set; } = "LETTER";
    public string PAGE_ORIENTATION { get; set; } = "PORTRAIT";
    public string REQUESTER_ID { get; set; } = null!;
    public string? APPROVER_ID { get; set; }
    public string? ORIGINAL_M_ID { get; set; }
    public DateTime? REQUEST_DATE { get; set; }
    public DateTime? APPROVED_DATE { get; set; }
    public DateTime? PUBLISH_DATE { get; set; }
    public DateTime? OBSOLETE_DATE { get; set; }
    public string IS_DELETED { get; set; } = "N";
    public string REG_ID { get; set; } = null!;
    public DateTime REG_DT { get; set; }
    public string? UPT_ID { get; set; }
    public DateTime? UPT_DT { get; set; }
}

/// USP_S_SELECT_MANUAL_ACCESS 결과. 모든 쓰기 API 의 사전 권한 확인에 사용한다.
public class ManualAccess
{
    public string M_ID { get; set; } = null!;
    public string STATUS { get; set; } = null!;
    public string REQUESTER_ID { get; set; } = null!;
    public string? APPROVER_ID { get; set; }
    public string? MEMBER_ROLE { get; set; }
    public string USER_ROLE { get; set; } = "USER";
    public string CAN_EDIT { get; set; } = "N";
    public string CAN_READ { get; set; } = "N";
}
