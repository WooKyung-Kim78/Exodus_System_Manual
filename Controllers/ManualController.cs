using System.Net;
using ExodusSystemManual.Controllers.Attributes;
using ExodusSystemManual.Controllers.Common;
using ExodusSystemManual.Data;
using ExodusSystemManual.Models;
using ExodusSystemManual.Utils;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Playwright;

namespace ExodusSystemManual.Controllers;

[Route("api/manual")]
public class ManualController : BaseController<ManualController>
{
    private readonly SendMail _mail;
    private readonly HtmlSanitize _sanitizer;
    private readonly DatasheetSpec _datasheet;
    private readonly PdfRenderer _pdf;

    public ManualController(
        ApplicationDbContext db,
        IWebHostEnvironment env,
        ILogger<ManualController> logger,
        IConfiguration config,
        SendMail mail,
        HtmlSanitize sanitizer,
        DatasheetSpec datasheet,
        PdfRenderer pdf)
        : base(db, env, logger, config)
    {
        _mail = mail;
        _sanitizer = sanitizer;
        _datasheet = datasheet;
        _pdf = pdf;
    }

    [AjaxAuth]
    [HttpGet("pdf")]
    public async Task<IActionResult> Pdf(string mid, CancellationToken ct)
    {
        var denied = DenyIfNotReadable(mid);
        if (denied is not null) return denied;

        var model = BuildPreviewModel(mid);
        if (model is null) return JsonFail(StatusCodes.Status404NotFound, "문서를 찾을 수 없습니다.");

        byte[] pdf;
        try
        {
            // 1차로 제목이 찍힌 쪽을 알아낸 뒤 목차에 쪽 번호를 채워 다시 만든다. 목차 폭이 고정이라 쪽 배치는 바뀌지 않는다.
            if (!model.IsOem)
            {
                model.EmitTocMarks = true;
                var draft = await RenderPdfAsync(model, ct);
                model.TocPages = PdfTocMarks.Read(draft);
                model.EmitTocMarks = false;
            }
            pdf = await RenderPdfAsync(model, ct);
        }
        catch (PlaywrightException ex)
        {
            _logger.LogError(ex, "PDF 생성 실패 ({MID})", mid);
            return JsonFail(StatusCodes.Status500InternalServerError, "PDF 를 만들지 못했습니다.");
        }

        NoStore();
        return File(pdf, "application/pdf", model.FileName);
    }

    private async Task<byte[]> RenderPdfAsync(PreviewViewModel model, CancellationToken ct)
    {
        var html = DocumentHtmlBuilder.Build(model);

        // 여백은 preview.css 의 @page 와 같아야 한다.
        return await _pdf.RenderAsync(html, new PagePdfOptions
        {
            Format = model.Header.PAGE_SIZE == "A4" ? "A4" : "Letter",
            PrintBackground = true,
            DisplayHeaderFooter = true,
            HeaderTemplate = "<span></span>",
            FooterTemplate = model.IsOem ? BuildOemPdfFooter(model.OemFooterText) : BuildPdfFooter(model.Header.DOC_VERSION),
            Margin = new Margin { Top = "20mm", Right = "20mm", Bottom = "18mm", Left = "20mm" },
        }, ct);
    }

