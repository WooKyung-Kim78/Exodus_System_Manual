using System.ComponentModel.DataAnnotations;

namespace ExodusSystemManual.Models;

public class ElementItem
{
    public long ELE_ID { get; set; }
    public string M_ID { get; set; } = null!;
    public long SEC_ID { get; set; }
    public string ELE_TYPE { get; set; } = null!;
    public int ORDER_NUM { get; set; }
    public double WIDTH { get; set; }
    public double HEIGHT { get; set; }
    public string? CONTENT_HTML { get; set; }
    public string? IMAGE_PATH { get; set; }
    public string? CAPTION { get; set; }
    public string? STYLE_JSON { get; set; }
    public byte[]? ROW_VER { get; set; }
    public string? UPT_ID { get; set; }
    public DateTime UPT_DT { get; set; }
}

public class InputElement
{
    public long? ELE_ID { get; set; }

    [Required]
    [StringLength(10)]
    public string M_ID { get; set; } = null!;

    [Required]
    public long SEC_ID { get; set; }

    [Required]
    [RegularExpression("^(TEXT|IMAGE|TABLE)$", ErrorMessage = "블록 타입이 올바르지 않습니다.")]
    public string ELE_TYPE { get; set; } = null!;

    public int ORDER_NUM { get; set; }
    public double WIDTH { get; set; }
    public double HEIGHT { get; set; }

    public string? CONTENT_HTML { get; set; }

    [StringLength(500)]
    public string? IMAGE_PATH { get; set; }

    [StringLength(500)]
    public string? CAPTION { get; set; }

    public string? STYLE_JSON { get; set; }

    /// base64 로 직렬화된 rowversion. 신규 생성 시에는 비어 있다.
    public string? ROW_VER { get; set; }
}

public class InputOrderBatch
{
    [Required]
    [StringLength(10)]
    public string M_ID { get; set; } = null!;

    /// 'ELE_ID:ORDER_NUM' 을 콤마로 이은 문자열
    [Required]
    public string ORDERS { get; set; } = null!;
}
