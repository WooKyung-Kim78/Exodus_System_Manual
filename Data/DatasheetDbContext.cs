using ExodusSystemManual.Models;
using Microsoft.EntityFrameworkCore;

namespace ExodusSystemManual.Data;

/// exodus_datasheet 시스템 DB. 읽기 전용으로 저장 프로시저만 호출한다.
public class DatasheetDbContext : DbContext
{
    public DatasheetDbContext(DbContextOptions<DatasheetDbContext> options)
        : base(options) { }

    public DbSet<DatasheetPublishedItem> USP_DS_SELECT_MAIN_PUBLISHED { get; set; } = null!;
    public DbSet<DatasheetDetailItem> USP_DS_SELECT_DATASHEET_DETAIL { get; set; } = null!;
    public DbSet<DatasheetHeaderItem> USP_DS_SELECT_DATASHEET { get; set; } = null!;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<DatasheetPublishedItem>().HasNoKey().ToView(null);
        modelBuilder.Entity<DatasheetDetailItem>().HasNoKey().ToView(null);
        modelBuilder.Entity<DatasheetHeaderItem>().HasNoKey().ToView(null);
    }
}
