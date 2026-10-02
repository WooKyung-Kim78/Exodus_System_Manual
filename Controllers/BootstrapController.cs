using ExodusSystemManual.Controllers.Common;
using ExodusSystemManual.Data;
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

}
