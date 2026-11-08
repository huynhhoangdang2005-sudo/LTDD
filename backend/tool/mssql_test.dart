import 'package:mssql/mssql.dart';
import 'dart:io';

Future<void> main() async {
  // Read port from env; default to current dynamic port of MSSQLSERVER01
  final port = int.tryParse(Platform.environment['MSSQL_PORT'] ?? '64517') ?? 64517;

  for (final enc in [true, false]) {
    try {
      final conn = await MssqlConnection.connect(
        host: '127.0.0.1',
        port: port,
        user: 'restaurant_user',
        password: 'your_password',
        database: 'QLNH',
        encrypt: enc,
        trustServerCertificate: true,
        timeout: const Duration(seconds: 10),
      );
      final r = await conn.query(
          'SELECT (SELECT COUNT(*) FROM users) u, (SELECT COUNT(*) FROM menu_items) m, (SELECT COUNT(*) FROM [tables]) t');
      print('OK port=$port encrypt=$enc users=${r.rows.first['u']} menu=${r.rows.first['m']} tables=${r.rows.first['t']}');
      // quick DML to prove db_owner write access
      await conn.execute('INSERT INTO categories (name) VALUES (@n)', {'n': 'test_cat'});
      final del =
          await conn.execute('DELETE FROM categories WHERE name = @n', {'n': 'test_cat'});
      print('DML OK (insert/delete) affected=$del');
      await conn.close();
      stdout.writeln('SUCCESS port=$port encrypt=$enc');
      return;
    } catch (e) {
      print('FAIL port=$port encrypt=$enc -> ${e.toString().split('\n').first}');
    }
  }
  print('No working connection found.');
}
