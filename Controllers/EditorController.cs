using System.Data;
using ExodusSystemManual.Controllers.Attributes;
using ExodusSystemManual.Controllers.Common;
using ExodusSystemManual.Data;
using ExodusSystemManual.Models;
using ExodusSystemManual.Utils;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace ExodusSystemManual.Controllers;

/// 목차(섹션) 계층과 섹션별 본문 블록을 편집한다.
[Route("api/editor")]
public class EditorController : BaseController<EditorController>
{
    private readonly HtmlSanitize _sanitizer;

    public EditorController(
        ApplicationDbContext db,
        IWebHostEnvironment env,
        ILogger<EditorController> logger,
        IConfiguration config,
        HtmlSanitize sanitizer)
        : base(db, env, logger, config)
    {
        _sanitizer = sanitizer;
    }

    [AjaxAuth]
    [HttpGet("data")]
    [Produces("application/json")]
    public IActionResult GetDocument(string mid)
    {
        var denied = DenyIfNotReadable(mid, out var access);
        if (denied is not null) return denied;

        var header = _db.USP_S_SELECT_MANUAL
            .FromSqlRaw("EXECUTE dbo.USP_S_SELECT_MANUAL {0}", mid)
            .AsEnumerable().FirstOrDefault();

        var sections = _db.USP_S_SELECT_SECTION_LIST
            .FromSqlRaw("EXECUTE dbo.USP_S_SELECT_SECTION_LIST {0}, {1}", mid, CurrentUserId!)
            .AsEnumerable().ToList();

        var blocks = _db.USP_S_SELECT_ELEMENT_LIST
            .FromSqlRaw("EXECUTE dbo.USP_S_SELECT_ELEMENT_LIST {0}, {1}", mid, DBNull.Value)
            .AsEnumerable().ToList();

        return JsonOk(new { header, sections, blocks, access });
    }

    /* ================= 섹션(목차) ================= */

    /// secId 를 주면 그 목차 한 건만, 없으면 목차 목록을 돌려준다.
    [AjaxAuth]
    [HttpGet("sections")]
    [Produces("application/json")]
    public IActionResult GetSections(string mid, long? secId)
    {
        var denied = DenyIfNotReadable(mid);
        if (denied is not null) return denied;

        var sections = _db.USP_S_SELECT_SECTION_LIST
            .FromSqlRaw("EXECUTE dbo.USP_S_SELECT_SECTION_LIST {0}, {1}", mid, CurrentUserId!)
            .AsEnumerable().ToList();

        if (secId is null) return JsonOk(new { list = sections });

        var section = sections.FirstOrDefault(s => s.SEC_ID == secId);
        if (section is null) return JsonFail(StatusCodes.Status404NotFound, "목차를 찾을 수 없습니다.");

        return JsonOk(new { section });
    }

    [AjaxAuth]
    [HttpPost("section")]
    [ValidateAntiForgeryToken]
    [Produces("application/json")]
    public IActionResult MergeSection(InputSection input)
    {
        if (!ModelState.IsValid) return JsonFail(StatusCodes.Status400BadRequest, FirstError());

        var denied = DenyIfNotEditable(input.M_ID);
        if (denied is not null) return denied;

        var result = _db.ResultModel
            .FromSqlRaw("EXECUTE dbo.USP_S_MERGE_SECTION {0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}",
                (object?)input.SEC_ID ?? DBNull.Value,
                input.M_ID,
                input.TITLE,
                input.SEC_LEVEL,
                (object?)input.SEC_NO ?? DBNull.Value,
                (object?)input.ASSIGNED_TEAM ?? DBNull.Value,
                (object?)input.SEC_STATUS ?? DBNull.Value,
                (object?)input.STYLE_JSON ?? DBNull.Value,
                input.TITLE_ALIGN,
                input.SEC_TYPE,
                (object?)input.SHOW_IN_TOC ?? DBNull.Value,
                (object?)input.TITLE_UNDERLINE ?? DBNull.Value,
                CurrentUserId!)
            .AsEnumerable().FirstOrDefault();

        if (result is null || result.Success == 0)
            return JsonFail(StatusCodes.Status400BadRequest, result?.ReturnMsg ?? "섹션을 저장하지 못했습니다.");

        return JsonOk(new { SEC_ID = result.ReturnMsg });
    }

    [AjaxAuth]
    [HttpDelete("section")]
    [ValidateAntiForgeryToken]
    [Produces("application/json")]
    public IActionResult DeleteSection(long secId, string mid)
    {
        var denied = DenyIfNotEditable(mid);
        if (denied is not null) return denied;

        var result = _db.ResultModel
            .FromSqlRaw("EXECUTE dbo.USP_S_DELETE_SECTION {0}, {1}, {2}", secId, mid, CurrentUserId!)
            .AsEnumerable().FirstOrDefault();

        return ToJson(result);
    }

    /* ---------- 목차 수정 이력 ---------- */

