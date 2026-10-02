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
    public string? CONTENT_HTML { get; set; }

    /// 제목 가로 정렬. LEFT / CENTER / RIGHT.
    public string TITLE_ALIGN { get; set; } = "LEFT";

    /// NORMAL 은 보통 목차, PAGEBREAK 는 제목·내용 없이 페이지만 끊는 목차.
    public string SEC_TYPE { get; set; } = "NORMAL";

    /// N 이면 PDF 앞쪽 목차 페이지에만 안 보인다. 본문에는 나온다.
    public string SHOW_IN_TOC { get; set; } = "Y";

    public string TITLE_UNDERLINE { get; set; } = "N";

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
    public string TITLE_ALIGN { get; set; } = "LEFT";
    public string SEC_TYPE { get; set; } = "NORMAL";

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

    public string? CONTENT_HTML { get; set; }

    [RegularExpression("^(LEFT|CENTER|RIGHT)$", ErrorMessage = "가로 정렬 값이 올바르지 않습니다.")]
    public string TITLE_ALIGN { get; set; } = "LEFT";

    [RegularExpression("^(NORMAL|PAGEBREAK)$", ErrorMessage = "목차 종류 값이 올바르지 않습니다.")]
    public string SEC_TYPE { get; set; } = "NORMAL";

    [RegularExpression("^(Y|N)$", ErrorMessage = "목차 표시 값이 올바르지 않습니다.")]
    public string SHOW_IN_TOC { get; set; } = "Y";

    [RegularExpression("^(Y|N)$", ErrorMessage = "제목 밑줄 값이 올바르지 않습니다.")]
    public string TITLE_UNDERLINE { get; set; } = "N";

    public int? ORDER_NUM { get; set; }
}

public class UserAdminItem
{
    public long IDX { get; set; }
    public string USER_ID { get; set; } = null!;
    public string FULL_NAME { get; set; } = null!;
    public string? EMAIL { get; set; }
    public string? DIVISION { get; set; }
    public string? TEAM { get; set; }
    public string AUTHORIZED { get; set; } = "S";
    public string IS_DELETED { get; set; } = "N";
    public string? SUPERVISOR_USER_ID { get; set; }
    public string? SUPERVISOR_NAME { get; set; }
    public string ROLE_NAME { get; set; } = null!;
    public DateTime? REG_DT { get; set; }
    public DateTime? UPT_DT { get; set; }
}

public class InputUserAccount
{
    /// 신규 등록 여부를 화면이 아니라 서버가 판단하도록 아이디만 받는다.
    [Required(ErrorMessage = "아이디는 필수입니다.")]
    [RegularExpression("^[0-9a-zA-Z._-]{4,20}$", ErrorMessage = "아이디는 영문·숫자 4~20자로 입력하세요.")]
    public string USER_ID { get; set; } = null!;

    [Required(ErrorMessage = "이름은 필수입니다.")]
    [StringLength(100, ErrorMessage = "이름은 100자 이내로 입력하세요.")]
    public string FULL_NAME { get; set; } = null!;

    [EmailAddress(ErrorMessage = "이메일 형식이 올바르지 않습니다.")]
    [StringLength(100, ErrorMessage = "이메일은 100자 이내로 입력하세요.")]
    public string? EMAIL { get; set; }

    [StringLength(100, ErrorMessage = "본부는 100자 이내로 입력하세요.")]
    public string? DIVISION { get; set; }

    [StringLength(100, ErrorMessage = "팀은 100자 이내로 입력하세요.")]
    public string? TEAM { get; set; }

    [StringLength(20)]
    public string? SUPERVISOR_USER_ID { get; set; }

    [Required]
    [RegularExpression("^(ADMIN|USER|READER)$", ErrorMessage = "역할 값이 올바르지 않습니다.")]
    public string ROLE_NAME { get; set; } = "USER";

    [Required]
    [RegularExpression("^(Y|S|N)$", ErrorMessage = "계정 상태 값이 올바르지 않습니다.")]
    public string AUTHORIZED { get; set; } = "Y";

    /// 신규 등록일 때만 쓰는 초기 비밀번호.
    public string? N_PASSWORD { get; set; }
}

public class InputUserPassword
{
    [Required]
    [StringLength(20)]
    public string USER_ID { get; set; } = null!;

    [Required(ErrorMessage = "새 비밀번호를 입력하세요.")]
    public string N_PASSWORD { get; set; } = null!;
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

public class TableParamItem
{
    public long IDX { get; set; }
    public string TITLE { get; set; } = null!;
    public string FUNC_HTML { get; set; } = null!;
    public int ORDER_NUM { get; set; }
    public DateTime? REG_DT { get; set; }
    public DateTime? UPT_DT { get; set; }
}

public class InputTableParam
{
    public long? IDX { get; set; }

    [Required(ErrorMessage = "Title은 필수입니다.")]
    [StringLength(200, ErrorMessage = "Title은 200자 이내로 입력하세요.")]
    public string TITLE { get; set; } = null!;

    [Required(ErrorMessage = "Function은 필수입니다.")]
    [StringLength(20000, ErrorMessage = "Function 내용이 너무 깁니다.")]
    public string FUNC_HTML { get; set; } = null!;

    [Range(0, 999, ErrorMessage = "순서는 0 ~ 999 사이로 입력하세요.")]
    public int ORDER_NUM { get; set; }
}
