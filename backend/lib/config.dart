import 'package:dotenv/dotenv.dart' as dotenv;

class Config {
  static final dotenv.DotEnv _env = dotenv.DotEnv();

  /// Load a .env file if present; no-op otherwise.
  static void loadEnv() => _env.load();

  static String get dbHost => _env['DB_HOST'] ?? '127.0.0.1';

  /// Default 64517 is the current dynamic TCP port of MSSQLSERVER01 on this machine.
  /// When the service restarts the port may change — re-check via:
  ///   $port = (Get-NetTCPConnection -OwningProcess <pid> -State Listen).LocalPort | Select -First 1
  /// or set DB_PORT in a .env file.
  static int get dbPort => int.tryParse(_env['DB_PORT'] ?? '1433') ?? 1433;

  static String get dbUser => _env['DB_USER'] ?? 'restaurant_user';

  static String get dbPassword => _env['DB_PASSWORD'] ?? 'your_password';

  static String get dbName => _env['DB_NAME'] ?? 'QLNH';
}
