using Ganss.Xss;

namespace ExodusSystemManual.Utils;

/// CKEditor5 가 만든 HTML 을 저장 전에 정제한다. 자동저장 경로에서도 반드시 통과시켜야 한다.
public class HtmlSanitize
{
    private readonly HtmlSanitizer _sanitizer;

    public HtmlSanitize()
    {
        _sanitizer = new HtmlSanitizer();

        _sanitizer.AllowedTags.Clear();
        foreach (var tag in new[]
        {
            "p", "br", "span", "div", "strong", "b", "em", "i", "u", "s", "sub", "sup",
            "h1", "h2", "h3", "h4", "h5", "h6", "blockquote", "pre", "code",
            "ul", "ol", "li", "hr", "figure", "figcaption",
            // colgroup/col 은 CKEditor 가 표의 열 너비를 저장하는 곳이다.
            "table", "colgroup", "col", "caption", "thead", "tbody", "tfoot", "tr", "th", "td", "a", "img",
        })
            _sanitizer.AllowedTags.Add(tag);

        _sanitizer.AllowedAttributes.Clear();
        foreach (var attr in new[]
        {
            "href", "title", "target", "rel", "src", "alt", "width", "height",
            "colspan", "rowspan", "span", "class", "style",
        })
            _sanitizer.AllowedAttributes.Add(attr);

        _sanitizer.AllowedCssProperties.Clear();
        foreach (var css in new[]
        {
            "color", "background-color", "background", "font-size", "font-weight", "font-style",
            "text-align", "text-decoration", "line-height", "width", "height",
            "min-width", "max-width", "vertical-align", "float",
            "border", "border-color", "border-style", "border-width", "border-collapse", "border-spacing",
            "border-top", "border-right", "border-bottom", "border-left",
            "border-top-color", "border-top-style", "border-top-width",
            "border-right-color", "border-right-style", "border-right-width",
            "border-bottom-color", "border-bottom-style", "border-bottom-width",
            "border-left-color", "border-left-style", "border-left-width",
            "padding", "padding-top", "padding-right", "padding-bottom", "padding-left",
            "margin", "margin-top", "margin-right", "margin-bottom", "margin-left",
        })
            _sanitizer.AllowedCssProperties.Add(css);

        // javascript:, data: 스킴을 통한 스크립트 실행을 막는다.
        _sanitizer.AllowedSchemes.Clear();
        _sanitizer.AllowedSchemes.Add("http");
        _sanitizer.AllowedSchemes.Add("https");
        _sanitizer.AllowedSchemes.Add("mailto");

        _sanitizer.RemovingAttribute += (_, e) => e.Cancel = false;
    }

    public string? Clean(string? html)
        => string.IsNullOrWhiteSpace(html) ? html : _sanitizer.Sanitize(html);
}
