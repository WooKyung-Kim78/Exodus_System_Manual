using ExodusSystemManual.Utils;
using Microsoft.AspNetCore.Http;

namespace ExodusSystemManual.Tests.Utils;

public sealed class ImageUploadTests : IDisposable
{
    private static readonly byte[] PngHead = { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A };
    private const long Max = 1024 * 1024;

    private readonly string _root = Path.Combine(Path.GetTempPath(), "exodus-test-" + Guid.NewGuid().ToString("N"));

    public void Dispose()
    {
        if (Directory.Exists(_root)) Directory.Delete(_root, recursive: true);
    }

    private static FormFile File(string name, byte[] content)
        => new(new MemoryStream(content), 0, content.Length, "file", name);

    [Fact]
    public async Task Saves_valid_png_under_manual_folder_with_generated_name()
    {
        var result = await ImageUpload.SaveAsync(File("../evil name.png", PngHead), _root, "M000000001", Max);

        Assert.True(result.Success);
        Assert.StartsWith("/Upload/M000000001/", result.WebPath);
        Assert.DoesNotContain("evil", result.WebPath!);
        Assert.True(System.IO.File.Exists(Path.Combine(_root, "wwwroot", result.WebPath!.TrimStart('/'))));
    }

    [Fact]
    public async Task Rejects_disallowed_extension()
    {
        var result = await ImageUpload.SaveAsync(File("a.exe", PngHead), _root, "M1", Max);
        Assert.False(result.Success);
    }

    [Fact]
    public async Task Rejects_content_that_does_not_match_extension()
    {
        var result = await ImageUpload.SaveAsync(File("a.png", "not an image at all"u8.ToArray()), _root, "M1", Max);
        Assert.False(result.Success);
    }

    [Fact]
    public async Task Rejects_empty_and_oversized_files()
    {
        Assert.False((await ImageUpload.SaveAsync(File("a.png", Array.Empty<byte>()), _root, "M1", Max)).Success);
        Assert.False((await ImageUpload.SaveAsync(File("a.png", PngHead), _root, "M1", maxBytes: 4)).Success);
    }

    [Fact]
    public async Task Writes_nothing_when_rejected()
    {
        await ImageUpload.SaveAsync(File("a.png", "text"u8.ToArray()), _root, "M1", Max);
        Assert.False(Directory.Exists(Path.Combine(_root, "wwwroot", "Upload")));
    }
}