    private PreviewViewModel? BuildPreviewModel(string mid)
    {
        var header = LoadHeader(mid);
        if (header is null) return null;

        var sections = _db.USP_S_SELECT_SECTION_LIST
            .FromSqlRaw("EXECUTE dbo.USP_S_SELECT_SECTION_LIST {0}, {1}", mid, CurrentUserId!)
            .AsEnumerable().ToList();

        var blocks = _db.USP_S_SELECT_ELEMENT_LIST
            .FromSqlRaw("EXECUTE dbo.USP_S_SELECT_ELEMENT_LIST {0}, {1}", mid, DBNull.Value)
            .AsEnumerable().ToList();

        // 저장 시에도 정제하지만, 렌더 직전에 한 번 더 통과시켜 이중 방어한다.
        foreach (var b in blocks)
            b.CONTENT_HTML = _sanitizer.Clean(b.CONTENT_HTML);

        var cover = _db.USP_S_SELECT_COMMON_CODE_LIST
            .FromSqlRaw("EXECUTE dbo.USP_S_SELECT_COMMON_CODE_LIST {0}", "COVER")
            .AsEnumerable()
            .ToDictionary(c => c.CODE, c => c.NAME);

        // SPECIFICATIONS 목차는 저장된 내용이 아니라 PDF 를 만들 때 datasheet 에서 그때그때 읽는다.
        var specSection = sections.FirstOrDefault(s => DatasheetSpec.IsSpecSection(s.TITLE));
        var spec = specSection is null ? null : LoadSpec(header).spec;

        return new PreviewViewModel
        {
            Header = header,
            Sections = sections,
            Blocks = blocks.GroupBy(b => b.SEC_ID)
                           .ToDictionary(g => g.Key, g => g.OrderBy(b => b.ORDER_NUM).ToList()),
            HeadingStyles = PreviewViewModel.ParseStyles(header.HEADING_STYLE_JSON),
            SpecSecId = specSection?.SEC_ID,
            SpecHtml = spec is null ? null : _sanitizer.Clean(DatasheetSpec.BuildHtml(spec)),
            SpecHtmlMarked = spec is null ? null : _sanitizer.Clean(DatasheetSpec.BuildHtml(spec, markCategories: true)),
            SpecCategories = spec?.Categories.Select(DatasheetSpec.TocTitle).ToList() ?? new List<string>(),
            CoverTitle1 = cover.GetValueOrDefault("TITLE_LINE1", string.Empty),
            CoverTitle2 = cover.GetValueOrDefault("TITLE_LINE2", string.Empty),
            CoverLogoPath = cover.GetValueOrDefault("LOGO_PATH"),
            OemFooterText = cover.GetValueOrDefault("OEM_FOOTER", string.Empty),
        };
    }

    // "1 | Page - Ver. 1.0" — 쪽 번호만 굵게. 템플릿은 페이지의 웹 글꼴을 못 쓰므로 기본 글꼴로 찍는다.
    private static string BuildPdfFooter(string? version)
    {
        var tail = " | Page" + (string.IsNullOrWhiteSpace(version) ? "" : "  -  Ver. " + WebUtility.HtmlEncode(version));
        return "<div style=\"width:100%;box-sizing:border-box;padding:0 20mm;margin-bottom:5mm;"
             + "font-family:Helvetica,Arial,sans-serif;font-size:9pt;color:#464646;"
             + "letter-spacing:0.35mm;white-space:pre;\">"
             + "<span class=\"pageNumber\" style=\"font-weight:700;\"></span>" + tail
             + "</div>";
    }

    private static string BuildOemPdfFooter(string text)
    {
        return "<div style=\"width:100%;box-sizing:border-box;padding:0 20mm;margin-bottom:5mm;text-align:center;"
             + "font-family:Helvetica,Arial,sans-serif;font-size:9pt;color:#464646;letter-spacing:0.35mm;\">"
             + WebUtility.HtmlEncode(text)
             + "</div>";
    }

    [AjaxAuth]
    [HttpGet("document-html")]
    public IActionResult DocumentHtml(string mid, string? mode)
    {
        if (mode is not ("preview" or "pdf"))
            return JsonFail(StatusCodes.Status400BadRequest, "mode 는 preview 또는 pdf 이어야 합니다.");

        var denied = DenyIfNotReadable(mid);
        if (denied is not null) return denied;

        var model = BuildPreviewModel(mid);
        if (model is null) return JsonFail(StatusCodes.Status404NotFound, "문서를 찾을 수 없습니다.");

        NoStore();
        return Content(DocumentHtmlBuilder.Build(model), "text/html; charset=utf-8");
    }

    /* ================= 목록 / 헤더 ================= */

    [AjaxAuth]
    [HttpGet("list")]
    [Produces("application/json")]
    public IActionResult GetList(string? status, string? onlyMine, string? startDate, string? endDate)
    {
        var list = _db.USP_S_SELECT_MANUAL_LIST_BY_STATUS
            .FromSqlRaw("EXECUTE dbo.USP_S_SELECT_MANUAL_LIST_BY_STATUS {0}, {1}, {2}, {3}, {4}",
                string.IsNullOrWhiteSpace(status) ? DBNull.Value : status,
                CurrentUserId!,
                onlyMine == "Y" ? "Y" : "N",
                string.IsNullOrWhiteSpace(startDate) ? DBNull.Value : startDate,
                string.IsNullOrWhiteSpace(endDate) ? DBNull.Value : endDate)
            .AsEnumerable()
            .ToList();

        return JsonOk(new { list });
    }

