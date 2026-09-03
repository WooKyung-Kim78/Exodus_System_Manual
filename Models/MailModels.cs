namespace ExodusSystemManual.Models;

public class NotifyRecipient
{
    public string USER_ID { get; set; } = null!;
    public string MEMBER_ROLE { get; set; } = null!;
    public string FULL_NAME { get; set; } = null!;
    public string? EMAIL_ADDRESS { get; set; }
    public string? TEAM { get; set; }
    public int SECTION_CNT { get; set; }
    public string? ASSIGNED_SECTIONS { get; set; }
}

public class MailSettings
{
    public string SystemName { get; set; } = "EXODUS System Manual";
    public string FromEmail { get; set; } = string.Empty;
    public string Host { get; set; } = string.Empty;
    public int Port { get; set; } = 587;
    public string Secure { get; set; } = "STARTTLS";
    public string UserId { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;

    /// T = 실제 발송하지 않고 App_Data/mail-drop 에 저장, P = 실제 발송
    public string Scope { get; set; } = "T";

    public bool IsTestScope => !string.Equals(Scope, "P", StringComparison.OrdinalIgnoreCase);
}

public class InputMailSetting
{
    public string SYSTEM_NAME { get; set; } = string.Empty;
    public string SYSTEM_EMAIL { get; set; } = string.Empty;
    public string SYSTEM_SMTP { get; set; } = string.Empty;
    public string SYSTEM_SMTP_PORT { get; set; } = "587";
    public string SYSTEM_SMTP_SECURE { get; set; } = "STARTTLS";
    public string SYSTEM_EMAIL_ID { get; set; } = string.Empty;

    /// 비어 있으면 기존 비밀번호를 유지한다.
    public string? SYSTEM_EMAIL_PASSWORD { get; set; }

    public string SYSTEM_SMTP_SCOPE { get; set; } = "T";
}
