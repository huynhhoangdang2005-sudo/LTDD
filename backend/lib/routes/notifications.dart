import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../db.dart';

const _jwtSecret = 'your-very-secret-key';

/// Route thông báo (notifications table).
/// - GET  /notifications/        - Lấy danh sách thông báo (cho mọi role đã đăng nhập)
/// - PUT  /notifications/<id>/read - Đánh dấu đã đọc (Quản lý)
/// - POST /notifications/        - Tạo thông báo mới (Quản lý)
class NotificationsRouter {
  final Future<DbConn> Function() _getDb;
  NotificationsRouter([Future<DbConn> Function()? getDb])
      : _getDb = getDb ?? Database.getConnection;

  Future<DbConn> get _dbFuture => _getDb();

  Router get router {
    final r = Router();
    r.get('/', _listNotifications);
    r.post('/', _createNotification);
    r.put('/<id>/read', _markRead);
    return r;
  }

  Future<Response> _listNotifications(Request request) async {
    final conn = await _dbFuture;
    final results = await conn.query(
        'SELECT id, title, body, level, table_id, order_id, created_at, read_flag FROM notifications ORDER BY id DESC');
    final list = results.map(_rowToMap).toList();
    return Response.ok(jsonEncode(list),
        headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _createNotification(Request request) async {
    final data =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final title = data['title'];
    if (title == null) {
      return Response.badRequest(
          body: jsonEncode({'error': 'title required'}));
    }
    final conn = await _dbFuture;
    final denied = await _authorizeManager(request, conn);
    if (denied != null) return denied;
    await conn.execute(
        'INSERT INTO notifications (title, body, level, table_id, order_id, created_at, read_flag) VALUES (?,?,?,?,?,?,0)',
        [
          title,
          data['body'] ?? '',
          data['level'] ?? 'info',
          data['table_id'] ?? null,
          data['order_id'] ?? null,
          DateTime.now().toIso8601String().substring(0, 19)
        ]);
    return Response.ok(jsonEncode({'message': 'notification created'}),
        headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _markRead(Request request, String id) async {
    final conn = await _dbFuture;
    await conn.execute(
        'UPDATE notifications SET read_flag = 1 WHERE id = ?', [int.parse(id)]);
    return Response.ok(jsonEncode({'message': 'marked read'}),
        headers: {'Content-Type': 'application/json'});
  }

  Map<String, dynamic> _rowToMap(dynamic row) => {
        'id': row['id'],
        'title': row['title'],
        'body': row['body'] ?? '',
        'level': row['level'] ?? 'info',
        'table_id': row['table_id'],
        'order_id': row['order_id'],
        'created_at': row['created_at']?.toString() ?? '',
        'read_flag': row['read_flag'] == 1 || row['read_flag'] == true,
      };

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
}
