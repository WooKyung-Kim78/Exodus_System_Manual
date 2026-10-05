using System.Globalization;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;
using ExodusSystemManual.Data;
using ExodusSystemManual.Models;
using Microsoft.EntityFrameworkCore;

namespace ExodusSystemManual.Utils;

/// exodus_datasheet 에서 발행된 datasheet 목록과 사양(category 머리말/꼬리말 + parameter)을 읽어
/// System Manual 의 SPECIFICATIONS 목차에 그릴 HTML 을 만든다. 저장하지 않고 볼 때마다 읽는다.
public class DatasheetSpec
{
    /// 생성한 사양 블록의 표식. 예전 동기화가 남긴 블록을 가려내는 데도 쓴다.
    public const string BlockMarker = "ds-spec-block";

    /// 이 단어가 들어간 목차에 datasheet 사양을 그린다.
    private const string SpecSectionKeyword = "SPECIFICATION";

    /// datasheet 프리뷰에서 Pin/Function/Description 으로 그리는 카테고리 (datasheet 의 constants.js 와 동일).
    private static readonly HashSet<string> PinCategories = new(StringComparer.OrdinalIgnoreCase)
    {
        "D-SUB CONNECTOR PIN ASSIGNMENT",
        "CONNECTOR PIN ASSIGNMENT",
        "PIN ASSIGNMENT",
        "OPTION ORDERING INFORMATION",
    };

    private readonly DatasheetDbContext _db;

    public DatasheetSpec(DatasheetDbContext db) => _db = db;

    /// 발행된 datasheet 를 NAME 기준으로 한 건씩(가장 최근 발행본) 돌려준다.
    public List<DatasheetOption> GetPublishedOptions()
        => _db.USP_DS_SELECT_MAIN_PUBLISHED
            .FromSqlRaw("EXECUTE dbo.USP_DS_SELECT_MAIN_PUBLISHED")
            .AsEnumerable()
            .Where(d => !string.IsNullOrWhiteSpace(d.NAME))
            .GroupBy(d => d.NAME!.Trim(), StringComparer.OrdinalIgnoreCase)
            .Select(g => g.OrderByDescending(d => d.PUBLISHED_DATE ?? DateTime.MinValue).First())
            .Select(d => new DatasheetOption
            {
                D_ID = d.PROCESS_ID,
                NAME = d.NAME!.Trim(),
                TITLE = d.TITLE,
                DS_VERSION = d.DS_VERSION,
                PUBLISHED_DATE = d.PUBLISHED_DATE,
            })
            .OrderBy(o => o.NAME, StringComparer.OrdinalIgnoreCase)
            .ToList();

    /// SPECIFICATIONS 목차인지 판단한다. 미리보기·편집기가 같은 기준을 써야 한다.
    public static bool IsSpecSection(string? title)
        => !string.IsNullOrWhiteSpace(title)
           && title.Contains(SpecSectionKeyword, StringComparison.OrdinalIgnoreCase);

    /// PROCESS_ID(= TB_DS_DOCUMENT.D_ID) 로 datasheet 사양을 가져온다.
    public DatasheetSpecResult? GetSpecById(string? processId)
    {
        if (string.IsNullOrWhiteSpace(processId)) return null;

        var id = processId.Trim();
        var option = GetPublishedOptions()
                         .FirstOrDefault(o => string.Equals(o.D_ID, id, StringComparison.OrdinalIgnoreCase))
                     ?? new DatasheetOption { D_ID = id, NAME = id };

        return BuildResult(option);
    }

