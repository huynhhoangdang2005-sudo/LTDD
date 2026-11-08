import 'package:mssql/mssql.dart';
import 'package:logging/logging.dart';
import 'config.dart';

final _log = Logger('Database');

/// Wraps an [MssqlConnection] and offers a small, route-friendly surface:
///  * [query]    -> returns List<Map<String,dynamic>> (rows by column name)
///  * [execute]  -> returns affected-row count
///  * [insertId] -> runs an INSERT then returns SCOPE_IDENTITY()
///
/// Positional `?` placeholders are translated to named `@p0, @p1...`
/// parameters, matching how the original MySQL code passed `[params]`.
class DbConn {
  final MssqlConnection _conn;
  DbConn(this._conn);

  MssqlConnection get raw => _conn;

  Future<List<Map<String, dynamic>>> query(
    String sql, [
    List<Object?>? params,
  ]) async {
    final p = _prep(sql, params);
    final res = await _conn.query(p.sql, p.params);
    return res.rows.map(_toMap).toList();
  }

  Future<int> execute(String sql, [List<Object?>? params]) async {
    final p = _prep(sql, params);
    return await _conn.execute(p.sql, p.params);
  }

  /// Runs an INSERT and returns the generated IDENTITY value.
  ///
  /// The package executes parameterized statements through sp_executesql
  /// (a separate RPC scope), so a *separate* `SELECT SCOPE_IDENTITY()` sees
  /// no scope and returns NULL. Instead, append the identity lookup to the
  /// SAME statement. The INSERT only yields a "rows affected" record, so the
  /// SELECT is the first real result set; scan every set for the `id` column.
  Future<int> insertId(String sql, [List<Object?>? params]) async {
    final p = _prep(sql, params);
    final stmt = p.sql.trimRight();
    final combined =
        (stmt.endsWith(';') ? stmt : '$stmt;') +
        ' SELECT CAST(SCOPE_IDENTITY() AS INT) AS id';
    final multi = await _conn.queryMultiple(combined, p.params);
    for (final set in multi.all) {
      if (set.isEmpty) continue;
      final row = set.rows.first;
      if (row.columnNames.contains('id')) {
        final id = row['id'];
        if (id != null) return id as int;
      }
    }
    throw Exception('insertId: no identity value returned');
  }

  // --- helpers -------------------------------------------------------------

  Map<String, dynamic> _toMap(MssqlRow row) {
    final m = <String, dynamic>{};
    for (final col in row.columnNames) {
      var v = row[col];
      if (v is DateTime) v = v.toIso8601String(); // clean ISO strings for the app
      m[col] = v;
    }
    return m;
  }

  /// Translate `?` placeholders to `@p0, @p1, ...` and build a named map.
  _Prepared _prep(String sql, [List<Object?>? params]) {
    if (params == null || params.isEmpty) {
      return _Prepared(sql, const <String, dynamic>{});
    }
    final n = params.length;
    final names = List<String>.generate(n, (i) => 'p$i');
    final sb = StringBuffer();
    var pi = 0;
    for (var i = 0; i < sql.length; i++) {
      final ch = sql[i];
      if (ch == '?' && pi < n) {
        sb.write('@');
        sb.write(names[pi]);
        pi++;
      } else {
        sb.write(ch);
      }
    }
    final map = <String, dynamic>{};
    for (var j = 0; j < n; j++) {
      map['p$j'] = params[j];
    }
    return _Prepared(sb.toString(), map);
  }
}

class _Prepared {
  final String sql;
  final Map<String, dynamic> params;
  _Prepared(this.sql, this.params);
}

/// Manages a single pooled [MssqlConnection] with auto-reconnect.
class Database {
  static MssqlConnection? _conn;
  static DbConn? _db;
  static bool _schemaReady = false;

  /// Returns an active [DbConn], reconnecting if the link was lost.
  static Future<DbConn> getConnection() async {
    if (_conn != null) {
      try {
        await _conn!.query('SELECT 1');
      } catch (_) {
        _log.warning('SQL Server connection lost. Reconnecting...');
        try {
          await _conn?.close();
        } catch (_) {}
        _conn = null;
        _db = null;
      }
    }

    if (_conn == null) {
      _log.info(
        'Connecting to SQL Server (${Config.dbHost}:${Config.dbPort}, DB: ${Config.dbName})...',
      );
      final conn = await MssqlConnection.connect(
        host: Config.dbHost,
        port: Config.dbPort,
        user: Config.dbUser,
        password: Config.dbPassword,
        database: Config.dbName,
        encrypt: false, // local dev; flip for TLS in prod
        trustServerCertificate: true,
        timeout: const Duration(seconds: 15),
      );
      _conn = conn;
      _db = DbConn(conn);
      if (!_schemaReady) {
        await _ensureSchema(_conn!);
        _schemaReady = true;
      }
      _log.info('SQL Server connection established.');
    }
    return _db!;
  }

  /// Lightweight guard: warn if the 6 core tables are missing.
  /// (The schema itself is created by RestaurantDB.sql.)
  static Future<void> _ensureSchema(MssqlConnection conn) async {
    final res = await conn.query(
      "SELECT name FROM sys.tables "
      "WHERE name IN ('users','categories','menu_items','tables','orders','order_items')",
    );
    final found = res.rows.map((r) => r['name'].toString()).toSet();
    final required = [
      'users',
      'categories',
      'menu_items',
      'tables',
      'orders',
      'order_items'
    ];
    final missing = required.where((t) => !found.contains(t)).toList();
    if (missing.isNotEmpty) {
      _log.warning('Missing tables: $missing — run RestaurantDB.sql to create the schema.');
    } else {
      _log.info('Schema check OK: all 6 core tables present.');
    }
  }
}
