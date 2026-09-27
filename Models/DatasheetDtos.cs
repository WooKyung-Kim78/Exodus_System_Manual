namespace ExodusSystemManual.Models;

/* ---------- exodus_datasheet 저장 프로시저 결과 (키 없음) ---------- */

/// USP_DS_SELECT_MAIN_PUBLISHED 결과. 필요한 열만 매핑한다.
public class DatasheetPublishedItem
{
    public string PROCESS_ID { get; set; } = null!;
    public string? NAME { get; set; }
    public string? TITLE { get; set; }
    public string? DS_VERSION { get; set; }
    public DateTime? PUBLISHED_DATE { get; set; }
}

/// USP_DS_SELECT_DATASHEET_DETAIL 결과. TYPE 은 HEADER/FOOTER/BODY/BODY_SPEC/BODY_NOTI.
public class DatasheetDetailItem
{
    public string DMP_ID { get; set; } = null!;
    public string CATEGORY { get; set; } = null!;
    public string? PARAMETER { get; set; }
    public string? PARA_E_FLAG { get; set; }
    public string? TYPE { get; set; }
    public string? SPEC { get; set; }
    public string? SPEC_E_FLAG { get; set; }
    public string? NOTI { get; set; }
    public string? NOTI_E_FLAG { get; set; }
    public string? PIN { get; set; }
    public int ORDER_NUM { get; set; }
    public string? TITLE_1 { get; set; }
    public string? TITLE_2 { get; set; }
}

/// USP_DS_SELECT_DATASHEET 결과. 표의 밴드(열) 구성만 쓴다.
public class DatasheetHeaderItem
{
    public int? BAND_NUM { get; set; }
    public string? BAND_NAME { get; set; }
}

/* ---------- 화면/동기화용 ---------- */

/// Job Number 선택 목록 한 건.
public class DatasheetOption
{
    public string D_ID { get; set; } = null!;
    public string NAME { get; set; } = null!;
    public string? TITLE { get; set; }
    public string? DS_VERSION { get; set; }
    public DateTime? PUBLISHED_DATE { get; set; }
}

/// 셀 하나. E_FLAG 가 Y 면 값이 HTML 이다.
public record DatasheetSpecValue(string? Value, string? EFlag);

/// datasheet 프리뷰처럼 Specification/Notes 를 밴드별 셀로 들고 있다. 셀이 밴드 수보다 적으면 합쳐 그린다.
public class DatasheetSpecRow
{
    public string DMP_ID { get; set; } = null!;
    public string? PIN { get; set; }
    public string? PARAMETER { get; set; }
    public string? PARA_E_FLAG { get; set; }
    public List<DatasheetSpecValue> SPECS { get; set; } = new();
    public List<DatasheetSpecValue> NOTES { get; set; } = new();
}

public class DatasheetSpecCategory
{
    public string CATEGORY { get; set; } = null!;

    /// Pin 계열 카테고리는 datasheet 프리뷰에서 Pin/Function/Description 으로 그린다.
    public bool IS_PIN { get; set; }

    public string? TITLE_1 { get; set; }
    public string? TITLE_2 { get; set; }

    /// category 이름 옆(HEADER)과 표 바로 아래(FOOTER)에 붙는 HTML.
    public string? HEADER { get; set; }
    public string? FOOTER { get; set; }

    public List<DatasheetSpecRow> ROWS { get; } = new();
}

public class DatasheetSpecResult
{
    public DatasheetOption Datasheet { get; set; } = null!;
    public int BandNum { get; set; } = 1;
    public List<string> BandNames { get; set; } = new() { string.Empty };
    public List<DatasheetSpecCategory> Categories { get; } = new();
}
