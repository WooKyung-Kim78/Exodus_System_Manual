using Microsoft.Data.SqlClient;

namespace ExodusSystemManual.Tests.Integration;

/// Database/ 스크립트가 모두 적용된 전용 테스트 DB 가 필요하다.
public class PermissionFunctionTests
{
    private static string Scalar(string sql)
    {
        using var conn = new SqlConnection(RequiresDbFactAttribute.ConnectionString);
        conn.Open();
        using var cmd = new SqlCommand(sql, conn);
        return (string)cmd.ExecuteScalar()!;
    }

    [RequiresDbFact]
    public void Unknown_user_cannot_read_or_edit()
    {
        Assert.Equal("N", Scalar("SELECT dbo.UFN_S_CAN_READ_MANUAL('NO_SUCH_M', 'NO_SUCH_USER')"));
        Assert.Equal("N", Scalar("SELECT dbo.UFN_S_IS_MANUAL_PARTICIPANT('NO_SUCH_M', 'NO_SUCH_USER')"));
        Assert.Equal("N", Scalar("SELECT dbo.UFN_S_CAN_EDIT_SECTION(-1, 'NO_SUCH_USER')"));
    }
}
