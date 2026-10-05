using ExodusSystemManual.Models;
using ExodusSystemManual.Utils;

namespace ExodusSystemManual.Tests.Utils;

public class DocumentHtmlBuilderTests
{
    [Fact]
    public void Build_encodes_model_values_but_keeps_sanitized_block_html()
    {
        var model = new PreviewViewModel
        {
            Header = new ManualHeader { M_ID = "M1", MODEL_NAME = "<model>", REVISION = "1", STATUS = "DRAFT", PAGE_SIZE = "LETTER", REQUESTER_ID = "user", REG_DT = DateTime.Today },
            Sections = new List<SectionItem> { new() { SEC_ID = 1, M_ID = "M1", TITLE = "<section>", SEC_STATUS = "EMPTY" } },
            Blocks = new Dictionary<long, List<ElementItem>> { [1] = new() { new() { SEC_ID = 1, M_ID = "M1", ELE_TYPE = "TEXT", CONTENT_HTML = "<p>허용 본문</p>" } } },
        };

        var html = DocumentHtmlBuilder.Build(model);

        Assert.Contains("&lt;model&gt;", html);
        Assert.Contains("&lt;section&gt;", html);
        Assert.Contains("<p>허용 본문</p>", html);
        Assert.DoesNotContain("<div><model>", html);
    }

    [Fact]
    public void Build_writes_pagebreak_before_following_section()
    {
        var model = new PreviewViewModel
        {
            Header = new ManualHeader { M_ID = "M1", MODEL_NAME = "model", REVISION = "1", STATUS = "DRAFT", PAGE_SIZE = "A4", REQUESTER_ID = "user", REG_DT = DateTime.Today },
            Sections = new List<SectionItem>
            {
                new() { SEC_ID = 1, M_ID = "M1", TITLE = "first", SEC_STATUS = "EMPTY" },
                new() { SEC_ID = 2, M_ID = "M1", TITLE = "", SEC_TYPE = "PAGEBREAK", SEC_STATUS = "EMPTY" },
                new() { SEC_ID = 3, M_ID = "M1", TITLE = "after", SEC_STATUS = "EMPTY" },
            },
        };

        var html = DocumentHtmlBuilder.Build(model);

        Assert.Contains("id=\"sec-3\"", html);
        Assert.True(html.LastIndexOf("page-break", StringComparison.Ordinal) < html.IndexOf("id=\"sec-3\"", StringComparison.Ordinal));
    }

    [Fact]
    public void Build_oem_document_omits_cover_and_toc_but_starts_sections_on_next_page()
    {
        var model = new PreviewViewModel
        {
            Header = new ManualHeader { M_ID = "M1", MODEL_NAME = "OEM-100", LABEL = "OEM", REVISION = "1", STATUS = "DRAFT", PAGE_SIZE = "LETTER", REQUESTER_ID = "user", REG_DT = DateTime.Today },
            Sections = new List<SectionItem> { new() { SEC_ID = 1, M_ID = "M1", TITLE = "본문", SEC_STATUS = "EMPTY" } },
        };

        var html = DocumentHtmlBuilder.Build(model);

        Assert.Contains("OEM-100 Manual Data", html);
        Assert.DoesNotContain("doc-cover", html);
        Assert.DoesNotContain("Table of Contents", html);
        Assert.True(html.IndexOf("page-break", StringComparison.Ordinal) < html.IndexOf("id=\"sec-1\"", StringComparison.Ordinal));
    }
}
