using System.Diagnostics;
using ExodusSystemManual.Controllers.Attributes;
using ExodusSystemManual.Controllers.Common;
using ExodusSystemManual.Data;
using Microsoft.AspNetCore.Mvc;
using ExodusSystemManual.Models;

namespace ExodusSystemManual.Controllers;

public class HomeController : BaseController<HomeController>
{
    public HomeController(
        ApplicationDbContext db,
        IWebHostEnvironment env,
        ILogger<HomeController> logger,
        IConfiguration config)
        : base(db, env, logger, config) { }

    [Auth]
    public IActionResult Index()
    {
        return View();
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }
}