    [AjaxAuth]
    [HttpGet("section/history")]
    [Produces("application/json")]
    public IActionResult GetSectionHistory(string mid, long secId)
    {
        var denied = DenyIfNotReadable(mid);
        if (denied is not null) return denied;

        var list = _db.USP_S_SELECT_SECTION_HISTORY
            .FromSqlRaw("EXECUTE dbo.USP_S_SELECT_SECTION_HISTORY {0}, {1}, {2}", mid, secId, 100)
            .AsEnumerable().ToList();

        return JsonOk(new { list });
    }

    /* ---------- 템플릿에서 옵션 목차 추가 ---------- */
    [AjaxAuth]
    [HttpGet("template-options")]
    [Produces("application/json")]
    public IActionResult GetTemplateOptions(string mid)
    {
        var denied = DenyIfNotReadable(mid);
        if (denied is not null) return denied;

        var list = _db.USP_S_SELECT_TEMPLATE_OPTION_LIST
            .FromSqlRaw("EXECUTE dbo.USP_S_SELECT_TEMPLATE_OPTION_LIST {0}", mid)
            .AsEnumerable().ToList();

        return JsonOk(new { list });
    }

    [AjaxAuth]
    [HttpPost("template-section")]
    [ValidateAntiForgeryToken]
    [Produces("application/json")]
    public IActionResult AddSectionFromTemplate(string mid, long tplId)
    {
        var denied = DenyIfNotEditable(mid);
        if (denied is not null) return denied;

        var result = _db.ResultModel
            .FromSqlRaw("EXECUTE dbo.USP_S_INSERT_SECTION_FROM_TEMPLATE {0}, {1}, {2}",
                mid, tplId, CurrentUserId!)
            .AsEnumerable().FirstOrDefault();

        if (result is null || result.Success == 0)
            return JsonFail(StatusCodes.Status400BadRequest, result?.ReturnMsg ?? "목차를 추가하지 못했습니다.");

        return JsonOk(new { SEC_ID = result.ReturnMsg });
    }

    [AjaxAuth]
    [HttpPost("section/order")]
    [ValidateAntiForgeryToken]
    [Produces("application/json")]
    public IActionResult UpdateSectionOrder(string mid, string orders)
    {
        var denied = DenyIfNotEditable(mid);
        if (denied is not null) return denied;

        if (string.IsNullOrWhiteSpace(orders))
            return JsonFail(StatusCodes.Status400BadRequest, "정렬 정보가 비어 있습니다.");

        var result = _db.ResultModel
            .FromSqlRaw("EXECUTE dbo.USP_S_UPDATE_SECTION_ORDER {0}, {1}, {2}", mid, orders, CurrentUserId!)
            .AsEnumerable().FirstOrDefault();

        return ToJson(result);
    }

    /* ================= 본문 블록 ================= */

    [AjaxAuth]
    [HttpPost("block")]
    [ValidateAntiForgeryToken]
    [Produces("application/json")]
    public IActionResult MergeBlock(InputElement input)
    {
        if (!ModelState.IsValid) return JsonFail(StatusCodes.Status400BadRequest, FirstError());

        var denied = DenyIfNotEditable(input.M_ID);
        if (denied is not null) return denied;

        byte[]? rowVer = null;
        if (!string.IsNullOrEmpty(input.ROW_VER))
        {
            try { rowVer = Convert.FromBase64String(input.ROW_VER); }
            catch (FormatException) { return JsonFail(StatusCodes.Status400BadRequest, "동시성 토큰이 올바르지 않습니다."); }
        }

        var safeHtml = _sanitizer.Clean(input.CONTENT_HTML);

        // ROW_VER 는 binary(8) 이라 타입을 명시하지 않으면 DBNull 이 nvarchar 로 전송되어 변환 오류가 난다.
        var parameters = new[]
        {
            Param("@ELE_ID", SqlDbType.BigInt, input.ELE_ID),
            Param("@M_ID", SqlDbType.VarChar, input.M_ID, 10),
            Param("@SEC_ID", SqlDbType.BigInt, input.SEC_ID),
            Param("@ELE_TYPE", SqlDbType.VarChar, input.ELE_TYPE, 20),
            Param("@ORDER_NUM", SqlDbType.Int, input.ORDER_NUM),
            Param("@WIDTH", SqlDbType.Float, input.WIDTH),
            Param("@HEIGHT", SqlDbType.Float, input.HEIGHT),
            Param("@CONTENT_HTML", SqlDbType.NVarChar, safeHtml, -1),
            Param("@IMAGE_PATH", SqlDbType.NVarChar, input.IMAGE_PATH, 500),
            Param("@CAPTION", SqlDbType.NVarChar, input.CAPTION, 500),
            Param("@STYLE_JSON", SqlDbType.NVarChar, input.STYLE_JSON, -1),
            Param("@ROW_VER", SqlDbType.Binary, rowVer, 8),
            Param("@USER_ID", SqlDbType.VarChar, CurrentUserId!, 20),
        };

        var result = _db.ResultModel
            .FromSqlRaw(
                "EXECUTE dbo.USP_S_MERGE_ELEMENT @ELE_ID, @M_ID, @SEC_ID, @ELE_TYPE, @ORDER_NUM, " +
                "@WIDTH, @HEIGHT, @CONTENT_HTML, @IMAGE_PATH, @CAPTION, @STYLE_JSON, @ROW_VER, @USER_ID",
                parameters)
            .AsEnumerable().FirstOrDefault();

        if (result is null || result.Success == 0)
        {
            if (result?.ReturnMsg == "CONFLICT")
                return JsonFail(StatusCodes.Status409Conflict, "다른 사용자가 먼저 수정했습니다. 새로고침 후 다시 시도하세요.");

            return JsonFail(StatusCodes.Status400BadRequest, result?.ReturnMsg ?? "블록을 저장하지 못했습니다.");
        }

        var saved = _db.USP_S_SELECT_ELEMENT_LIST
            .FromSqlRaw("EXECUTE dbo.USP_S_SELECT_ELEMENT_LIST {0}, {1}", input.M_ID, input.SEC_ID)
            .AsEnumerable()
            .FirstOrDefault(e => e.ELE_ID.ToString() == result.ReturnMsg);

        return JsonOk(new { block = saved });
    }

