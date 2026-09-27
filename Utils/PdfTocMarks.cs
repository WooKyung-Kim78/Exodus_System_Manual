using System.Text.RegularExpressions;
using UglyToad.PdfPig;

namespace ExodusSystemManual.Utils;

/// Chromium 은 목차의 쪽 번호(target-counter)를 지원하지 않는다.
/// 1차 PDF 에 제목마다 보이지 않는 표식을 찍고, 표식이 찍힌 쪽을 읽어 2차 PDF 목차에 채운다.
public static class PdfTocMarks
{
    private const string Open = "QZX";
    private const string Close = "XZQ";
    private static readonly Regex Pattern = new(Open + "([SC][0-9]+)" + Close, RegexOptions.Compiled);

    public static string SectionKey(long secId) => "S" + secId;
    public static string CategoryKey(int index) => "C" + index;

    public static string Html(string key) => $"<span class=\"toc-mark\">{Open}{key}{Close}</span>";

    public static Dictionary<string, int> Read(byte[] pdf)
    {
        var pages = new Dictionary<string, int>();
        using var document = PdfDocument.Open(pdf);

        foreach (var page in document.GetPages())
        {
            var text = string.Concat(page.Letters.Select(l => l.Value));
            foreach (Match m in Pattern.Matches(text))
                pages.TryAdd(m.Groups[1].Value, page.Number);
        }

        return pages;
    }
}
