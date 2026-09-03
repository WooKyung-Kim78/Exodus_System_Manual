using System.ComponentModel.DataAnnotations;

namespace ExodusSystemManual.Models;

/* ---------- 저장 프로시저 결과 (키 없음) ---------- */

public class ManualListItem
{
    public string M_ID { get; set; } = null!;
    public string? DOC_NUM { get; set; }
    public string? JOB_NUMBER { get; set; }
    public string MODEL_NAME { get; set; } = null!;
    public string? LABEL { get; set; }
    public string? COOLING { get; set; }
    public string? OPTION_TEXT { get; set; }
    public string REVISION { get; set; } = null!;
    public string STATUS { get; set; } = null!;
    public string REQUESTER_ID { get; set; } = null!;
    public string? REQUESTER_NAME { get; set; }
    public string? APPROVER_NAME { get; set; }
    public DateTime? REQUEST_DATE { get; set; }
    public DateTime? PUBLISH_DATE { get; set; }
    public DateTime REG_DT { get; set; }
    public string? MY_ROLE { get; set; }
    public int SECTION_CNT { get; set; }
    public int OPEN_CMT_CNT { get; set; }
}

public class ManualHeader
{
    public string M_ID { get; set; } = null!;
    public string? DOC_NUM { get; set; }
    public string? JOB_NUMBER { get; set; }
    public string MODEL_NAME { get; set; } = null!;
    public string? LABEL { get; set; }
    public string? COOLING { get; set; }
    public string? OPTION_TEXT { get; set; }
    public string REVISION { get; set; } = null!;
    public string STATUS { get; set; } = null!;
    public string PAGE_SIZE { get; set; } = null!;
    public string PAGE_ORIENTATION { get; set; } = null!;
    public string? HEADING_STYLE_JSON { get; set; }
    public string? COVER_IMAGE_PATH { get; set; }
    public string? BODY_FONT { get; set; }
    public int? BODY_FONT_SIZE { get; set; }
    public decimal? BODY_LINE_HEIGHT { get; set; }
    public decimal? BODY_LETTER_SPACING { get; set; }
    public string REQUESTER_ID { get; set; } = null!;
    public string? REQUESTER_NAME { get; set; }
    public string? APPROVER_ID { get; set; }
    public string? APPROVER_NAME { get; set; }
    public string? ORIGINAL_M_ID { get; set; }
    public DateTime? REQUEST_DATE { get; set; }
    public DateTime? APPROVED_DATE { get; set; }
    public DateTime? PUBLISH_DATE { get; set; }
    public DateTime? OBSOLETE_DATE { get; set; }
    public DateTime REG_DT { get; set; }
    public DateTime? UPT_DT { get; set; }
}

public class ManualMemberItem
{
    public long IDX { get; set; }
    public string M_ID { get; set; } = null!;
    public string USER_ID { get; set; } = null!;
    public string MEMBER_ROLE { get; set; } = null!;
    public string FULL_NAME { get; set; } = null!;
    public string? EMAIL { get; set; }
    public string? DIVISION { get; set; }
    public string? TEAM { get; set; }
}

/* ---------- 입력 모델 ---------- */

public class InputNewManual
{
    [Required(ErrorMessage = "Model Name 은 필수입니다.")]
    [StringLength(100, ErrorMessage = "Model Name 은 100자 이내로 입력하세요.")]
    public string MODEL_NAME { get; set; } = null!;

    [StringLength(50, ErrorMessage = "Job Number 는 50자 이내로 입력하세요.")]
    public string? JOB_NUMBER { get; set; }

    [RegularExpression("^(EXODUS|OEM)?$", ErrorMessage = "Label 은 Exodus 또는 OEM 이어야 합니다.")]
    public string? LABEL { get; set; }

    [RegularExpression("^(AIR|LIQUID)?$", ErrorMessage = "Cooling 은 Air 또는 Liquid 여야 합니다.")]
    public string? COOLING { get; set; }

    [StringLength(500, ErrorMessage = "Option 은 500자 이내로 입력하세요.")]
    public string? OPTION_TEXT { get; set; }

    [RegularExpression("^(LETTER|A4)$", ErrorMessage = "Page Size 값이 올바르지 않습니다.")]
    public string PAGE_SIZE { get; set; } = "LETTER";
}

public class InputManualHeader : InputNewManual
{
    [Required]
    [StringLength(10)]
    public string M_ID { get; set; } = null!;
}
