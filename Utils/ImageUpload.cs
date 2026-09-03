namespace ExodusSystemManual.Utils;

public record UploadResult(bool Success, string? Message, string? WebPath, string? FileName, long Size);

public static class ImageUpload
{
    private static readonly Dictionary<string, byte[][]> Signatures = new()
    {
        [".png"] = new[] { new byte[] { 0x89, 0x50, 0x4E, 0x47 } },
        [".jpg"] = new[] { new byte[] { 0xFF, 0xD8, 0xFF } },
        [".jpeg"] = new[] { new byte[] { 0xFF, 0xD8, 0xFF } },
        [".gif"] = new[] { new byte[] { 0x47, 0x49, 0x46, 0x38 } },
        [".webp"] = new[] { new byte[] { 0x52, 0x49, 0x46, 0x46 } },
    };

    public static async Task<UploadResult> SaveAsync(
        IFormFile file, string contentRootPath, string mId, long maxBytes)
    {
        if (file is null || file.Length == 0)
            return new UploadResult(false, "파일이 비어 있습니다.", null, null, 0);

        if (file.Length > maxBytes)
            return new UploadResult(false, $"파일이 너무 큽니다. (최대 {maxBytes / 1024 / 1024}MB)", null, null, 0);

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!Signatures.ContainsKey(ext))
            return new UploadResult(false, "이미지 파일(png, jpg, gif, webp)만 업로드할 수 있습니다.", null, null, 0);

        // 확장자만 바꿔 올린 파일을 막기 위해 매직 바이트를 확인한다.
        await using (var probe = file.OpenReadStream())
        {
            var head = new byte[8];
            var read = await probe.ReadAsync(head.AsMemory(0, head.Length));
            if (read < 4 || !Signatures[ext].Any(sig => head.Take(sig.Length).SequenceEqual(sig)))
                return new UploadResult(false, "파일 내용이 이미지 형식이 아닙니다.", null, null, 0);
        }

        var relativeDir = Path.Combine("Upload", mId);
        var absoluteDir = Path.Combine(contentRootPath, "wwwroot", relativeDir);
        Directory.CreateDirectory(absoluteDir);

        var storedName = Guid.NewGuid().ToString("N") + ext;
        var absolutePath = Path.Combine(absoluteDir, storedName);

        await using (var stream = new FileStream(absolutePath, FileMode.Create))
            await file.CopyToAsync(stream);

        var webPath = "/" + relativeDir.Replace('\\', '/') + "/" + storedName;
        return new UploadResult(true, null, webPath, file.FileName, file.Length);
    }

    public static void Delete(string contentRootPath, string? webPath)
    {
        if (string.IsNullOrWhiteSpace(webPath) || !webPath.StartsWith("/Upload/")) return;

        var absolute = Path.Combine(contentRootPath, "wwwroot", webPath.TrimStart('/').Replace('/', Path.DirectorySeparatorChar));
        if (File.Exists(absolute)) File.Delete(absolute);
    }
}
