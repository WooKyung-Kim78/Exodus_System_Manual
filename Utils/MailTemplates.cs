using System.Net;
using ExodusSystemManual.Models;

namespace ExodusSystemManual.Utils;

public static class MailTemplates
{
    public static (string Subject, string Body) EditRequest(
        ManualHeader header, NotifyRecipient recipient, string appDomain, string requesterName, string? memo)
    {
        var subject = $"[System Manual] 작성 요청 - {header.DOC_NUM} {header.MODEL_NAME}";
        var link = $"{appDomain.TrimEnd('/')}/canvas?mid={WebUtility.UrlEncode(header.M_ID)}";

        var assigned = recipient.SECTION_CNT > 0
            ? $"<p><b>담당 섹션 {recipient.SECTION_CNT}개</b><br/>{Escape(recipient.ASSIGNED_SECTIONS)}</p>"
            : "<p>배정된 섹션이 없습니다. 문서 화면에서 담당 섹션을 확인해 주세요.</p>";

        var memoBlock = string.IsNullOrWhiteSpace(memo)
            ? string.Empty
            : $"<p style='background:#f5f6f8;padding:12px;border-radius:6px'>{Escape(memo)}</p>";

        var body = $@"
<div style=""font-family:'Malgun Gothic',sans-serif;font-size:14px;color:#181c32;line-height:1.6"">
  <p>{Escape(recipient.FULL_NAME)} 님,</p>
  <p>{Escape(requesterName)} 님이 아래 System Manual 작성을 요청했습니다.</p>
  {memoBlock}
  <table style=""border-collapse:collapse;margin:16px 0"">
    {Row("문서번호", header.DOC_NUM)}
    {Row("Model Name", header.MODEL_NAME)}
    {Row("Job Number", header.JOB_NUMBER)}
    {Row("Label", header.LABEL)}
    {Row("Cooling", header.COOLING)}
    {Row("Revision", header.REVISION)}
    {Row("역할", RoleLabel(recipient.MEMBER_ROLE))}
  </table>
  {assigned}
  <p style=""margin:24px 0"">
    <a href=""{link}"" style=""background:#1b84ff;color:#fff;padding:10px 20px;border-radius:6px;text-decoration:none"">
      캔버스에서 작성하기
    </a>
  </p>
  <p style=""color:#78829d;font-size:12px"">{link}</p>
  <hr style=""border:none;border-top:1px solid #e4e6ef;margin:24px 0"" />
  <p style=""color:#78829d;font-size:12px"">
    이 메일은 시스템이 자동으로 보냈습니다. 회신하지 마세요.<br/>
    Copyright Exodus Advanced Communications. All rights reserved.
  </p>
</div>";

        return (subject, body);
    }

    public static (string Subject, string Body) MemberInvited(
        ManualHeader header, NotifyRecipient recipient, string appDomain, string inviterName)
    {
        var subject = $"[System Manual] 참여자로 추가되었습니다 - {header.DOC_NUM} {header.MODEL_NAME}";
        var link = $"{appDomain.TrimEnd('/')}/manual/detail?mid={WebUtility.UrlEncode(header.M_ID)}";

        var body = $@"
<div style=""font-family:'Malgun Gothic',sans-serif;font-size:14px;color:#181c32;line-height:1.6"">
  <p>{Escape(recipient.FULL_NAME)} 님,</p>
  <p>{Escape(inviterName)} 님이 회원님을 아래 문서의 <b>{RoleLabel(recipient.MEMBER_ROLE)}</b>로 추가했습니다.</p>
  <table style=""border-collapse:collapse;margin:16px 0"">
    {Row("문서번호", header.DOC_NUM)}
    {Row("Model Name", header.MODEL_NAME)}
    {Row("Job Number", header.JOB_NUMBER)}
  </table>
  <p style=""margin:24px 0"">
    <a href=""{link}"" style=""background:#1b84ff;color:#fff;padding:10px 20px;border-radius:6px;text-decoration:none"">
      문서 열기
    </a>
  </p>
  <p style=""color:#78829d;font-size:12px"">{link}</p>
  <hr style=""border:none;border-top:1px solid #e4e6ef;margin:24px 0"" />
  <p style=""color:#78829d;font-size:12px"">
    이 메일은 시스템이 자동으로 보냈습니다. 회신하지 마세요.
  </p>
</div>";

        return (subject, body);
    }

    private static string Row(string label, string? value) => $@"
    <tr>
      <td style=""padding:4px 16px 4px 0;color:#78829d"">{Escape(label)}</td>
      <td style=""padding:4px 0;font-weight:600"">{Escape(value ?? "-")}</td>
    </tr>";

    private static string RoleLabel(string role) => role switch
    {
        "OWNER" => "문서 소유자",
        "APPROVER" => "승인자",
        "REVIEWER" => "검토자",
        _ => "작성자",
    };

    // 사용자 입력(모델명, 메모 등)이 메일 본문에 그대로 들어가므로 반드시 이스케이프한다.
    private static string Escape(string? value) => WebUtility.HtmlEncode(value ?? string.Empty);
}