    [AjaxAuth]
    [HttpPost("create")]
    [ValidateAntiForgeryToken]
    [Produces("application/json")]
    public IActionResult CreateNew([FromBody] InputNewManual input)
    {
        if (!ModelState.IsValid) return JsonFail(StatusCodes.Status400BadRequest, FirstError());

        var result = _db.ResultModel
            .FromSqlRaw("EXECUTE dbo.USP_S_INSERT_MANUAL {0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}",
                (object?)input.JOB_NUMBER ?? DBNull.Value,
                input.MODEL_NAME,
                (object?)input.LABEL ?? DBNull.Value,
                (object?)input.COOLING ?? DBNull.Value,
                (object?)input.OPTION_TEXT ?? DBNull.Value,
                input.PAGE_SIZE,
                DBNull.Value,
                CurrentUserId!,
                (object?)input.PROCESS_ID ?? DBNull.Value,
                (object?)input.DOC_VERSION ?? DBNull.Value)
            .AsEnumerable()
            .FirstOrDefault();

        if (result is null || result.Success == 0)
            return JsonFail(StatusCodes.Status400BadRequest, result?.ReturnMsg ?? "문서를 생성하지 못했습니다.");

        return JsonOk(new { M_ID = result.ReturnMsg! });
    }

    [AjaxAuth]
    [HttpGet("find")]
    [Produces("application/json")]
    public IActionResult FindOne(string mid)
    {
        var denied = DenyIfNotReadable(mid, out var access);
        if (denied is not null) return denied;

        var header = _db.USP_S_SELECT_MANUAL
            .FromSqlRaw("EXECUTE dbo.USP_S_SELECT_MANUAL {0}", mid)
            .AsEnumerable()
            .FirstOrDefault();

        var sections = _db.USP_S_SELECT_SECTION_LIST
            .FromSqlRaw("EXECUTE dbo.USP_S_SELECT_SECTION_LIST {0}, {1}", mid, CurrentUserId!)
            .AsEnumerable()
            .ToList();

        return JsonOk(new { header, sections, access });
    }

    [AjaxAuth]
    [HttpPost("header")]
    [ValidateAntiForgeryToken]
    [Produces("application/json")]
    public IActionResult UpdateHeader([FromBody] InputManualHeader input)
    {
        if (!ModelState.IsValid) return JsonFail(StatusCodes.Status400BadRequest, FirstError());

        var denied = DenyIfNotEditable(input.M_ID);
        if (denied is not null) return denied;

        var result = _db.ResultModel
            .FromSqlRaw("EXECUTE dbo.USP_S_UPDATE_MANUAL_HEADER {0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}",
                input.M_ID,
                (object?)input.JOB_NUMBER ?? DBNull.Value,
                input.MODEL_NAME,
                (object?)input.LABEL ?? DBNull.Value,
                (object?)input.COOLING ?? DBNull.Value,
                (object?)input.OPTION_TEXT ?? DBNull.Value,
                input.PAGE_SIZE,
                CurrentUserId!,
                (object?)input.PROCESS_ID ?? DBNull.Value,
                (object?)input.DOC_VERSION ?? DBNull.Value)
            .AsEnumerable()
            .FirstOrDefault();

        return ToJson(result);
    }

    [AjaxAuth]
    [HttpDelete("delete")]
    [ValidateAntiForgeryToken]
    [Produces("application/json")]
    public IActionResult DeleteManual(string mid)
    {
        var denied = DenyIfNotEditable(mid);
        if (denied is not null) return denied;

        var result = _db.ResultModel
            .FromSqlRaw("EXECUTE dbo.USP_S_DELETE_MANUAL {0}, {1}", mid, CurrentUserId!)
            .AsEnumerable()
            .FirstOrDefault();

        return ToJson(result);
    }

    /* ================= 작성 요청 메일 ================= */

