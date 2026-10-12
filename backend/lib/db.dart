import 'package:mysql1/mysql1.dart';
import 'package:logging/logging.dart';
import 'config.dart';

final _log = Logger('Database');

class Database {
  static MySqlConnection? _conn;
  static bool _schemaReady = false;

  static ConnectionSettings get settings => ConnectionSettings(
        host: Config.dbHost,
        port: Config.dbPort,
        user: Config.dbUser,
        password: Config.dbPassword,
        db: Config.dbName,
      );

  /// Returns an active MySQL connection.
  /// Automatically pings and reconnects if the connection was closed due to inactivity timeout.
  static Future<MySqlConnection> getConnection() async {
    if (_conn != null) {
      try {
        await _conn!.query('SELECT 1');
      } catch (e) {
        _log.warning('MySQL connection lost ($e). Reconnecting...');
        try {
          await _conn?.close();
        } catch (_) {}
        _conn = null;
      }
    }

    if (_conn == null) {
      _log.info(
          'Connecting to MySQL (${Config.dbHost}:${Config.dbPort}, DB: ${Config.dbName})...');
      _conn = await MySqlConnection.connect(settings);
      _log.info('MySQL connection established.');
    }

    if (!_schemaReady) {
      await _ensureRequiredColumns(_conn!);
      await _conn!.query(
        "UPDATE users SET role = 'Quản lý' WHERE username = 'admin' AND role = 'Khách hàng'",
      );
      _schemaReady = true;
    }
    return _conn!;
  }

  static Future<void> _ensureRequiredColumns(MySqlConnection connection) async {
    const columns = <List<String>>[
      ['users', 'full_name', "VARCHAR(100) NOT NULL DEFAULT ''"],
      ['users', 'role', "VARCHAR(40) NOT NULL DEFAULT 'Khách hàng'"],
      ['users', 'status', "VARCHAR(20) NOT NULL DEFAULT 'active'"],
      ['users', 'phone', "VARCHAR(30) NOT NULL DEFAULT ''"],
      ['menu_items', 'image_url', "VARCHAR(500) NOT NULL DEFAULT ''"],
      ['menu_items', 'available', 'BOOLEAN NOT NULL DEFAULT TRUE'],
      ['tables', 'status', "VARCHAR(30) NOT NULL DEFAULT 'Trống'"],
    ];

    for (final column in columns) {
      final tableName = column[0];
      final columnName = column[1];
      final definition = column[2];
      final existing = await connection.query(
        "SHOW COLUMNS FROM `$tableName` LIKE '$columnName'",
      );
      if (existing.isEmpty) {
        await connection.query(
            'ALTER TABLE `$tableName` ADD COLUMN `$columnName` $definition');
        _log.info('Added missing database column $tableName.$columnName.');
      }
    }
  }
}
