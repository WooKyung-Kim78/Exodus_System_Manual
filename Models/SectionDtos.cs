using System.ComponentModel.DataAnnotations;

namespace ExodusSystemManual.Models;

public class SectionItem
{
    public long SEC_ID { get; set; }
    public string M_ID { get; set; } = null!;
    public int ORDER_NUM { get; set; }

    /// 1=대제목, 2=중제목, 3=소제목
    public int SEC_LEVEL { get; set; } = 1;

    public string? SEC_NO { get; set; }
    public string TITLE { get; set; } = null!;

    /// NULL 이면 문서 공통 스타일을 따른다.
    public string? STYLE_JSON { get; set; }

    /// 템플릿에서 온 목차면 원본 TPL_ID.
    public long? TPL_ID { get; set; }

    public string? ASSIGNED_TEAM { get; set; }

    /// 마지막으로 이 목차를 손대사람.
    public string? EDITOR_NAME { get; set; }

    /// 요청한 사용자가 이 목차의 내용을 고칠 수 있는지.
    public string CAN_EDIT_SEC { get; set; } = "N";

    public string SEC_STATUS { get; set; } = null!;
    public int BLOCK_CNT { get; set; }
    public int OPEN_CMT_CNT { get; set; }
    public DateTime? UPT_DT { get; set; }
}

public class InputSection
{
    public long? SEC_ID { get; set; }

    [Required]
    [StringLength(10)]
    public string M_ID { get; set; } = null!;

    [Required(ErrorMessage = "섹션 제목은 필수입니다.")]
    [StringLength(200, ErrorMessage = "섹션 제목은 200자 이내로 입력하세요.")]
    public string TITLE { get; set; } = null!;

    [Range(1, 3, ErrorMessage = "제목 단계는 1~3 입니다.")]
    public int SEC_LEVEL { get; set; } = 1;

    [StringLength(20, ErrorMessage = "번호는 20자 이내로 입력하세요.")]
    public string? SEC_NO { get; set; }

    [StringLength(100)]
    public string? ASSIGNED_TEAM { get; set; }

    [RegularExpression("^(EMPTY|WRITING|DONE)$", ErrorMessage = "섹션 상태 값이 올바르지 않습니다.")]
    public string? SEC_STATUS { get; set; }

    [StringLength(2000, ErrorMessage = "제목 스타일 값이 너무 깁니다.")]
    public string? STYLE_JSON { get; set; }
}