    /// datasheet 프리뷰(workspace/preview.js)와 같은 규칙으로 category → 파라미터 → 밴드별 셀을 묶는다.
    private DatasheetSpecResult BuildResult(DatasheetOption option)
    {
        var rows = _db.USP_DS_SELECT_DATASHEET_DETAIL
            .FromSqlRaw("EXECUTE dbo.USP_DS_SELECT_DATASHEET_DETAIL {0}", option.D_ID)
            .AsEnumerable()
            .ToList();

        var header = _db.USP_DS_SELECT_DATASHEET
            .FromSqlRaw("EXECUTE dbo.USP_DS_SELECT_DATASHEET {0}", option.D_ID)
            .AsEnumerable()
            .FirstOrDefault();

        var bandNum = header?.BAND_NUM is > 0 ? header.BAND_NUM.Value : 1;
        var result = new DatasheetSpecResult
        {
            Datasheet = option,
            BandNum = bandNum,
            BandNames = string.IsNullOrEmpty(header?.BAND_NAME)
                ? new List<string> { string.Empty }
                : header.BAND_NAME.Split("||").ToList(),
        };

        var byName = new Dictionary<string, DatasheetSpecCategory>();

        foreach (var r in rows)
        {
            if (!byName.TryGetValue(r.CATEGORY, out var category))
            {
                category = new DatasheetSpecCategory
                {
                    CATEGORY = r.CATEGORY,
                    IS_PIN = PinCategories.Contains(r.CATEGORY),
                };
                byName[r.CATEGORY] = category;
                result.Categories.Add(category);
            }

            switch (r.TYPE)
            {
                case "BODY":
                    category.ROWS.Add(new DatasheetSpecRow
                    {
                        DMP_ID = r.DMP_ID, PIN = r.PIN, PARAMETER = r.PARAMETER, PARA_E_FLAG = r.PARA_E_FLAG,
                        SPECS = Enumerable.Range(0, bandNum).Select(_ => new DatasheetSpecValue(string.Empty, "N")).ToList(),
                        NOTES = Enumerable.Range(0, bandNum).Select(_ => new DatasheetSpecValue(string.Empty, "N")).ToList(),
                    });
                    break;

                case "BODY_SPEC":
                case "BODY_NOTI":
                    var row = category.ROWS.FirstOrDefault(x => x.DMP_ID == r.DMP_ID);
                    if (row is null)
                    {
                        row = new DatasheetSpecRow
                        {
                            DMP_ID = r.DMP_ID, PIN = r.PIN, PARAMETER = r.PARAMETER, PARA_E_FLAG = r.PARA_E_FLAG,
                        };
                        category.ROWS.Add(row);
                    }

                    if (r.TYPE == "BODY_NOTI") row.NOTES.Add(new DatasheetSpecValue(r.NOTI, r.NOTI_E_FLAG));
                    else row.SPECS.Add(new DatasheetSpecValue(r.SPEC, r.SPEC_E_FLAG));
                    break;

                case "HEADER":
                    category.HEADER = r.SPEC;
                    category.TITLE_1 = r.TITLE_1;
                    category.TITLE_2 = r.TITLE_2;
                    break;

                case "FOOTER":
                    category.FOOTER = r.SPEC;
                    break;
            }
        }

        return result;
    }

    /// datasheet 프리뷰의 category 제목 · 사양표 · 꼬리말 구조를 그대로 옮긴다.
    /// 모양은 wwwroot/css/ds-spec.css 가 맞춘다.
    public static string BuildHtml(DatasheetSpecResult spec, bool markCategories = false)
    {
        var sb = new StringBuilder();
        sb.Append("<div class=\"").Append(BlockMarker).Append("\">");

        for (var i = 0; i < spec.Categories.Count; i++)
        {
            var category = spec.Categories[i];
            sb.Append("<div class=\"ds-spec-group\">");

            sb.Append("<div class=\"ds-spec-cat\">");
            if (markCategories) sb.Append(PdfTocMarks.Html(PdfTocMarks.CategoryKey(i)));
            sb.Append("<b class=\"ds-spec-cat-name\">").Append(WebUtility.HtmlEncode(category.CATEGORY)).Append("</b>");
            if (!string.IsNullOrEmpty(category.HEADER))
            {
                sb.Append("<span class=\"ds-spec-sep\"> : </span>")
                  .Append("<span class=\"ds-spec-head\">").Append(category.HEADER).Append("</span>");
            }
            sb.Append("</div>");

            sb.Append("<table class=\"ds-spec-table\">");
            AppendColGroup(sb, category, spec.BandNum);
            AppendHead(sb, category, spec);

            sb.Append("<tbody>");
            foreach (var row in category.ROWS)
                AppendRow(sb, category, row, spec.BandNum);
            sb.Append("</tbody></table>");

            if (!string.IsNullOrEmpty(category.FOOTER))
                sb.Append("<div class=\"ds-spec-foot\">").Append(category.FOOTER).Append("</div>");

            sb.Append("</div>");
        }

        sb.Append("</div>");
        return sb.ToString();
    }

    private static void AppendColGroup(StringBuilder sb, DatasheetSpecCategory category, int bandNum)
    {
        sb.Append("<colgroup>");
        if (category.IS_PIN)
        {
            sb.Append("<col style=\"width:7%\" /><col style=\"width:25.3%\" /><col style=\"width:60%\" />");
        }
        else
        {
            var width = (65m / (bandNum * 2)).ToString("0.####", CultureInfo.InvariantCulture);
            sb.Append("<col style=\"width:35%\" />");
            for (var i = 0; i < bandNum * 2; i++)
                sb.Append("<col style=\"width:").Append(width).Append("%\" />");
        }
        sb.Append("</colgroup>");
    }

