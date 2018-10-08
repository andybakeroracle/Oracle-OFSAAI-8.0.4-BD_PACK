import java.sql.*;
/**
 * Run arguments sample:
 * jdbc:oracle:thin:@localhost:1521:XE system mypassword123 oracle.jdbc.driver.OracleDriver
 */
public class DbConn {
    public static void main(String[] args) throws Exception {
        String url = args[0];
        String username = args[1];
        String password = args[2];
        String driver = args[3];

        Class.forName(driver);
        Connection conn = DriverManager.getConnection(url, username, password);
        try {
            Statement statement = conn.createStatement();
            ResultSet rs = statement.executeQuery("SELECT SYSDATE FROM DUAL");
            while(rs.next()) {
                System.out.println(rs.getObject(1));
            }
        } finally {
            conn.close();
        }
    }
}
