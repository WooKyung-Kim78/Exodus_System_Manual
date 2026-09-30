using ExodusSystemManual.Controllers.Common;
using ExodusSystemManual.Controllers.Attributes;
using ExodusSystemManual.Data;
using ExodusSystemManual.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;

namespace ExodusSystemManual.Controllers;

[Route("api")]
public class BootstrapController : BaseController<BootstrapController>
{
    public BootstrapController(ApplicationDbContext db, IWebHostEnvironment env, ILogger<BootstrapController> logger, IConfiguration config)
        : base(db, env, logger, config) { }

    [HttpGet("health")]
    [AllowAnonymous]
    [Produces("application/json")]
    public IActionResult Health() => Ok(new { success = true, data = new { status = "ok" } });

    [HttpGet("bootstrap")]
    [AjaxAuth]
    [Produces("application/json")]
    public IActionResult Bootstrap() => JsonOk(new
    {
        isDevelopment = _env.IsDevelopment(),
        headingStyles = HeadingStyle.ClientDefaults(),
        bodyFonts = new[]
        {
            new { code = "ARIAL", name = "Arial" },
            new { code = "CARLITO", name = "Carlito" },
            new { code = "VERDANA", name = "Verdana" },
            new { code = "TAHOMA", name = "Tahoma" },
            new { code = "GEORGIA", name = "Georgia" },
            new { code = "TIMES", name = "Times New Roman" },
        },
    });
}
