using System.Text.Json;

namespace ExodusSystemManual.Models;

public class HeadingStyle
{
    public int Size { get; set; } = 14;
    public string Color { get; set; } = "#181c32";
    public bool Bold { get; set; } = true;
    public bool Underline { get; set; }

    public string ToCss() =>
        $"font-size:{Size}pt;color:{Color};" +
        $"font-weight:{(Bold ? "700" : "400")};" +
        $"text-decoration:{(Underline ? "underline" : "none")};";

    /// 대/중/소제목 기본 스타일. 화면(detail.js, editor.js)도 ClientDefaults() 로 이 값을 받아 쓴다.
    public static Dictionary<int, HeadingStyle> Defaults() => new()
    {
        [1] = new() { Size = 13, Bold = true },
        [2] = new() { Size = 13, Bold = true },
        [3] = new() { Size = 13, Bold = true, Color = "#3f4254" },
    };

    /// JS 가 쓰는 소문자 키 형식. (HEADING_STYLE_JSON 에 저장되는 형식과 같다)
    public static Dictionary<int, object> ClientDefaults()
        => Defaults().ToDictionary(kv => kv.Key, kv => (object)new
        {
            size = kv.Value.Size,
            color = kv.Value.Color,
            bold = kv.Value.Bold,
            underline = kv.Value.Underline,
        });
}

/// 공통 스타일 위에 목차별 값만 덮어쓰기 위해 모든 항목이 nullable 이다.
public class HeadingStyleOverride
{
    public int? Size { get; set; }
    public string? Color { get; set; }
    public bool? Bold { get; set; }
    public bool? Underline { get; set; }

    public HeadingStyle ApplyTo(HeadingStyle baseStyle) => new()
    {
        Size = Size ?? baseStyle.Size,
        Color = string.IsNullOrWhiteSpace(Color) ? baseStyle.Color : Color,
        Bold = Bold ?? baseStyle.Bold,
        Underline = Underline ?? baseStyle.Underline,
    };
}

/// 제목 가로 정렬. 크기·색·굵기·밑줄과 달리 목차마다 직접 가지는 값이다.
public static class TitleAligns
{
    public const string Default = "LEFT";

    public static string CssOf(string? code) => (code ?? Default).ToUpperInvariant() switch
    {
        "CENTER" => "center",
        "RIGHT" => "right",
        _ => "left",
    };
}

/// 본문 글꼴은 문서 전체가 하나로 통일된다.
public static class BodyFonts
{
    private static readonly Dictionary<string, string> Stacks = new()
    {
        ["ARIAL"]   = "Arial, Helvetica, sans-serif",
        ["CARLITO"] = "Carlito, 'Malgun Gothic', sans-serif",
        ["VERDANA"] = "Verdana, Geneva, sans-serif",
        ["TAHOMA"]  = "Tahoma, Geneva, sans-serif",
        ["GEORGIA"] = "Georgia, 'Times New Roman', serif",
        ["TIMES"]   = "'Times New Roman', Times, serif",
    };

    // 예전 코드(CALIBRI)나 모르는 값은 기본 글꼴로 그린다.
    public const string Default = "CARLITO";

    public static string StackOf(string? code)
        => Stacks.TryGetValue(code ?? Default, out var stack) ? stack : Stacks[Default];
}

public class PreviewViewModel
{
    public ManualHeader Header { get; set; } = null!;
    public List<SectionItem> Sections { get; set; } = new();
    public Dictionary<long, List<ElementItem>> Blocks { get; set; } = new();
    public Dictionary<int, HeadingStyle> HeadingStyles { get; set; } = new();

    /// SPECIFICATIONS 목차와 그 자리에 그릴 datasheet 사양. 저장된 내용이 아니라 만들 때마다 읽는다.
    public long? SpecSecId { get; set; }
    public string? SpecHtml { get; set; }
    public string? SpecHtmlMarked { get; set; }
    public List<string> SpecCategories { get; set; } = new();

    /// PDF 1차 생성에서만 켠다. 제목·category 마다 쪽 번호를 찾을 표식을 찍는다.
    public bool EmitTocMarks { get; set; }
    public Dictionary<string, int>? TocPages { get; set; }

    public string TocPageOf(string key)
        => TocPages is not null && TocPages.TryGetValue(key, out var page) ? page.ToString() : string.Empty;

    /// 표지 상단 고정 문구와 로고. 관리자가 공통 코드(COVER)에서 바꾼다.
    public string CoverTitle1 { get; set; } = string.Empty;
    public string CoverTitle2 { get; set; } = string.Empty;
    public string? CoverLogoPath { get; set; }

    /// OEM 문서는 표지·목차 페이지 없이 첫 장 상단에 "<Model> Manual Data" 만 찍는다.
    public bool IsOem => Header.LABEL == "OEM";
    public string OemFooterText { get; set; } = string.Empty;

    /// 인쇄 영역 폭(mm). Letter 216 / A4 210 에서 좌우 여백을 뺀 값.
    public int ContentWidthMm => Header.PAGE_SIZE == "A4" ? 170 : 176;
    public string BodyFontStack => BodyFonts.StackOf(Header.BODY_FONT);
    /// 본문 글자 크기(pt). DB 는 10 으로 고정해 저장한다. (USP_S_UPDATE_DOC_STYLE)
    public int BodyFontSize => Header.BODY_FONT_SIZE is > 0 ? Header.BODY_FONT_SIZE.Value : 12;
    public decimal BodyLineHeight => Header.BODY_LINE_HEIGHT ?? 1.2m;
    public decimal BodyLetterSpacing => Header.BODY_LETTER_SPACING ?? 0m;
    public string FileName
    {
        get
        {
            var raw = $"{Header.MODEL_NAME}_{Header.JOB_NUMBER}_Rev{Header.REVISION}";
            foreach (var c in Path.GetInvalidFileNameChars()) raw = raw.Replace(c, '_');
            return raw + ".pdf";
        }
    }

    public HeadingStyle StyleOf(int level)
        => HeadingStyles.TryGetValue(level, out var s) ? s : new HeadingStyle();

    public HeadingStyle StyleOf(SectionItem section)
    {
        var common = StyleOf(section.SEC_LEVEL);
        var style = common;

        if (!string.IsNullOrWhiteSpace(section.STYLE_JSON))
        {
            try
            {
                var over = JsonSerializer.Deserialize<HeadingStyleOverride>(
                    section.STYLE_JSON, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                style = over?.ApplyTo(common) ?? common;
            }
            catch (JsonException)
            {
                style = common;
            }
        }

        // 밑줄 스위치는 개별 스타일과 별개다. 공통 스타일 객체는 공유되므로 복사해서 바꿈다.
        if (section.TITLE_UNDERLINE == "Y" && !style.Underline)
            style = new HeadingStyle { Size = style.Size, Color = style.Color, Bold = style.Bold, Underline = true };

        return style;
    }

    public static Dictionary<int, HeadingStyle> ParseStyles(string? json)
    {
        var defaults = HeadingStyle.Defaults();

        if (string.IsNullOrWhiteSpace(json)) return defaults;

        try
        {
            var parsed = JsonSerializer.Deserialize<Dictionary<string, HeadingStyle>>(
                json, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

            if (parsed is null) return defaults;

            foreach (var (key, value) in parsed)
                if (int.TryParse(key, out var level) && value is not null)
                    defaults[level] = value;
        }
        catch (JsonException)
        {
            // 저장된 값이 깨졌으면 기본 스타일로 보여준다.
        }

        return defaults;
    }
}
