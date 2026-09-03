using ExodusSystemManual.Data;
using ExodusSystemManual.Models;
using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.AspNetCore.DataProtection;
using MimeKit;

namespace ExodusSystemManual.Utils;

public class SendMail
{
    private const string ProtectorPurpose = "ExodusSystemManual.SmtpPassword";

    private readonly ApplicationDbContext _db;
    private readonly IWebHostEnvironment _env;
    private readonly ILogger<SendMail> _logger;
    private readonly IDataProtector _protector;

    public SendMail(
        ApplicationDbContext db,
        IWebHostEnvironment env,
        ILogger<SendMail> logger,
        IDataProtectionProvider protectionProvider)
    {
        _db = db;
        _env = env;
        _logger = logger;
        _protector = protectionProvider.CreateProtector(ProtectorPurpose);
    }

    public string Protect(string plain) => _protector.Protect(plain);

    public MailSettings LoadSettings()
    {
        var rows = _db.TB_S_SETTING.Where(s => s.CATEGORY == "SMTP").ToList();
        string Get(string type) => rows.FirstOrDefault(r => r.TYPE == type)?.VALUE ?? string.Empty;

        var stored = Get("SYSTEM_EMAIL_PASSWORD");
        var password = string.Empty;
        if (!string.IsNullOrEmpty(stored))
        {
            // 암호화 이전에 저장된 평문 값도 그대로 쓸 수 있게 한다.
            try { password = _protector.Unprotect(stored); }
            catch (System.Security.Cryptography.CryptographicException) { password = stored; }
        }

        return new MailSettings
        {
            SystemName = string.IsNullOrWhiteSpace(Get("SYSTEM_NAME")) ? "EXODUS System Manual" : Get("SYSTEM_NAME"),
            FromEmail = Get("SYSTEM_EMAIL"),
            Host = Get("SYSTEM_SMTP"),
            Port = int.TryParse(Get("SYSTEM_SMTP_PORT"), out var p) ? p : 587,
            Secure = string.IsNullOrWhiteSpace(Get("SYSTEM_SMTP_SECURE")) ? "STARTTLS" : Get("SYSTEM_SMTP_SECURE"),
            UserId = Get("SYSTEM_EMAIL_ID"),
            Password = password,
            Scope = string.IsNullOrWhiteSpace(Get("SYSTEM_SMTP_SCOPE")) ? "T" : Get("SYSTEM_SMTP_SCOPE"),
        };
    }

    public async Task<(bool Success, string? Error)> SendAsync(
        string mailType,
        string? mId,
        IEnumerable<string> toList,
        string subject,
        string htmlBody,
        IEnumerable<string>? ccList = null,
        string? regId = null)
    {
        var to = toList.Where(a => !string.IsNullOrWhiteSpace(a)).Distinct().ToList();
        var cc = (ccList ?? Enumerable.Empty<string>())
            .Where(a => !string.IsNullOrWhiteSpace(a) && !to.Contains(a)).Distinct().ToList();

        if (to.Count == 0) return (false, "수신자가 없습니다.");

        var settings = LoadSettings();
        string? error = null;
        var success = false;

        try
        {
            var message = BuildMessage(settings, to, cc, subject, htmlBody);

            if (settings.IsTestScope)
            {
                await DropToDiskAsync(message);
                success = true;
            }
            else
            {
                if (string.IsNullOrWhiteSpace(settings.Host) || string.IsNullOrWhiteSpace(settings.FromEmail))
                    throw new InvalidOperationException("SMTP 설정이 완료되지 않았습니다. 관리 > 메일 설정을 확인하세요.");

                using var client = new SmtpClient();
                await client.ConnectAsync(settings.Host, settings.Port, ResolveSecurity(settings.Secure));

                if (!string.IsNullOrWhiteSpace(settings.UserId))
                    await client.AuthenticateAsync(settings.UserId, settings.Password);

                await client.SendAsync(message);
                await client.DisconnectAsync(true);
                success = true;
            }
        }
        catch (Exception ex)
        {
            error = ex.Message;
            _logger.LogError(ex, "메일 발송 실패. type={MailType} mid={MId}", mailType, mId);
        }

        _db.TB_S_MAIL_LOG.Add(new MailLog
        {
            M_ID = mId,
            MAIL_TYPE = mailType,
            TO_LIST = Truncate(string.Join(", ", to), 2000),
            CC_LIST = cc.Count > 0 ? Truncate(string.Join(", ", cc), 2000) : null,
            SUBJECT = Truncate(subject, 500),
            IS_SUCCESS = success ? "Y" : "N",
            ERROR_MSG = error is null ? null : Truncate(error, 2000),
            REG_ID = regId ?? "system",
            REG_DT = DateTime.Now,
        });
        await _db.SaveChangesAsync();

        return (success, error);
    }

    private static MimeMessage BuildMessage(
        MailSettings settings, List<string> to, List<string> cc, string subject, string htmlBody)
    {
        var message = new MimeMessage();
        message.From.Add(new MailboxAddress(
            settings.SystemName,
            string.IsNullOrWhiteSpace(settings.FromEmail) ? "no-reply@localhost" : settings.FromEmail));

        foreach (var address in to) message.To.Add(MailboxAddress.Parse(address));
        foreach (var address in cc) message.Cc.Add(MailboxAddress.Parse(address));

        message.Subject = subject;
        message.Body = new BodyBuilder { HtmlBody = htmlBody }.ToMessageBody();
        return message;
    }

    private async Task DropToDiskAsync(MimeMessage message)
    {
        var dir = Path.Combine(_env.ContentRootPath, "App_Data", "mail-drop");
        Directory.CreateDirectory(dir);

        var name = $"{DateTime.Now:yyyyMMdd-HHmmss-fff}.eml";
        await using var stream = File.Create(Path.Combine(dir, name));
        await message.WriteToAsync(stream);

        _logger.LogInformation("TEST 모드: 메일을 발송하지 않고 {Path} 에 저장했습니다.", Path.Combine(dir, name));
    }

    private static SecureSocketOptions ResolveSecurity(string secure) => secure.ToUpperInvariant() switch
    {
        "SSL" => SecureSocketOptions.SslOnConnect,
        "NONE" => SecureSocketOptions.None,
        _ => SecureSocketOptions.StartTls,
    };

    private static string Truncate(string value, int max)
        => value.Length <= max ? value : value[..max];
}
