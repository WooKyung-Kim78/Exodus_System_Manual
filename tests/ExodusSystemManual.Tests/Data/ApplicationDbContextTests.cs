using ExodusSystemManual.Data;
using ExodusSystemManual.Models;
using Microsoft.EntityFrameworkCore;

namespace ExodusSystemManual.Tests.Data;

public class ApplicationDbContextTests
{
    [Fact]
    public void ManualHeader_decimal_properties_have_expected_precision()
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseSqlServer("Server=(localdb)\\mssqllocaldb;Database=ExodusModelTest;Trusted_Connection=True")
            .Options;
        using var db = new ApplicationDbContext(options);

        var entity = db.Model.FindEntityType(typeof(ManualHeader))!;

        Assert.Equal(4, entity.FindProperty(nameof(ManualHeader.BODY_LINE_HEIGHT))!.GetPrecision());
        Assert.Equal(1, entity.FindProperty(nameof(ManualHeader.BODY_LINE_HEIGHT))!.GetScale());
        Assert.Equal(4, entity.FindProperty(nameof(ManualHeader.BODY_LETTER_SPACING))!.GetPrecision());
        Assert.Equal(1, entity.FindProperty(nameof(ManualHeader.BODY_LETTER_SPACING))!.GetScale());
    }
}
