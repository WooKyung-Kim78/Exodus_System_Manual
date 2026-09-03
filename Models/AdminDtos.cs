using System.ComponentModel.DataAnnotations;

namespace ExodusSystemManual.Models;

/// 목차 템플릿 한 줄. LABEL/COOLING 이 비어 있으면 모든 조합에 적용된다.
public class SectionTemplateItem
{
    public long TPL_ID { get; set; }
    public string? LABEL { get; set; }
    public string? COOLING { get; set; }
    public int SEC_LEVEL { get; set; } = 1;
    public string? SEC_NO { get; set; }
    public string TITLE { get; set; } = null!;
    public string IS_MANDATORY { get; set; } = "Y";
    public int ORDER_NUM { get; set; }
    public string? ASSIGNED_TEAM { get; set; }
    public DateTime? REG_DT { get; set; }
    public DateTime? UPT_DT { get; set; }
}

/// 프로시저마다 반환 컬럼이 달라 결과 모델을 따로 둔다. 하나로 합치면 EF 매핑이 깨진다.
public class TemplateOptionItem
{
    public long TPL_ID { get; set; }
    public string? LABEL { get; set; }
    public string? COOLING { get; set; }
    public int SEC_LEVEL { get; set; } = 1;
    public string? SEC_NO { get; set; }
    public string TITLE { get; set; } = null!;
    public string IS_MANDATORY { get; set; } = "Y";
    public int ORDER_NUM { get; set; }
    public string? ASSIGNED_TEAM { get; set; }

    /// 이미 문서에 들어가 있는지 여부.
    public string IS_ADDED { get; set; } = "N";
}

public class InputSectionTemplate
{
    public long? TPL_ID { get; set; }

    [RegularExpression("^(EXODUS|OEM)?$", ErrorMessage = "Label 값이 올바르지 않습니다.")]
    public string? LABEL { get; set; }

    [RegularExpression("^(AIR|LIQUID)?$", ErrorMessage = "Cooling 값이 올바르지 않습니다.")]
    public string? COOLING { get; set; }

    [Range(1, 3, ErrorMessage = "제목 단계는 1~3 입니다.")]
    public int SEC_LEVEL { get; set; } = 1;

    [StringLength(20, ErrorMessage = "번호는 20자 이내로 입력하세요.")]
    public string? SEC_NO { get; set; }

    [Required(ErrorMessage = "제목은 필수입니다.")]
    [StringLength(200, ErrorMessage = "제목은 200자 이내로 입력하세요.")]
    public string TITLE { get; set; } = null!;

    [RegularExpression("^(Y|N)$", ErrorMessage = "필수 여부 값이 올바르지 않습니다.")]
    public string IS_MANDATORY { get; set; } = "Y";

    [StringLength(100)]
    public string? ASSIGNED_TEAM { get; set; }

    public int? ORDER_NUM { get; set; }
}

public class UserRoleItem
{
    public string USER_ID { get; set; } = null!;
    public string FULL_NAME { get; set; } = null!;
    public string? DIVISION { get; set; }
    public string? TEAM { get; set; }
    public string? AUTHORIZED { get; set; }
    public string ROLE_NAME { get; set; } = null!;
    public DateTime? UPT_DT { get; set; }
}

public class InputUserRole
{
    [Required]
    [StringLength(20)]
    public string USER_ID { get; set; } = null!;

    [Required]
    [RegularExpression("^(ADMIN|USER|READER)$", ErrorMessage = "역할 값이 올바르지 않습니다.")]
    public string ROLE_NAME { get; set; } = null!;
}

public class CommonCodeItem
{
    public long IDX { get; set; }
    public string CATEGORY { get; set; } = null!;
    public string CODE { get; set; } = null!;
    public string NAME { get; set; } = null!;
    public int ORDER_NUM { get; set; }
    public DateTime? REG_DT { get; set; }
    public DateTime? UPT_DT { get; set; }
}

public class InputCommonCode
{
    public long? IDX { get; set; }

    [Required(ErrorMessage = "분류는 필수입니다.")]
    [RegularExpression("^[A-Z0-9_]{1,50}$", ErrorMessage = "분류는 영문 대문자·숫자·밑줄만 쓸 수 있습니다.")]
    public string CATEGORY { get; set; } = null!;

    [Required(ErrorMessage = "코드는 필수입니다.")]
    [RegularExpression("^[A-Z0-9_]{1,50}$", ErrorMessage = "코드는 영문 대문자·숫자·밑줄만 쓸 수 있습니다.")]
    public string CODE { get; set; } = null!;

    [StringLength(200, ErrorMessage = "값은 200자 이내로 입력하세요.")]
    public string NAME { get; set; } = string.Empty;

    public int ORDER_NUM { get; set; }
}
