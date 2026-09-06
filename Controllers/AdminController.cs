using ExodusSystemManual.Controllers.Attributes;
using ExodusSystemManual.Controllers.Common;
using ExodusSystemManual.Data;
using ExodusSystemManual.Models;
using ExodusSystemManual.Utils;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace ExodusSystemManual.Controllers;

[Route("admin")]
public class AdminController : BaseController<AdminController>
{
    private static readonly string[] SmtpKeys =
    {
        "SYSTEM_NAME", "SYSTEM_EMAIL", "SYSTEM_SMTP", "SYSTEM_SMTP_PORT",
        "SYSTEM_SMTP_SECURE", "SYSTEM_EMAIL_ID", "SYSTEM_EMAIL_PASSWORD", "SYSTEM_SMTP_SCOPE",
    };

    private readonly SendMail _mail;
    private readonly HtmlSanitize _sanitizer;

    public AdminController(
        ApplicationDbContext db,
        IWebHostEnvironment env,
        ILogger<AdminController> logger,
        IConfiguration config,
        SendMail mail,
        HtmlSanitize sanitizer)
        : base(db, env, logger, config)
    {
        _mail = mail;
        _sanitizer = sanitizer;
    }

    [Auth("ADMIN, SUPPORTER")]
    [HttpGet("setting")]
    public IActionResult Setting() => View();

    [AjaxAuth("ADMIN, SUPPORTER")]
    [HttpGet("setting/mail")]
    [Produces("application/json")]
    public IActionResult GetMailSetting()
    {
        var rows = _db.TB_S_SETTING.Where(s => s.CATEGORY == "SMTP").ToList();
        string Get(string type) => rows.FirstOrDefault(r => r.TYPE == type)?.VALUE ?? string.Empty;

        // 비밀번호는 값 대신 설정 여부만 내려준다.
        return JsonOk(new
        {
            setting = new
            {
                SYSTEM_NAME = Get("SYSTEM_NAME"),
                SYSTEM_EMAIL = Get("SYSTEM_EMAIL"),
                SYSTEM_SMTP = Get("SYSTEM_SMTP"),
                SYSTEM_SMTP_PORT = Get("SYSTEM_SMTP_PORT"),
                SYSTEM_SMTP_SECURE = Get("SYSTEM_SMTP_SECURE"),
                SYSTEM_EMAIL_ID = Get("SYSTEM_EMAIL_ID"),
                SYSTEM_SMTP_SCOPE = Get("SYSTEM_SMTP_SCOPE"),
            },
            hasPassword = !string.IsNullOrEmpty(Get("SYSTEM_EMAIL_PASSWORD")),
        });
    }

    [AjaxAuth("ADMIN, SUPPORTER")]
    [HttpPost("setting/mail")]
    [ValidateAntiForgeryToken]
    [Produces("application/json")]
    public IActionResult SaveMailSetting(InputMailSetting input)
    {
        if (input.SYSTEM_SMTP_SCOPE is not ("T" or "P"))
            return JsonFail(StatusCodes.Status400BadRequest, "적용 범위 값이 올바르지 않습니다.");

        if (!int.TryParse(input.SYSTEM_SMTP_PORT, out var port) || port is < 1 or > 65535)
            return JsonFail(StatusCodes.Status400BadRequest, "포트 번호가 올바르지 않습니다.");

        var values = new Dictionary<string, string?>
        {
            ["SYSTEM_NAME"] = input.SYSTEM_NAME,
            ["SYSTEM_EMAIL"] = input.SYSTEM_EMAIL,
            ["SYSTEM_SMTP"] = input.SYSTEM_SMTP,
            ["SYSTEM_SMTP_PORT"] = port.ToString(),
            ["SYSTEM_SMTP_SECURE"] = input.SYSTEM_SMTP_SECURE,
            ["SYSTEM_EMAIL_ID"] = input.SYSTEM_EMAIL_ID,
            ["SYSTEM_SMTP_SCOPE"] = input.SYSTEM_SMTP_SCOPE,
        };

        // 빈 값이면 기존 비밀번호를 유지한다. 입력된 경우에만 암호화해 덮어쓴다.
        if (!string.IsNullOrEmpty(input.SYSTEM_EMAIL_PASSWORD))
            values["SYSTEM_EMAIL_PASSWORD"] = _mail.Protect(input.SYSTEM_EMAIL_PASSWORD);

        var rows = _db.TB_S_SETTING.Where(s => SmtpKeys.Contains(s.TYPE)).ToList();

        foreach (var (type, value) in values)
        {
            var row = rows.FirstOrDefault(r => r.TYPE == type);
            if (row is null)
            {
                _db.TB_S_SETTING.Add(new SettingItem
                {
                    CATEGORY = "SMTP", TYPE = type, VALUE = value,
                    REG_ID = CurrentUserId!, REG_DT = DateTime.Now,
                });
            }
            else
            {
                row.VALUE = value;
                row.UPT_ID = CurrentUserId;
                row.UPT_DT = DateTime.Now;
            }
        }

        _db.SaveChanges();
        return JsonOk();
    }

