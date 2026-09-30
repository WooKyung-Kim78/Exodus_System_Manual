using ExodusSystemManual.Bootstrap;
using ExodusSystemManual.Data;
using ExodusSystemManual.Utils;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.EntityFrameworkCore;

if (args.Length > 0 && args[0].Equals("seed-admin", StringComparison.OrdinalIgnoreCase))
{
    return await SeedAdminCommand.RunAsync(args);
}

var builder = WebApplication.CreateBuilder(args);

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
if (string.IsNullOrWhiteSpace(connectionString))
{
    throw new InvalidOperationException(
        "ConnectionStrings:DefaultConnection 이 비어 있습니다. " +
        "dotnet user-secrets set \"ConnectionStrings:DefaultConnection\" \"<연결문자열>\" 로 설정하세요.");
}

builder.Services.AddDbContext<ApplicationDbContext>(o => o.UseSqlServer(connectionString));

// Job Number(= datasheet NAME) 와 SPECIFICATIONS 는 exodus_datasheet DB 에서 읽는다.
// 값이 없으면 같은 서버/DB 에 datasheet 프로시저가 있다고 보고 기본 연결을 쓴다.
var datasheetConnectionString = builder.Configuration.GetConnectionString("DatasheetConnection");
builder.Services.AddDbContext<DatasheetDbContext>(o => o.UseSqlServer(
    string.IsNullOrWhiteSpace(datasheetConnectionString) ? connectionString : datasheetConnectionString));

builder.Services.AddControllers()
    .AddJsonOptions(o => o.JsonSerializerOptions.PropertyNamingPolicy = null);

builder.Services.AddDistributedMemoryCache();
builder.Services.AddMemoryCache();
builder.Services.AddSingleton<LoginThrottle>();
builder.Services.AddSingleton<HtmlSanitize>();
builder.Services.AddSingleton<PdfRenderer>();
builder.Services.AddScoped<SendMail>();
builder.Services.AddScoped<DatasheetSpec>();

// ajaxSetting.js 가 이 헤더로 토큰을 실어 보낸다.
builder.Services.AddAntiforgery(o => o.HeaderName = "RequestVerificationToken");

builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromHours(4);
    options.Cookie.Name = "ExodusSystemManual.SESSION";
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
    // Always 로 고정하면 개발중 http 접속 시 쾠키가 저장되지 않아 로그인이 유지되지 않는다.
    options.Cookie.SecurePolicy = builder.Environment.IsDevelopment()
        ? CookieSecurePolicy.SameAsRequest
        : CookieSecurePolicy.Always;
    options.Cookie.SameSite = SameSiteMode.Lax;
});

builder.Services.AddDataProtection()
    .PersistKeysToFileSystem(new DirectoryInfo(Path.Combine(builder.Environment.ContentRootPath, "App_Data", "keys")))
    .SetApplicationName("ExodusSystemManual");

builder.Services.Configure<FormOptions>(o =>
{
    o.MultipartBodyLengthLimit = builder.Configuration.GetValue<long>("APP:MAX_UPLOAD_BYTES", 20 * 1024 * 1024);
});

var app = builder.Build();

DevAutoLoginConfiguration.Validate(app.Environment, builder.Configuration);

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/api/health");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseSession();

if (DevAutoLoginConfiguration.ShouldRegister(app.Environment))
    app.UseMiddleware<DevAutoLogin>();

app.UseAuthorization();

app.MapControllers();

app.MapFallback(async context =>
{
    if (!SpaFallbackPolicy.ShouldServe(context.Request, app.Environment.IsDevelopment()))
    {
        context.Response.StatusCode = StatusCodes.Status404NotFound;
        return;
    }

    var index = Path.Combine(app.Environment.WebRootPath, "app", "index.html");
    if (!File.Exists(index))
    {
        context.Response.StatusCode = StatusCodes.Status503ServiceUnavailable;
        await context.Response.WriteAsync("프런트엔드 빌드 산출물이 없습니다. web/ 에서 npm run build 를 실행하세요.");
        return;
    }

    context.Response.ContentType = "text/html; charset=utf-8";
    await context.Response.SendFileAsync(index);
});

app.Run();
return 0;
