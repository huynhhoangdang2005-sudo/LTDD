import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../db.dart';

const _jwtSecret = 'your-very-secret-key';

/// Route quản lý ca làm việc (shifts table) — chỉ Quản lý.
class ShiftsRouter {
  final Future<DbConn> Function() _getDb;
  ShiftsRouter([Future<DbConn> Function()? getDb])
      : _getDb = getDb ?? Database.getConnection;

  Future<DbConn> get _dbFuture => _getDb();

  Router get router {
    final r = Router();
    r.get('/', _listShifts);
    r.post('/', _createShift);
    r.delete('/<id>', _deleteShift);
    return r;
  }

  Future<Response> _listShifts(Request request) async {
    final conn = await _dbFuture;
    final denied = await _authorizeManager(request, conn);
    if (denied != null) return denied;
    final results =
        await conn.query('SELECT * FROM shifts ORDER BY [date] DESC, start_time ASC');
    final list = results.map(_rowToMap).toList();
    return Response.ok(jsonEncode(list),
        headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _createShift(Request request) async {
    final data = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final shift = data['shift'];
    final start = data['start_time'];
    final end = data['end_time'];
    if (shift == null || start == null || end == null) {
      return Response.badRequest(
          body: jsonEncode({'error': 'shift, start_time, end_time required'}));
    }
    final conn = await _dbFuture;
    final denied = await _authorizeManager(request, conn);
    if (denied != null) return denied;
    await conn.execute(
        'INSERT INTO shifts (user_id, user_name, shift, start_time, end_time, [date], notes, created_at) VALUES (?,?,?,?,?,?,?,?)',
        [
          data['user_id'] ?? null,
          data['user_name'] ?? 'admin',
          shift,
          start,
          end,
          data['date'] ?? null,
          data['notes'] ?? '',
          DateTime.now().toIso8601String().substring(0, 19)
        ]);
    return Response.ok(jsonEncode({'message': 'shift created'}),
        headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _deleteShift(Request request, String id) async {
    final conn = await _dbFuture;
    final denied = await _authorizeManager(request, conn);
    if (denied != null) return denied;
    await conn.execute('DELETE FROM shifts WHERE id = ?', [int.parse(id)]);
    return Response.ok(jsonEncode({'message': 'shift deleted'}),
        headers: {'Content-Type': 'application/json'});
  }

  Map<String, dynamic> _rowToMap(dynamic row) => {
        'id': row['id'],
        'user_id': row['user_id'],
        'user_name': row['user_name'] ?? '',
        'shift': row['shift'] ?? '',
        'start_time': row['start_time']?.toString() ?? '',
        'end_time': row['end_time']?.toString() ?? '',
        'date': row['date']?.toString() ?? '',
        'notes': row['notes'] ?? '',
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
