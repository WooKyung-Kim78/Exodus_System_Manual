using System.Net;
using System.Text;
using ExodusSystemManual.Models;

namespace ExodusSystemManual.Utils;

/// 미리보기 iframe과 PDF가 같은 문서 문자열을 사용하도록 만드는 단일 렌더러다.
public static class DocumentHtmlBuilder
{
    public static string Build(PreviewViewModel model)
    {
        var h = model.Header;
        var html = new StringBuilder();
        html.Append("<!doctype html><html lang=\"ko\"><head><meta charset=\"utf-8\"><title>")
            .Append(E(h.MODEL_NAME)).Append("</title>")
            .Append("<link rel=\"stylesheet\" href=\"/css/doc-base.css\">")
            .Append("<link rel=\"stylesheet\" href=\"/css/fonts.css\">")
            .Append("<link rel=\"stylesheet\" href=\"/css/doc-type.css\">")
            .Append("<link rel=\"stylesheet\" href=\"/css/ds-spec.css\">")
            .Append("<link rel=\"stylesheet\" href=\"/css/preview.css\">")
            .Append("</head><body><div class=\"preview-stage\" style=\"")
            .Append("--doc-font:").Append(A(model.BodyFontStack)).Append(';')
            .Append("--doc-font-size:").Append(model.BodyFontSize).Append("pt;")
            .Append("--doc-line-height:").Append(model.BodyLineHeight).Append(';')
            .Append("--doc-letter-spacing:").Append(model.BodyLetterSpacing).Append("px;\"><div class=\"doc-sheet ")
            .Append(h.PAGE_SIZE == "A4" ? "a4" : "letter")
            .Append("\" id=\"docSheet\" data-filename=\"").Append(A(model.FileName))
            .Append("\" data-version=\"").Append(A(h.DOC_VERSION)).Append("\">");

        if (model.IsOem)
            html.Append("<div class=\"doc-oem-title\">").Append(E(h.MODEL_NAME)).Append(" Manual Data</div>");
        else
            Cover(html, model);
        if (model.Sections.Count == 0)
        {
            html.Append("<div class=\"page-break\"></div><p class=\"text-center text-muted\">작성된 목차가 없습니다.</p>");
        }
        else
        {
            if (!model.IsOem) Toc(html, model);
            Sections(html, model, model.IsOem);
        }

        return html.Append("</div></div></body></html>").ToString();
    }

    private static void Cover(StringBuilder html, PreviewViewModel model)
    {
        var h = model.Header;
        html.Append("<div class=\"doc-cover avoid-break\">");
        if (!string.IsNullOrWhiteSpace(model.CoverLogoPath))
            html.Append("<img class=\"cover-logo\" src=\"").Append(A(model.CoverLogoPath)).Append("\" alt=\"logo\">");
        html.Append("<div class=\"cover-headline\">");
        Line(html, model.CoverTitle1);
        Line(html, model.CoverTitle2);
        Line(html, h.MODEL_NAME);
        Line(html, h.JOB_NUMBER);
        html.Append("</div>");
        if (!string.IsNullOrWhiteSpace(h.COVER_IMAGE_PATH))
            html.Append("<img class=\"cover-photo\" src=\"").Append(A(h.COVER_IMAGE_PATH)).Append("\" alt=\"product\">");
        html.Append("<div class=\"cover-meta\">Document No. ").Append(E(h.DOC_NUM)).Append(" · Rev ")
            .Append(E(h.REVISION)).Append(" · ").Append((h.PUBLISH_DATE ?? h.REG_DT).ToString("yyyy-MM-dd"))
            .Append("</div></div>");
    }

    private static void Toc(StringBuilder html, PreviewViewModel model)
    {
        html.Append("<div class=\"page-break\"></div><div class=\"doc-toc\"><div class=\"doc-toc-title\">Table of Contents</div>");
        foreach (var s in model.Sections.Where(x => x.SEC_TYPE != "PAGEBREAK" && x.SHOW_IN_TOC != "N"))
        {
            TocRow(html, s.SEC_LEVEL, "#sec-" + s.SEC_ID, s.SEC_NO, s.TITLE, model.TocPageOf(PdfTocMarks.SectionKey(s.SEC_ID)));
            if (model.SpecSecId == s.SEC_ID && !string.IsNullOrWhiteSpace(model.SpecHtml))
            {
                var level = Math.Min(s.SEC_LEVEL + 1, 3);
                for (var i = 0; i < model.SpecCategories.Count; i++)
                    TocRow(html, level, "#sec-" + s.SEC_ID, null, model.SpecCategories[i], model.TocPageOf(PdfTocMarks.CategoryKey(i)));
            }
        }
        html.Append("</div>");
    }