    [AjaxAuth("ADMIN, SUPPORTER")]
    [HttpPost("setting/mail/test")]
    [ValidateAntiForgeryToken]
    [Produces("application/json")]
    public async Task<IActionResult> SendTestMail(string to)
    {
        if (string.IsNullOrWhiteSpace(to) || !to.Contains('@'))
            return JsonFail(StatusCodes.Status400BadRequest, "받는 사람 주소를 확인하세요.");

        var body = $@"<div style=""font-family:'Malgun Gothic',sans-serif"">
            <p>EXODUS System Manual 메일 설정 테스트입니다.</p>
            <p>발송 시각: {DateTime.Now:yyyy-MM-dd HH:mm:ss}</p></div>";

        var (ok, error) = await _mail.SendAsync("TEST", null, new[] { to },
            "[System Manual] 메일 설정 테스트", body, regId: CurrentUserId);

        if (!ok) return JsonFail(StatusCodes.Status400BadRequest, error ?? "발송에 실패했습니다.");

        return JsonOk(new { testMode = _mail.LoadSettings().IsTestScope });
    }

    [AjaxAuth("ADMIN, SUPPORTER")]
    [HttpGet("setting/mail/log")]
    [Produces("application/json")]
    public IActionResult GetMailLog()
    {
        var list = _db.TB_S_MAIL_LOG
            .OrderByDescending(l => l.IDX)
            .Take(50)
            .ToList();

        return JsonOk(new { list });
    }

    /* ================= 목차 템플릿 ================= */

    [Auth("ADMIN")]
    [HttpGet("section-template")]
    public IActionResult SectionTemplate() => View();

    [AjaxAuth("ADMIN")]
    [HttpGet("section-template/list")]
    [Produces("application/json")]
    public IActionResult GetSectionTemplates(string? label, string? cooling)
    {
        var list = _db.USP_S_SELECT_SECTION_TEMPLATE_LIST
            .FromSqlRaw("EXECUTE dbo.USP_S_SELECT_SECTION_TEMPLATE_LIST {0}, {1}",
                string.IsNullOrWhiteSpace(label) ? DBNull.Value : label,
                string.IsNullOrWhiteSpace(cooling) ? DBNull.Value : cooling)
            .AsEnumerable().ToList();

        return JsonOk(new { list });
    }

    [AjaxAuth("ADMIN")]
    [HttpPost("section-template")]
    [ValidateAntiForgeryToken]
    [Produces("application/json")]
    public IActionResult MergeSectionTemplate(InputSectionTemplate input)
    {
        if (!ModelState.IsValid) return JsonFail(StatusCodes.Status400BadRequest, FirstError());

        var result = _db.ResultModel
            .FromSqlRaw("EXECUTE dbo.USP_S_MERGE_SECTION_TEMPLATE {0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}",
                (object?)input.TPL_ID ?? DBNull.Value,
                string.IsNullOrWhiteSpace(input.LABEL) ? DBNull.Value : input.LABEL,
                string.IsNullOrWhiteSpace(input.COOLING) ? DBNull.Value : input.COOLING,
                input.SEC_LEVEL,
                (object?)input.SEC_NO ?? DBNull.Value,
                input.TITLE,
                input.IS_MANDATORY,
                (object?)input.ORDER_NUM ?? DBNull.Value,
                string.IsNullOrWhiteSpace(input.ASSIGNED_TEAM) ? DBNull.Value : input.ASSIGNED_TEAM,
                (object?)_sanitizer.Clean(input.CONTENT_HTML) ?? DBNull.Value,
                input.TITLE_ALIGN,
                CurrentUserId!)
            .AsEnumerable().FirstOrDefault();

        if (result is null || result.Success == 0)
            return JsonFail(StatusCodes.Status400BadRequest, result?.ReturnMsg ?? "저장하지 못했습니다.");

        return JsonOk(new { TPL_ID = result.ReturnMsg });
    }

