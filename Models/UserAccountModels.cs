using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ExodusSystemManual.Models;

[Table("TB_S_USER")]
public class User
{
    [Key]
    public long IDX { get; set; }
    public string USER_ID { get; set; } = null!;
    public string PASSWORD { get; set; } = null!;
    public string FULL_NAME { get; set; } = null!;
    public string? EMAIL { get; set; }
    public string? DIVISION { get; set; }
    public string? TEAM { get; set; }
    public string AUTHORIZED { get; set; } = "S";
    public string? SUPERVISOR_USER_ID { get; set; }
    public string? IS_SUPERVISOR { get; set; }
    public string IS_DELETED { get; set; } = "N";
    public string REG_ID { get; set; } = null!;
    public DateTime REG_DT { get; set; }
    public string? UPT_ID { get; set; }
    public DateTime? UPT_DT { get; set; }
}

[Table("TB_S_ROLE")]
public class Role
{
    [Key]
    public long IDX { get; set; }
    public string USER_ID { get; set; } = null!;
    public string ROLE_NAME { get; set; } = null!;
    public string IS_DELETED { get; set; } = "N";
    public string REG_ID { get; set; } = null!;
    public DateTime REG_DT { get; set; }
    public string? UPT_ID { get; set; }
    public DateTime? UPT_DT { get; set; }
}

public class UserLoginInputModel
{
    [Required(ErrorMessage = "Please enter ID.")]
    public string? USER_ID { get; set; }

    [Required(ErrorMessage = "Please enter password.")]
    public string? PASSWORD { get; set; }
}