    private static void TocRow(StringBuilder html, int level, string href, string? no, string title, string page)
    {
        html.Append("<a class=\"toc-row lv").Append(level).Append("\" href=\"").Append(A(href)).Append("\">");
        if (!string.IsNullOrWhiteSpace(no)) html.Append("<span class=\"toc-no\">").Append(E(no)).Append("</span>");
        html.Append("<span class=\"toc-text\">").Append(E(title)).Append("</span><span class=\"toc-leader\"></span><span class=\"toc-page\">")
            .Append(E(page)).Append("</span></a>");
    }

    private static void Sections(StringBuilder html, PreviewViewModel model, bool startOnNewPage)
    {
        var pendingBreak = startOnNewPage;
        foreach (var s in model.Sections)
        {
            if (s.SEC_TYPE == "PAGEBREAK") { pendingBreak = true; continue; }
            if (pendingBreak || s.SEC_LEVEL == 1) { html.Append("<div class=\"page-break\"></div>"); pendingBreak = false; }
            var style = model.StyleOf(s);
            html.Append("<div class=\"doc-section\" id=\"sec-").Append(s.SEC_ID).Append("\"><div class=\"doc-section-title avoid-break\" style=\"")
                .Append(A(style.ToCss())).Append("text-align:").Append(TitleAligns.CssOf(s.TITLE_ALIGN)).Append(";\">");
            if (model.EmitTocMarks) html.Append(PdfTocMarks.Html(PdfTocMarks.SectionKey(s.SEC_ID)));
            if (!string.IsNullOrWhiteSpace(s.SEC_NO)) html.Append("<span class=\"sec-no\">").Append(E(s.SEC_NO)).Append("</span>");
            html.Append("<span>").Append(E(s.TITLE)).Append("</span></div>");
            if (model.SpecSecId == s.SEC_ID && !string.IsNullOrWhiteSpace(model.SpecHtml))
                html.Append("<div class=\"doc-block\">").Append(model.EmitTocMarks ? model.SpecHtmlMarked : model.SpecHtml).Append("</div>");
            if (model.Blocks.TryGetValue(s.SEC_ID, out var blocks))
                foreach (var block in blocks.OrderBy(b => b.ORDER_NUM)) Block(html, block);
            html.Append("</div>");
        }
    }

    private static void Block(StringBuilder html, ElementItem block)
    {
        html.Append("<div class=\"doc-block avoid-break").Append(block.ELE_TYPE == "TABLE" ? " doc-block-table" : string.Empty).Append("\">");
        if (block.ELE_TYPE == "IMAGE" && !string.IsNullOrWhiteSpace(block.IMAGE_PATH))
        {
            html.Append("<img src=\"").Append(A(block.IMAGE_PATH)).Append("\" alt=\"").Append(A(block.CAPTION)).Append("\" style=\"width:")
                .Append(block.WIDTH > 0 ? block.WIDTH : 100).Append("%\">");
            if (!string.IsNullOrWhiteSpace(block.CAPTION)) html.Append("<div class=\"block-caption\">").Append(E(block.CAPTION)).Append("</div>");
        }
        else if (!string.IsNullOrWhiteSpace(block.CONTENT_HTML)) html.Append(block.CONTENT_HTML);
        html.Append("</div>");
    }

    private static void Line(StringBuilder html, string? value)
    {
        if (!string.IsNullOrWhiteSpace(value)) html.Append("<div>").Append(E(value)).Append("</div>");
    }

    private static string E(string? value) => WebUtility.HtmlEncode(value ?? string.Empty);
    private static string A(string? value) => WebUtility.HtmlEncode(value ?? string.Empty);
}