    [AjaxAuth("ADMIN")]
    [HttpDelete("section-template")]
    [ValidateAntiForgeryToken]
    [Produces("application/json")]
    public IActionResult DeleteSectionTemplate(long tplId)
    {
        var result = _db.ResultModel
            .FromSqlRaw("EXECUTE dbo.USP_S_DELETE_SECTION_TEMPLATE {0}, {1}", tplId, CurrentUserId!)
            .AsEnumerable().FirstOrDefault();

        if (result is null || result.Success == 0)
            return JsonFail(StatusCodes.Status400BadRequest, result?.ReturnMsg ?? "삭제하지 못했습니다.");

        return JsonOk();
    }

    [AjaxAuth("ADMIN")]
    [HttpPost("section-template/order")]
    [ValidateAntiForgeryToken]
    [Produces("application/json")]
    public IActionResult UpdateSectionTemplateOrder(string orders)
    {
        if (string.IsNullOrWhiteSpace(orders))
            return JsonFail(StatusCodes.Status400BadRequest, "순서 정보가 없습니다.");

        var result = _db.ResultModel
            .FromSqlRaw("EXECUTE dbo.USP_S_UPDATE_SECTION_TEMPLATE_ORDER {0}, {1}", orders, CurrentUserId!)
            .AsEnumerable().FirstOrDefault();

        if (result is null || result.Success == 0)
            return JsonFail(StatusCodes.Status400BadRequest, result?.ReturnMsg ?? "순서를 저장하지 못했습니다.");

        return JsonOk();
    }

    [AjaxAuth("ADMIN")]
    [HttpPost("section-template/image")]
    [ValidateAntiForgeryToken]
    [Consumes("multipart/form-data")]
    [Produces("application/json")]
    public async Task<IActionResult> UploadSectionTemplateImage(IFormFile? upload, IFormFile? file)
    {
        var image = upload ?? file;
        if (image is null) return JsonFail(StatusCodes.Status400BadRequest, "이미지 파일을 선택하세요.");

        var maxBytes = _config.GetValue<long>("APP:MAX_UPLOAD_BYTES", 20 * 1024 * 1024);
        var result = await ImageUpload.SaveAsync(image, _env.ContentRootPath, "templates", maxBytes);
        if (!result.Success)
            return JsonFail(StatusCodes.Status400BadRequest, result.Message ?? "업로드에 실패했습니다.");

        return Ok(new { url = result.WebPath, success = true, data = new { path = result.WebPath } });
    }

    /* ================= 사용자 역할 ================= */

    [Auth("ADMIN")]
    [HttpGet("user-role")]
    public IActionResult UserRole() => View();

    [AjaxAuth("ADMIN")]
    [HttpGet("user-role/list")]
    [Produces("application/json")]
    public IActionResult GetUserRoles(string? keyword)
    {
        var list = _db.USP_S_SELECT_USER_ROLE_LIST
            .FromSqlRaw("EXECUTE dbo.USP_S_SELECT_USER_ROLE_LIST {0}",
                string.IsNullOrWhiteSpace(keyword) ? DBNull.Value : keyword)
            .AsEnumerable().ToList();

        return JsonOk(new { list });
    }

    [AjaxAuth("ADMIN")]
    [HttpPost("user-role")]
    [ValidateAntiForgeryToken]
    [Produces("application/json")]
    public IActionResult MergeUserRole(InputUserRole input)
    {
        if (!ModelState.IsValid) return JsonFail(StatusCodes.Status400BadRequest, FirstError());

        var result = _db.ResultModel
            .FromSqlRaw("EXECUTE dbo.USP_S_MERGE_USER_ROLE {0}, {1}, {2}",
                input.USER_ID, input.ROLE_NAME, CurrentUserId!)
            .AsEnumerable().FirstOrDefault();

        if (result is null || result.Success == 0)
            return JsonFail(StatusCodes.Status400BadRequest, result?.ReturnMsg ?? "역할을 저장하지 못했습니다.");

        return JsonOk();
    }

    /* ================= 공통 코드 ================= */

    [Auth("ADMIN, SUPPORTER")]
    [HttpGet("code")]
    public IActionResult Code() => View();

