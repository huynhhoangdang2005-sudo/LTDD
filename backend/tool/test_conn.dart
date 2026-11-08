import 'dart:io';
import 'package:mssql/mssql.dart';

Future<void> main() async {
  for (int attempt = 1; attempt <= 5; attempt++) {
    MssqlConnection? conn;
    try {
      print('Attempt $attempt: connecting...');
      conn = await MssqlConnection.connect(
        host: '127.0.0.1', port: 64517,
        user: 'restaurant_user', password: 'your_password', database: 'QLNH',
        encrypt: false, trustServerCertificate: true,
        timeout: const Duration(seconds: 20),
      );
      final v = await conn.query('SELECT 1 AS ok', const <String, dynamic>{});
      print('CONNECTED OK: ' + v.rows.first['ok'].toString());
      // quick: count open connections
      try {
        final c = await conn.query(
            'SELECT COUNT(*) AS n FROM sys.dm_exec_sessions', const <String, dynamic>{});
        print('open sessions=' + c.rows.first['n'].toString());
      } catch (_) {}
      await conn.close();
      exit(0);
    } catch (e) {
      print('  fail: $e');
      await Future.delayed(const Duration(seconds: 5));
    }
  }
  print('STILL FAILING after 5 attempts');
  exit(1);
}
