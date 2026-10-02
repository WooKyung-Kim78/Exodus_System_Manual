using System.Text.Json;
using System.Text.Json.Nodes;

namespace ExodusSystemManual.Utils;

/// <summary>표의 서식 열 HTML을 저장 전 정제한다.</summary>
public static class TableStyleJsonSanitizer
{
    public static string? Clean(string? json, HtmlSanitize sanitizer)
    {
        if (string.IsNullOrWhiteSpace(json)) return json;

        JsonNode? root;
        try { root = JsonNode.Parse(json); }
        catch (JsonException) { return null; }

        if (root is not JsonObject table) return null;
        if (table["rich"] is not JsonArray rich || table["rows"] is not JsonArray rows) return json;

        foreach (var row in rows.OfType<JsonArray>())
        {
            for (var i = 0; i < row.Count && i < rich.Count; i++)
            {
                if (rich[i] is not JsonValue flag || !flag.TryGetValue<bool>(out var isRich) || !isRich) continue;
                row[i] = row[i] is JsonValue cell && cell.TryGetValue<string>(out var html)
                    ? sanitizer.Clean(html)
                    : string.Empty;
            }
        }

        return table.ToJsonString();
    }
}
