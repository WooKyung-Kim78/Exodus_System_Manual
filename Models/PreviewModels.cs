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

/// 본문 글꼴은 문서 전체가 하나로 통일된다.
public static class BodyFonts
{
    private static readonly Dictionary<string, string> Stacks = new()
    {
        ["ARIAL"]   = "Arial, Helvetica, sans-serif",
        ["CALIBRI"] = "Calibri, 'Segoe UI', sans-serif",
        ["VERDANA"] = "Verdana, Geneva, sans-serif",
        ["TAHOMA"]  = "Tahoma, Geneva, sans-serif",
        ["GEORGIA"] = "Georgia, 'Times New Roman', serif",
        ["TIMES"]   = "'Times New Roman', Times, serif",
    };

    public const string Default = "ARIAL";

    public static string StackOf(string? code)
        => Stacks.TryGetValue(code ?? Default, out var stack) ? stack : Stacks[Default];
}

public class PreviewViewModel
{
    public ManualHeader Header { get; set; } = null!;
    public List<SectionItem> Sections { get; set; } = new();
    public Dictionary<long, List<ElementItem>> Blocks { get; set; } = new();
    public Dictionary<int, HeadingStyle> HeadingStyles { get; set; } = new();

    /// 표지 상단 고정 문구와 로고. 관리자가 공통 코드(COVER)에서 바꾼다.
    public string CoverTitle1 { get; set; } = string.Empty;
    public string CoverTitle2 { get; set; } = string.Empty;
    public string? CoverLogoPath { get; set; }

    /// 인쇄 영역 폭(mm). Letter 216 / A4 210 에서 좌우 여백을 뺀 값.
    public int ContentWidthMm => Header.PAGE_SIZE == "A4" ? 170 : 176;
    public string BodyFontStack => BodyFonts.StackOf(Header.BODY_FONT);
    public int BodyFontSize => 12;
    public decimal BodyLineHeight => Header.BODY_LINE_HEIGHT ?? 1.0m;
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
        if (string.IsNullOrWhiteSpace(section.STYLE_JSON)) return common;

        try
        {
            var over = JsonSerializer.Deserialize<HeadingStyleOverride>(
                section.STYLE_JSON, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
            return over?.ApplyTo(common) ?? common;
        }
        catch (JsonException)
        {
            return common;
        }
    }

    public static Dictionary<int, HeadingStyle> ParseStyles(string? json)
    {
        var defaults = new Dictionary<int, HeadingStyle>
        {
            [1] = new() { Size = 18, Bold = true },
            [2] = new() { Size = 15, Bold = true },
            [3] = new() { Size = 13, Bold = true, Color = "#3f4254" },
        };

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