    [AjaxAuth("ADMIN, SUPPORTER")]
    [HttpGet("code/list")]
    [Produces("application/json")]
    public IActionResult GetCodes(string? category)
    {
        var list = _db.USP_S_SELECT_COMMON_CODE_LIST
            .FromSqlRaw("EXECUTE dbo.USP_S_SELECT_COMMON_CODE_LIST {0}",
                string.IsNullOrWhiteSpace(category) ? DBNull.Value : category)
            .AsEnumerable().ToList();

        return JsonOk(new { list });
    }

    [AjaxAuth("ADMIN, SUPPORTER")]
    [HttpPost("code")]
    [ValidateAntiForgeryToken]
    [Produces("application/json")]
    public IActionResult MergeCode(InputCommonCode input)
    {
        if (!ModelState.IsValid) return JsonFail(StatusCodes.Status400BadRequest, FirstError());

        var result = _db.ResultModel
            .FromSqlRaw("EXECUTE dbo.USP_S_MERGE_COMMON_CODE {0}, {1}, {2}, {3}, {4}, {5}",
                (object?)input.IDX ?? DBNull.Value,
                input.CATEGORY, input.CODE, input.NAME, input.ORDER_NUM, CurrentUserId!)
            .AsEnumerable().FirstOrDefault();

        if (result is null || result.Success == 0)
            return JsonFail(StatusCodes.Status400BadRequest, result?.ReturnMsg ?? "저장하지 못했습니다.");

        return JsonOk(new { IDX = result.ReturnMsg });
    }

    [AjaxAuth("ADMIN, SUPPORTER")]
    [HttpDelete("code")]
    [ValidateAntiForgeryToken]
    [Produces("application/json")]
    public IActionResult DeleteCode(long idx)
    {
        var result = _db.ResultModel
            .FromSqlRaw("EXECUTE dbo.USP_S_DELETE_COMMON_CODE {0}, {1}", idx, CurrentUserId!)
            .AsEnumerable().FirstOrDefault();

        if (result is null || result.Success == 0)
            return JsonFail(StatusCodes.Status400BadRequest, result?.ReturnMsg ?? "삭제하지 못했습니다.");

        return JsonOk();
    }

    /// 표지 로고. 경로를 COVER/LOGO_PATH 코드에 저장한다.
    [AjaxAuth("ADMIN, SUPPORTER")]
    [HttpPost("code/logo")]
    [ValidateAntiForgeryToken]
    [Consumes("multipart/form-data")]
    [Produces("application/json")]
    public async Task<IActionResult> UploadCoverLogo(IFormFile file)
    {
        var maxBytes = _config.GetValue<long>("APP:MAX_UPLOAD_BYTES", 20 * 1024 * 1024);
        var result = await ImageUpload.SaveAsync(file, _env.ContentRootPath, "system", maxBytes);

        if (!result.Success)
            return JsonFail(StatusCodes.Status400BadRequest, result.Message ?? "업로드에 실패했습니다.");

        var saved = _db.ResultModel
            .FromSqlRaw("EXECUTE dbo.USP_S_MERGE_COMMON_CODE {0}, {1}, {2}, {3}, {4}, {5}",
                DBNull.Value, "COVER", "LOGO_PATH", result.WebPath!, 3, CurrentUserId!)
            .AsEnumerable().FirstOrDefault();

        // 이미 있는 코드면 INSERT 가 거부되므로 IDX 를 찾아 다시 저장한다.
        if (saved is null || saved.Success == 0)
        {
            var existing = _db.USP_S_SELECT_COMMON_CODE_LIST
                .FromSqlRaw("EXECUTE dbo.USP_S_SELECT_COMMON_CODE_LIST {0}", "COVER")
                .AsEnumerable().FirstOrDefault(c => c.CODE == "LOGO_PATH");

            if (existing is null)
                return JsonFail(StatusCodes.Status400BadRequest, "로고 경로를 저장하지 못했습니다.");

            _db.ResultModel
                .FromSqlRaw("EXECUTE dbo.USP_S_MERGE_COMMON_CODE {0}, {1}, {2}, {3}, {4}, {5}",
                    existing.IDX, "COVER", "LOGO_PATH", result.WebPath!, existing.ORDER_NUM, CurrentUserId!)
                .AsEnumerable().FirstOrDefault();
        }

        return JsonOk(new { path = result.WebPath });
    }
}