    /// 목차 담당 팀원과 작성자에게 편집기 링크를 담아 요청 메일을 보낸다.
    [AjaxAuth]
    [HttpPost("notify")]
    [ValidateAntiForgeryToken]
    [Produces("application/json")]
    public async Task<IActionResult> NotifyEditRequest(string mid, string? memo, string? onlyAssigned)
    {
        var denied = DenyIfNotEditable(mid);
        if (denied is not null) return denied;

        var header = LoadHeader(mid);
        if (header is null) return JsonFail(StatusCodes.Status404NotFound, "문서를 찾을 수 없습니다.");

        var recipients = _db.USP_S_SELECT_NOTIFY_RECIPIENT_LIST
            .FromSqlRaw("EXECUTE dbo.USP_S_SELECT_NOTIFY_RECIPIENT_LIST {0}", mid)
            .AsEnumerable()
            .Where(r => !string.IsNullOrWhiteSpace(r.EMAIL_ADDRESS))
            .Where(r => r.USER_ID != CurrentUserId)
            .Where(r => onlyAssigned != "Y" || r.SECTION_CNT > 0)
            .ToList();

        if (recipients.Count == 0)
            return JsonFail(StatusCodes.Status400BadRequest,
                "보낼 수신자가 없습니다. 목차의 담당 팀과 사용자 이메일 주소를 확인하세요.");

        var sent = new List<string>();
        var failed = new List<string>();

        foreach (var recipient in recipients)
        {
            var (subject, body) = MailTemplates.EditRequest(header, recipient, AppDomainUrl, CurrentUserName, memo);
            var (ok, _) = await _mail.SendAsync("EDIT_REQUEST", mid,
                new[] { recipient.EMAIL_ADDRESS! }, subject, body, regId: CurrentUserId);

            (ok ? sent : failed).Add(recipient.FULL_NAME);
        }

        var testMode = _mail.LoadSettings().IsTestScope;
        return JsonOk(new { sent, failed, testMode });
    }

    [AjaxAuth]
    [HttpGet("notify/recipients")]
    [Produces("application/json")]
    public IActionResult GetNotifyRecipients(string mid)
    {
        var denied = DenyIfNotReadable(mid);
        if (denied is not null) return denied;

        // 미리보기와 실제 발송 대상이 어긋나지 않도록 본인 제외 기준을 서버에서 맞춘다.
        var list = _db.USP_S_SELECT_NOTIFY_RECIPIENT_LIST
            .FromSqlRaw("EXECUTE dbo.USP_S_SELECT_NOTIFY_RECIPIENT_LIST {0}", mid)
            .AsEnumerable()
            .Where(r => r.USER_ID != CurrentUserId)
            .ToList();

        return JsonOk(new { list, testMode = _mail.LoadSettings().IsTestScope });
    }

    /* ================= 표지 이미지 ================= */

    [AjaxAuth]
    [HttpPost("cover")]
    [ValidateAntiForgeryToken]
    [Consumes("multipart/form-data")]
    [Produces("application/json")]
    public async Task<IActionResult> UploadCover(string mid, IFormFile file)
    {
        var denied = DenyIfNotEditable(mid);
        if (denied is not null) return denied;

        var maxBytes = _config.GetValue<long>("APP:MAX_UPLOAD_BYTES", 20 * 1024 * 1024);
        var upload = await ImageUpload.SaveAsync(file, _env.ContentRootPath, mid, maxBytes);

        if (!upload.Success)
            return JsonFail(StatusCodes.Status400BadRequest, upload.Message ?? "업로드에 실패했습니다.");

        var result = _db.ResultModel
            .FromSqlRaw("EXECUTE dbo.USP_S_UPDATE_MANUAL_COVER_IMAGE {0}, {1}, {2}",
                mid, upload.WebPath!, CurrentUserId!)
            .AsEnumerable().FirstOrDefault();

        if (result is null || result.Success == 0)
            return JsonFail(StatusCodes.Status400BadRequest, result?.ReturnMsg ?? "표지 이미지를 저장하지 못했습니다.");

        return JsonOk(new { path = upload.WebPath });
    }

    [AjaxAuth]
    [HttpDelete("cover")]
    [ValidateAntiForgeryToken]
    [Produces("application/json")]
    public IActionResult DeleteCover(string mid)
    {
        var denied = DenyIfNotEditable(mid);
        if (denied is not null) return denied;

        var result = _db.ResultModel
            .FromSqlRaw("EXECUTE dbo.USP_S_UPDATE_MANUAL_COVER_IMAGE {0}, {1}, {2}",
                mid, DBNull.Value, CurrentUserId!)
            .AsEnumerable().FirstOrDefault();

        return ToJson(result);
    }

