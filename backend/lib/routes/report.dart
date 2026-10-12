import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:mysql1/mysql1.dart';
import '../db.dart';

class ReportRouter {
  final Future<MySqlConnection> Function() _getDb;
  ReportRouter([Future<MySqlConnection> Function()? getDb])
      : _getDb = getDb ?? Database.getConnection;

  Future<MySqlConnection> get _dbFuture => _getDb();

  Router get router {
    final router = Router();
    router.get('/daily', _dailyReport);
    router.get('/monthly', _monthlyReport);
    return router;
  }

  // Sum total per day for the last 7 days
  Future<Response> _dailyReport(Request request) async {
    final conn = await _dbFuture;
    final results = await conn.query('''
      SELECT DATE(created_at) as day, SUM(total) as revenue
      FROM orders
      WHERE status = 'paid' AND created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
      GROUP BY day
      ORDER BY day DESC
    ''');
    final data = results
        .map((row) => {'day': row['day'].toString(), 'revenue': row['revenue']})
        .toList();
    return Response.ok(jsonEncode(data),
        headers: {'Content-Type': 'application/json'});
  }

  // Sum total per month for the last 12 months
  Future<Response> _monthlyReport(Request request) async {
    final conn = await _dbFuture;
    final results = await conn.query('''
      SELECT DATE_FORMAT(created_at, '%Y-%m') as month, SUM(total) as revenue
      FROM orders
      WHERE status = 'paid' AND created_at >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
      GROUP BY month
      ORDER BY month DESC
    ''');
    final data = results
        .map((row) => {'month': row['month'], 'revenue': row['revenue']})
        .toList();
    return Response.ok(jsonEncode(data),
        headers: {'Content-Type': 'application/json'});
  }
}
