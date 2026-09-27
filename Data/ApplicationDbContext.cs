using ExodusSystemManual.Models;
using Microsoft.EntityFrameworkCore;

namespace ExodusSystemManual.Data;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options) { }

    /* 테이블 */
    public DbSet<User> TB_S_USER { get; set; } = null!;
    public DbSet<Role> TB_S_ROLE { get; set; } = null!;
    public DbSet<SettingItem> TB_S_SETTING { get; set; } = null!;
    public DbSet<CommonCode> TB_S_MASTER_COMMON_CODE { get; set; } = null!;
    public DbSet<UploadFile> TB_S_UPLOAD_FILE { get; set; } = null!;
    public DbSet<MailLog> TB_S_MAIL_LOG { get; set; } = null!;
    public DbSet<Manual> TB_S_MANUAL { get; set; } = null!;
    public DbSet<ManualMember> TB_S_MANUAL_MEMBER { get; set; } = null!;
    public DbSet<Section> TB_S_SECTION { get; set; } = null!;
    public DbSet<CanvasElement> TB_S_ELEMENT { get; set; } = null!;
    public DbSet<ElementTableRow> TB_S_ELEMENT_TABLE_ROW { get; set; } = null!;
    public DbSet<ElementHistory> TB_S_ELEMENT_HISTORY { get; set; } = null!;
    public DbSet<Comment> TB_S_COMMENT { get; set; } = null!;
    public DbSet<Presence> TB_S_PRESENCE { get; set; } = null!;

    /* 저장 프로시저 결과 (DbSet 이름 = 프로시저 이름) */
    public DbSet<ResultModel> ResultModel { get; set; } = null!;
    public DbSet<ManualAccess> USP_S_SELECT_MANUAL_ACCESS { get; set; } = null!;
    public DbSet<ManualHeader> USP_S_SELECT_MANUAL { get; set; } = null!;
    public DbSet<ManualListItem> USP_S_SELECT_MANUAL_LIST_BY_STATUS { get; set; } = null!;
    public DbSet<ManualMemberItem> USP_S_SELECT_MANUAL_MEMBER_LIST { get; set; } = null!;
    public DbSet<SectionItem> USP_S_SELECT_SECTION_LIST { get; set; } = null!;
    public DbSet<ElementItem> USP_S_SELECT_ELEMENT_LIST { get; set; } = null!;
    public DbSet<TeamItem> USP_S_SELECT_USER_TEAM_LIST { get; set; } = null!;
    public DbSet<UserSearchItem> USP_S_SELECT_USER_SEARCH_LIST { get; set; } = null!;
    public DbSet<NotifyRecipient> USP_S_SELECT_NOTIFY_RECIPIENT_LIST { get; set; } = null!;
    public DbSet<SectionTemplateItem> USP_S_SELECT_SECTION_TEMPLATE_LIST { get; set; } = null!;
    public DbSet<TemplateOptionItem> USP_S_SELECT_TEMPLATE_OPTION_LIST { get; set; } = null!;
    public DbSet<UserAdminItem> USP_S_SELECT_USER_LIST { get; set; } = null!;
    public DbSet<SectionHistoryItem> USP_S_SELECT_SECTION_HISTORY { get; set; } = null!;
    public DbSet<CommonCodeItem> USP_S_SELECT_COMMON_CODE_LIST { get; set; } = null!;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Presence>().HasKey(p => new { p.M_ID, p.CLIENT_ID });

        // 저장 프로시저 결과는 테이블이 아니므로 키 없이 매핑한다.
        modelBuilder.Entity<ResultModel>().HasNoKey().ToView(null);
        modelBuilder.Entity<ManualAccess>().HasNoKey().ToView(null);
        modelBuilder.Entity<ManualHeader>().HasNoKey().ToView(null);
        modelBuilder.Entity<ManualListItem>().HasNoKey().ToView(null);
        modelBuilder.Entity<ManualMemberItem>().HasNoKey().ToView(null);
        modelBuilder.Entity<SectionItem>().HasNoKey().ToView(null);
        modelBuilder.Entity<ElementItem>().HasNoKey().ToView(null);
        modelBuilder.Entity<TeamItem>().HasNoKey().ToView(null);
        modelBuilder.Entity<UserSearchItem>().HasNoKey().ToView(null);
        modelBuilder.Entity<NotifyRecipient>().HasNoKey().ToView(null);
        modelBuilder.Entity<SectionTemplateItem>().HasNoKey().ToView(null);
        modelBuilder.Entity<TemplateOptionItem>().HasNoKey().ToView(null);
        modelBuilder.Entity<UserAdminItem>().HasNoKey().ToView(null);
        modelBuilder.Entity<SectionHistoryItem>().HasNoKey().ToView(null);
        modelBuilder.Entity<CommonCodeItem>().HasNoKey().ToView(null);
    }
}