    /* ================= 조회용 ================= */

    /// Model Name 선택 목록. exodus_datasheet 에서 발행된 datasheet 의 NAME 을 쓴다.
    [AjaxAuth]
    [HttpGet("datasheets")]
    [Produces("application/json")]
    public IActionResult GetDatasheets()
    {
        try
        {
            return JsonOk(new { list = _datasheet.GetPublishedOptions() });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "datasheet 목록을 불러오지 못했습니다.");
            return JsonFail(StatusCodes.Status503ServiceUnavailable, "Datasheet 시스템에 연결하지 못했습니다.");
        }
    }

    /// SPECIFICATIONS 목차에 그릴 datasheet 사양. 저장하지 않고 요청할 때마다 datasheet 에서 읽는다.
    [AjaxAuth]
    [HttpGet("spec")]
    [Produces("application/json")]
    public IActionResult GetSpec(string mid)
    {
        var denied = DenyIfNotReadable(mid);
        if (denied is not null) return denied;

        var header = LoadHeader(mid);
        if (header is null) return JsonFail(StatusCodes.Status404NotFound, "문서를 찾을 수 없습니다.");

        var (html, message) = LoadSpecHtml(header);
        return JsonOk(new
        {
            html,
            message,
            modelName = header.MODEL_NAME,
            processId = header.PROCESS_ID,
        });
    }

    [AjaxAuth]
    [HttpGet("teams")]
    [Produces("application/json")]
    public IActionResult GetTeams()
    {
        var teams = _db.USP_S_SELECT_USER_TEAM_LIST
            .FromSqlRaw("EXECUTE dbo.USP_S_SELECT_USER_TEAM_LIST")
            .AsEnumerable()
            .ToList();

        return JsonOk(new { teams });
    }

    [AjaxAuth]
    [HttpGet("users")]
    [Produces("application/json")]
    public IActionResult SearchUsers(string? keyword, string? team)
    {
        var users = _db.USP_S_SELECT_USER_SEARCH_LIST
            .FromSqlRaw("EXECUTE dbo.USP_S_SELECT_USER_SEARCH_LIST {0}, {1}",
                string.IsNullOrWhiteSpace(keyword) ? DBNull.Value : keyword,
                string.IsNullOrWhiteSpace(team) ? DBNull.Value : team)
            .AsEnumerable()
            .ToList();

        return JsonOk(new { users });
    }

    /* ================= 공통 ================= */

    private string AppDomainUrl => _config["APP:DOMAIN"] ?? "http://localhost:7176";

    private ManualHeader? LoadHeader(string mId)
        => _db.USP_S_SELECT_MANUAL
            .FromSqlRaw("EXECUTE dbo.USP_S_SELECT_MANUAL {0}", mId)
            .AsEnumerable().FirstOrDefault();



    /* ---------- datasheet 사양 → SPECIFICATIONS 목차 ---------- */

    /// 저장된 PROCESS_ID(= TB_DS_DOCUMENT.D_ID)로 datasheet 의 category·parameter 를 읽어 HTML 로 만든다.
    private (string? html, string message) LoadSpecHtml(ManualHeader header)
    {
        var (spec, message) = LoadSpec(header);
        return (spec is null ? null : _sanitizer.Clean(DatasheetSpec.BuildHtml(spec)), message);
    }

    private (DatasheetSpecResult? spec, string message) LoadSpec(ManualHeader header)
    {
        if (string.IsNullOrWhiteSpace(header.PROCESS_ID))
            return (null, "Model Name 을 datasheet 목록에서 선택하세요.");

        DatasheetSpecResult? spec;
        try
        {
            spec = _datasheet.GetSpecById(header.PROCESS_ID);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "datasheet 사양을 불러오지 못했습니다. ({MID}, {MODEL})", header.M_ID, header.MODEL_NAME);
            return (null, "Datasheet 시스템에 연결하지 못했습니다.");
        }

        if (spec is null || spec.Categories.Count == 0)
            return (null, $"'{header.MODEL_NAME}' datasheet 에서 가져올 사양이 없습니다.");

        var rows = spec.Categories.Sum(c => c.ROWS.Count);
        return (spec, $"'{spec.Datasheet.NAME}' 사양 {spec.Categories.Count}개 항목 · {rows}개 파라미터");
    }
}
