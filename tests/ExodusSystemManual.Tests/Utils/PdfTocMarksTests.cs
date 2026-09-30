using System.Text;
using ExodusSystemManual.Utils;

namespace ExodusSystemManual.Tests.Utils;

public class PdfTocMarksTests
{
    [Fact]
    public void Read_returns_the_first_page_for_each_valid_marker()
    {
        var pdf = BuildPdf("QZXS12XZQ QZXC0XZQ", "QZXS12XZQ QZXC3XZQ QZXinvalidXZQ");

        var pages = PdfTocMarks.Read(pdf);

        Assert.Equal(1, pages["S12"]);
        Assert.Equal(1, pages["C0"]);
        Assert.Equal(2, pages["C3"]);
        Assert.Equal(3, pages.Count);
    }

    [Fact]
    public void Html_and_key_helpers_create_the_marker_format_read_expects()
    {
        Assert.Equal("S42", PdfTocMarks.SectionKey(42));
        Assert.Equal("C2", PdfTocMarks.CategoryKey(2));
        Assert.Contains("QZXS42XZQ", PdfTocMarks.Html(PdfTocMarks.SectionKey(42)));
    }

    private static byte[] BuildPdf(params string[] pageTexts)
    {
        var objects = new List<string>
        {
            "<< /Type /Catalog /Pages 2 0 R >>",
            $"<< /Type /Pages /Kids [{string.Join(" ", Enumerable.Range(0, pageTexts.Length).Select(i => $"{i + 3} 0 R"))}] /Count {pageTexts.Length} >>",
        };

        var fontObject = pageTexts.Length * 2 + 3;
        for (var i = 0; i < pageTexts.Length; i++)
        {
            var contentObject = pageTexts.Length + 3 + i;
            objects.Add($"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 {fontObject} 0 R >> >> /Contents {contentObject} 0 R >>");
        }

        foreach (var text in pageTexts)
        {
            var content = $"BT /F1 12 Tf 72 720 Td ({text}) Tj ET";
            objects.Add($"<< /Length {Encoding.ASCII.GetByteCount(content)} >>\nstream\n{content}\nendstream");
        }
        objects.Add("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>");

        using var stream = new MemoryStream();
        using var writer = new StreamWriter(stream, Encoding.ASCII, leaveOpen: true);
        writer.Write("%PDF-1.4\n");
        writer.Flush();

        var offsets = new List<long> { 0 };
        for (var i = 0; i < objects.Count; i++)
        {
            offsets.Add(stream.Position);
            writer.Write($"{i + 1} 0 obj\n{objects[i]}\nendobj\n");
            writer.Flush();
        }

        var xrefOffset = stream.Position;
        writer.Write($"xref\n0 {objects.Count + 1}\n0000000000 65535 f \n");
        foreach (var offset in offsets.Skip(1)) writer.Write($"{offset:D10} 00000 n \n");
        writer.Write($"trailer\n<< /Size {objects.Count + 1} /Root 1 0 R >>\nstartxref\n{xrefOffset}\n%%EOF");
        writer.Flush();
        return stream.ToArray();
    }
}
