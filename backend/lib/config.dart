import 'package:dotenv/dotenv.dart' as dotenv;

class Config {
  static final dotenv.DotEnv _env = dotenv.DotEnv();

  static void loadEnv() {
    // Load .env if present; no‑op otherwise.
    _env.load();
  }

  static String get dbHost => _env['DB_HOST'] ?? '127.0.0.1';
  static int get dbPort => int.tryParse(_env['DB_PORT'] ?? '3306') ?? 3306;
  static String get dbUser => _env['DB_USER'] ?? 'restaurant_user';
  static String get dbPassword => _env['DB_PASSWORD'] ?? 'your_password';
  static String get dbName => _env['DB_NAME'] ?? 'restaurant_db';
}