    [AjaxAuth]
    [HttpPost("block/order")]
    [ValidateAntiForgeryToken]
    [Produces("application/json")]
    public IActionResult UpdateBlockOrder(InputOrderBatch input)
    {
        if (!ModelState.IsValid) return JsonFail(StatusCodes.Status400BadRequest, FirstError());

        var denied = DenyIfNotEditable(input.M_ID);
        if (denied is not null) return denied;

        var result = _db.ResultModel
            .FromSqlRaw("EXECUTE dbo.USP_S_UPDATE_ELEMENT_ORDER {0}, {1}, {2}",
                input.M_ID, input.ORDERS, CurrentUserId!)
            .AsEnumerable().FirstOrDefault();

        return ToJson(result);
    }

    [AjaxAuth]
    [HttpDelete("block")]
    [ValidateAntiForgeryToken]
    [Produces("application/json")]
    public IActionResult DeleteBlock(long eleId, string mid)
    {
        var denied = DenyIfNotEditable(mid);
        if (denied is not null) return denied;

        var result = _db.ResultModel
            .FromSqlRaw("EXECUTE dbo.USP_S_DELETE_ELEMENT {0}, {1}, {2}", eleId, mid, CurrentUserId!)
            .AsEnumerable().FirstOrDefault();

        return ToJson(result);
    }

    /* ================= 이미지 / 문서 설정 ================= */

    [AjaxAuth]
    [HttpPost("image")]
    [ValidateAntiForgeryToken]
    [Consumes("multipart/form-data")]
    [Produces("application/json")]
    public async Task<IActionResult> UploadImage(string mid, IFormFile? upload, IFormFile? file)
    {
        var denied = DenyIfNotEditable(mid);
        if (denied is not null) return denied;

        var image = upload ?? file;
        if (image is null) return JsonFail(StatusCodes.Status400BadRequest, "이미지 파일을 선택하세요.");

        var maxBytes = _config.GetValue<long>("APP:MAX_UPLOAD_BYTES", 20 * 1024 * 1024);
        var result = await ImageUpload.SaveAsync(image, _env.ContentRootPath, mid, maxBytes);

        if (!result.Success)
            return JsonFail(StatusCodes.Status400BadRequest, result.Message ?? "업로드에 실패했습니다.");

        _db.TB_S_UPLOAD_FILE.Add(new UploadFile
        {
            F_TB_NAME = "TB_S_ELEMENT",
            F_CODE = mid,
            FILE_NAME = result.FileName!,
            PATH = result.WebPath!,
            WEB_PATH = result.WebPath!,
            CONTENT_TYPE = image.ContentType,
            SIZE = result.Size,
            REG_ID = CurrentUserId!,
            REG_DT = DateTime.Now,
        });
        _db.SaveChanges();

        // CKEditor SimpleUploadAdapter 규약: { url: "..." }
        return Ok(new { url = result.WebPath, success = true, data = new { path = result.WebPath } });
    }

    [AjaxAuth]
    [HttpPost("heading-style")]
    [ValidateAntiForgeryToken]
    [Produces("application/json")]
    public IActionResult SaveHeadingStyle(string mid, string style, string? bodyFont,
                                          decimal? lineHeight, decimal? letterSpacing)
    {
        var denied = DenyIfNotEditable(mid);
        if (denied is not null) return denied;

        var result = _db.ResultModel
            .FromSqlRaw("EXECUTE dbo.USP_S_UPDATE_DOC_STYLE {0}, {1}, {2}, {3}, {4}, {5}",
                mid, style,
                string.IsNullOrWhiteSpace(bodyFont) ? DBNull.Value : bodyFont,
                (object?)lineHeight ?? DBNull.Value,
                (object?)letterSpacing ?? DBNull.Value,
                CurrentUserId!)
            .AsEnumerable().FirstOrDefault();

        return ToJson(result);
    }

    /* ================= 공통 ================= */

    private static SqlParameter Param(string name, SqlDbType type, object? value, int size = 0)
    {
        var p = size == 0 ? new SqlParameter(name, type) : new SqlParameter(name, type, size);
        p.Value = value ?? DBNull.Value;
        return p;
    }


}
