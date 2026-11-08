import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../db.dart';

const _jwtSecret = 'your-very-secret-key';

class ReportRouter {
  final Future<DbConn> Function() _getDb;
  ReportRouter([Future<DbConn> Function()? getDb])
      : _getDb = getDb ?? Database.getConnection;

  Future<DbConn> get _dbFuture => _getDb();

  Router get router {
    final router = Router();
    router.get('/daily', _dailyReport);
    router.get('/monthly', _monthlyReport);
    return router;
  }

  // Báo cáo doanh thu chỉ dành cho Quản lý (khách hàng bị chặn 403).
  Future<Response?> _authorizeManager(Request request, DbConn conn) async {
    final authorization = request.headers['authorization'];
    if (authorization == null || !authorization.startsWith('Bearer ')) {
      return Response.forbidden(
          jsonEncode({'error': 'manager access required'}),
          headers: {'Content-Type': 'application/json'});
    }
    try {
      final jwt = JWT.verify(authorization.substring(7), SecretKey(_jwtSecret));
      final userId = int.parse(jwt.payload['sub'].toString());
      final results =
          await conn.query('SELECT role, status FROM users WHERE id = ?', [userId]);
      if (results.isEmpty ||
          results.first['role'] != 'Quản lý' ||
          results.first['status'] != 'active') {
        return Response.forbidden(
            jsonEncode({'error': 'manager access required'}),
            headers: {'Content-Type': 'application/json'});
      }
      return null;
    } catch (_) {
      return Response.forbidden(
          jsonEncode({'error': 'invalid or expired token'}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  // Sum total per day for the last 7 days
  Future<Response> _dailyReport(Request request) async {
    final conn = await _dbFuture;
    final denied = await _authorizeManager(request, conn);
    if (denied != null) return denied;
    final results = await conn.query('''
      SELECT CAST(created_at AS DATE) AS [day], SUM(total) AS revenue
      FROM orders
      WHERE status = 'paid' AND created_at >= CAST(DATEADD(DAY, -7, GETDATE()) AS DATE)
      GROUP BY CAST(created_at AS DATE)
      ORDER BY [day] DESC
    ''');
    final data = results
        .map((row) => {
              'day': row['day'].toString(),
              'revenue': row['revenue'] is num ? (row['revenue'] as num).toInt() : row['revenue']
            })
        .toList();
    return Response.ok(jsonEncode(data),
        headers: {'Content-Type': 'application/json'});
  }

  // Sum total per month for the last 12 months
  Future<Response> _monthlyReport(Request request) async {
    final conn = await _dbFuture;
    final denied = await _authorizeManager(request, conn);
    if (denied != null) return denied;
    final results = await conn.query('''
      SELECT FORMAT(created_at, 'yyyy-MM') AS [month], SUM(total) AS revenue
      FROM orders
      WHERE status = 'paid' AND created_at >= DATEADD(MONTH, -12, GETDATE())
      GROUP BY FORMAT(created_at, 'yyyy-MM')
      ORDER BY [month] DESC
    ''');
    final data = results
        .map((row) => {
              'month': row['month'],
              'revenue': row['revenue'] is num ? (row['revenue'] as num).toInt() : row['revenue']
            })
        .toList();
    return Response.ok(jsonEncode(data),
        headers: {'Content-Type': 'application/json'});
  }
}
