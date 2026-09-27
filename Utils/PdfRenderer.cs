using Microsoft.AspNetCore.StaticFiles;
using Microsoft.Playwright;

namespace ExodusSystemManual.Utils;

/// 서버에서 Headless Chromium 으로 HTML 을 벡터 PDF 로 만든다. 브라우저는 한 번만 띄워 재사용한다.
public sealed class PdfRenderer : IAsyncDisposable
{
    // 문서와 정적 파일을 이 가짜 주소로 받아 wwwroot 에서 바로 읽는다. 그 밖의 요청은 모두 막는다.
    private const string Origin = "http://pdf.local";
    private const string DocumentPath = "/__document";
    private const int MaxParallelPages = 2;

    private readonly IWebHostEnvironment _env;
    private readonly ILogger<PdfRenderer> _logger;
    private readonly string? _channel;
    private readonly SemaphoreSlim _launchLock = new(1, 1);
    private readonly SemaphoreSlim _pageSlots = new(MaxParallelPages, MaxParallelPages);
    private readonly FileExtensionContentTypeProvider _contentTypes = new();
    private IPlaywright? _playwright;
    private IBrowser? _browser;

    public PdfRenderer(IWebHostEnvironment env, ILogger<PdfRenderer> logger, IConfiguration config)
    {
        _env = env;
        _logger = logger;
        var channel = config["PDF:BROWSER_CHANNEL"];
        _channel = string.IsNullOrWhiteSpace(channel) ? null : channel;
    }

    public async Task<byte[]> RenderAsync(string html, PagePdfOptions options, CancellationToken ct = default)
    {
        var browser = await GetBrowserAsync();

        await _pageSlots.WaitAsync(ct);
        try
        {
            await using var context = await browser.NewContextAsync();
            await context.RouteAsync("**/*", route => HandleRouteAsync(route, html));

            var page = await context.NewPageAsync();
            await page.GotoAsync(Origin + DocumentPath, new PageGotoOptions
            {
                WaitUntil = WaitUntilState.Load,
                Timeout = 60_000,
            });
            await page.EvaluateAsync("() => document.fonts.ready.then(() => true)");

            return await page.PdfAsync(options);
        }
        finally
        {
            _pageSlots.Release();
        }
    }

    private async Task HandleRouteAsync(IRoute route, string html)
    {
        if (!Uri.TryCreate(route.Request.Url, UriKind.Absolute, out var uri)
            || !string.Equals(uri.GetLeftPart(UriPartial.Authority), Origin, StringComparison.OrdinalIgnoreCase))
        {
            await route.AbortAsync();
            return;
        }

        if (uri.AbsolutePath == DocumentPath)
        {
            await route.FulfillAsync(new RouteFulfillOptions
            {
                Status = 200,
                ContentType = "text/html; charset=utf-8",
                Body = html,
            });
            return;
        }

        // PhysicalFileProvider 는 wwwroot 밖으로 나가는 경로와 숨김 파일을 NotFound 로 돌려준다.
        var file = _env.WebRootFileProvider.GetFileInfo(Uri.UnescapeDataString(uri.AbsolutePath));
        if (!file.Exists || file.IsDirectory || file.PhysicalPath is null)
        {
            _logger.LogWarning("PDF 리소스를 찾지 못했습니다: {Path}", uri.AbsolutePath);
            await route.FulfillAsync(new RouteFulfillOptions { Status = 404 });
            return;
        }

        if (!_contentTypes.TryGetContentType(file.Name, out var contentType))
            contentType = "application/octet-stream";

        await route.FulfillAsync(new RouteFulfillOptions
        {
            Status = 200,
            ContentType = contentType,
            Path = file.PhysicalPath,
        });
    }

    private async Task<IBrowser> GetBrowserAsync()
    {
        if (_browser is { IsConnected: true }) return _browser;

        await _launchLock.WaitAsync();
        try
        {
            if (_browser is { IsConnected: true }) return _browser;
            if (_browser is not null) await _browser.DisposeAsync();

            _playwright ??= await Playwright.CreateAsync();
            _browser = await _playwright.Chromium.LaunchAsync(new BrowserTypeLaunchOptions
            {
                Headless = true,
                Channel = _channel,
                Args = new[] { "--font-render-hinting=none" },
            });
            return _browser;
        }
        finally
        {
            _launchLock.Release();
        }
    }

    public async ValueTask DisposeAsync()
    {
        if (_browser is not null) await _browser.DisposeAsync();
        _playwright?.Dispose();
        _launchLock.Dispose();
        _pageSlots.Dispose();
    }
}