    private static void AppendHead(StringBuilder sb, DatasheetSpecCategory category, DatasheetSpecResult spec)
    {
        sb.Append("<thead><tr>");

        if (category.IS_PIN)
        {
            sb.Append("<th><div class=\"ds-cell\">Pin</div></th>");
            AppendTh(sb, Fallback(category.TITLE_1, "Function"), 1, 1);
            AppendTh(sb, Fallback(category.TITLE_2, "Description"), spec.BandNum, 1);
            sb.Append("</tr>");
        }
        else
        {
            AppendTh(sb, "Parameter", 1, spec.BandNames.Count);
            AppendTh(sb, Fallback(category.TITLE_1, "Specification"), spec.BandNum, 1);
            AppendTh(sb, Fallback(category.TITLE_2, "Notes"), spec.BandNum, 1);
            sb.Append("</tr>");

            if (spec.BandNames.Count > 1)
            {
                sb.Append("<tr>");
                foreach (var band in spec.BandNames) sb.Append("<th>").Append(WebUtility.HtmlEncode(band)).Append("</th>");
                foreach (var band in spec.BandNames) sb.Append("<th>").Append(WebUtility.HtmlEncode(band)).Append("</th>");
                sb.Append("</tr>");
            }
        }

        sb.Append("</thead>");
    }

    private static void AppendTh(StringBuilder sb, string text, int colspan, int rowspan)
    {
        sb.Append("<th");
        if (colspan > 1) sb.Append(" colspan=\"").Append(colspan).Append('"');
        if (rowspan > 1) sb.Append(" rowspan=\"").Append(rowspan).Append('"');
        sb.Append("><div class=\"ds-cell\">").Append(WebUtility.HtmlEncode(text)).Append("</div></th>");
    }

    /// 셀이 밴드 수보다 적으면 남은 폭을 colspan 으로 채운다. (datasheet: BAND_NUM - length + 1)
    private static void AppendRow(StringBuilder sb, DatasheetSpecCategory category, DatasheetSpecRow row, int bandNum)
    {
        sb.Append("<tr>");

        if (category.IS_PIN)
            sb.Append("<td><div class=\"ds-cell ds-center\">").Append(WebUtility.HtmlEncode(row.PIN)).Append("</div></td>");

        sb.Append("<td>");
        if (row.PARA_E_FLAG == "Y")
            sb.Append("<div class=\"ds-cell\">").Append(row.PARAMETER).Append("</div>");
        else
            sb.Append("<div class=\"ds-cell").Append(category.IS_PIN ? " ds-center" : "").Append("\">")
              .Append(WebUtility.HtmlEncode(row.PARAMETER)).Append("</div>");
        sb.Append("</td>");

        foreach (var value in row.SPECS)
        {
            AppendTdOpen(sb, bandNum - row.SPECS.Count + 1);
            if (value.EFlag == "Y")
                sb.Append("<div class=\"").Append(category.IS_PIN ? "ds-cell" : "ds-center").Append("\">").Append(value.Value).Append("</div>");
            else
                sb.Append("<div class=\"ds-cell").Append(category.IS_PIN ? "" : " ds-center").Append("\">")
                  .Append(WebUtility.HtmlEncode(value.Value)).Append("</div>");
            sb.Append("</td>");
        }

        if (!category.IS_PIN)
        {
            foreach (var value in row.NOTES)
            {
                AppendTdOpen(sb, bandNum - row.NOTES.Count + 1);
                if (value.EFlag == "Y")
                    sb.Append("<div class=\"ds-center\">").Append(value.Value).Append("</div>");
                else
                    sb.Append("<div class=\"ds-cell ds-center\">").Append(WebUtility.HtmlEncode(value.Value)).Append("</div>");
                sb.Append("</td>");
            }
        }

        sb.Append("</tr>");
    }

    private static void AppendTdOpen(StringBuilder sb, int colspan)
    {
        sb.Append("<td");
        if (colspan > 1) sb.Append(" colspan=\"").Append(colspan).Append('"');
        sb.Append('>');
    }

    private static string Fallback(string? value, string fallback)
        => string.IsNullOrWhiteSpace(value) ? fallback : value;

    private static readonly Regex Tags = new("<[^>]*>", RegexOptions.Compiled);
    private static readonly Regex Spaces = new(@"\s+", RegexOptions.Compiled);

    /// 목차에 쓸 "CATEGORY: 머리말" 평문.
    public static string TocTitle(DatasheetSpecCategory category)
    {
        var head = string.IsNullOrEmpty(category.HEADER)
            ? string.Empty
            : Spaces.Replace(WebUtility.HtmlDecode(Tags.Replace(category.HEADER, " ")), " ").Trim();
        return head.Length == 0 ? category.CATEGORY : $"{category.CATEGORY}: {head}";
    }
}
