import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:mysql1/mysql1.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../db.dart';

const _jwtSecret = 'your-very-secret-key';

/// Route quản lý nhân viên (users table):
/// GET  /users/          - Danh sách tất cả nhân viên (không bao gồm khách hàng)
/// GET  /users/<id>      - Chi tiết nhân viên
/// POST /users/          - Tạo nhân viên mới
/// PUT  /users/<id>      - Cập nhật thông tin nhân viên
/// PUT  /users/<id>/status - Khoá / mở khoá tài khoản
/// DELETE /users/<id>    - Xoá nhân viên
class UserRouter {
  final Future<MySqlConnection> Function() _getDb;
  UserRouter([Future<MySqlConnection> Function()? getDb])
      : _getDb = getDb ?? Database.getConnection;

  Future<MySqlConnection> get _dbFuture => _getDb();

  Router get router {
    final r = Router();
    r.get('/', _listUsers);
    r.get('/<id>', _getUser);
    r.post('/', _createUser);
    r.put('/<id>', _updateUser);
    r.put('/<id>/status', _updateUserStatus);
    r.delete('/<id>', _deleteUser);
    return r;
  }

  // Danh sách nhân viên (không lấy Khách hàng)
  Future<Response> _listUsers(Request request) async {
    final conn = await _dbFuture;
    final denied = await _authorizeManager(request, conn);
    if (denied != null) return denied;
    final results = await conn.query(
      "SELECT id, username, full_name, role, status, phone, created_at FROM users WHERE role != 'Khách hàng' AND status != 'deleted' ORDER BY id ASC",
    );
    final list = results.map((row) => _rowToMap(row)).toList();
    return Response.ok(jsonEncode(list),
        headers: {'Content-Type': 'application/json'});
  }

  // Chi tiết một nhân viên
  Future<Response> _getUser(Request request, String id) async {
    final conn = await _dbFuture;
    final denied = await _authorizeManager(request, conn);
    if (denied != null) return denied;
    final results = await conn.query(
      'SELECT id, username, full_name, role, status, phone, created_at FROM users WHERE id = ?',
      [int.parse(id)],
    );
    if (results.isEmpty) {
      return Response.notFound(jsonEncode({'error': 'user not found'}),
          headers: {'Content-Type': 'application/json'});
    }
    return Response.ok(jsonEncode(_rowToMap(results.first)),
        headers: {'Content-Type': 'application/json'});
  }

  // Tạo nhân viên mới
  Future<Response> _createUser(Request request) async {
    final data =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final username = data['username'];
    final password = data['password'] ?? '123456';
    final fullName = data['full_name'] ?? '';
    final role = data['role'] ?? 'Phục vụ';
    final phone = data['phone'] ?? '';
    if (username is! String || username.trim().isEmpty) {
      return Response.badRequest(
          body: jsonEncode({'error': 'username required'}),
          headers: {'Content-Type': 'application/json'});
    }
    final conn = await _dbFuture;
    final denied = await _authorizeManager(request, conn);
    if (denied != null) return denied;
    // Kiểm tra username đã tồn tại
    final existing =
        await conn.query('SELECT id FROM users WHERE username = ?', [username]);
    if (existing.isNotEmpty) {
      return Response.badRequest(
          body: jsonEncode({'error': 'Username đã tồn tại'}),
          headers: {'Content-Type': 'application/json'});
    }
    final result = await conn.query(
      'INSERT INTO users (username, password, full_name, role, status, phone) VALUES (?, ?, ?, ?, ?, ?)',
      [username, password, fullName, role, 'active', phone],
    );
    return Response.ok(
      jsonEncode({'message': 'user created', 'id': result.insertId}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  // Cập nhật thông tin nhân viên
  Future<Response> _updateUser(Request request, String id) async {
    final data =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final conn = await _dbFuture;
    final denied = await _authorizeManager(request, conn);
    if (denied != null) return denied;
    final updates = <String>[];
    final params = <dynamic>[];
    if (data['full_name'] != null) {
      updates.add('full_name = ?');
      params.add(data['full_name']);
    }
    if (data['role'] != null) {
      updates.add('role = ?');
      params.add(data['role']);
    }
    if (data['phone'] != null) {
      updates.add('phone = ?');
      params.add(data['phone']);
    }
    if (data['password'] != null && (data['password'] as String).isNotEmpty) {
      updates.add('password = ?');
      params.add(data['password']);
    }
    if (updates.isEmpty) {
      return Response.badRequest(
          body: jsonEncode({'error': 'No fields to update'}),
          headers: {'Content-Type': 'application/json'});
    }
    params.add(int.parse(id));
    await conn.query(
        'UPDATE users SET ${updates.join(', ')} WHERE id = ?', params);
    return Response.ok(jsonEncode({'message': 'user updated'}),
        headers: {'Content-Type': 'application/json'});
  }

  // Khoá / mở khoá tài khoản
  Future<Response> _updateUserStatus(Request request, String id) async {
    final data =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final status = data['status'];
    if (status != 'active' && status != 'locked') {
      return Response.badRequest(
          body: jsonEncode({'error': 'status required'}),
          headers: {'Content-Type': 'application/json'});
    }
    final conn = await _dbFuture;
    final denied = await _authorizeManager(request, conn);
    if (denied != null) return denied;
    await conn.query(
        'UPDATE users SET status = ? WHERE id = ?', [status, int.parse(id)]);
    return Response.ok(jsonEncode({'message': 'status updated'}),
        headers: {'Content-Type': 'application/json'});
  }

  // Xoá nhân viên
  Future<Response> _deleteUser(Request request, String id) async {
    final conn = await _dbFuture;
    final denied = await _authorizeManager(request, conn);
    if (denied != null) return denied;
    final target = await conn
        .query('SELECT role FROM users WHERE id = ?', [int.parse(id)]);
    if (target.isEmpty) {
      return Response.notFound(jsonEncode({'error': 'user not found'}),
          headers: {'Content-Type': 'application/json'});
    }
    if (target.first['role'] == 'Quản lý') {
      return Response.badRequest(
          body: jsonEncode({'error': 'Không thể xóa tài khoản quản lý'}),
          headers: {'Content-Type': 'application/json'});
    }
    await conn.query(
        "UPDATE users SET status = 'deleted' WHERE id = ? AND role != 'Quản lý'",
        [int.parse(id)]);
    return Response.ok(jsonEncode({'message': 'user deleted'}),
        headers: {'Content-Type': 'application/json'});
  }

  Future<Response?> _authorizeManager(
      Request request, MySqlConnection conn) async {
    final authorization = request.headers['authorization'];
    if (authorization == null || !authorization.startsWith('Bearer ')) {
      return Response.forbidden(
          jsonEncode({'error': 'manager access required'}),
          headers: {'Content-Type': 'application/json'});
    }
    try {
      final jwt = JWT.verify(authorization.substring(7), SecretKey(_jwtSecret));
      final userId = int.parse(jwt.payload['sub'].toString());
      final results = await conn
          .query('SELECT role, status FROM users WHERE id = ?', [userId]);
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

  Map<String, dynamic> _rowToMap(dynamic row) => {
        'id': row['id'],
        'username': row['username'],
        'full_name': row['full_name'] ?? '',
        'role': row['role'] ?? '',
        'status': row['status'] ?? 'active',
        'phone': row['phone'] ?? '',
        'created_at': row['created_at']?.toString() ?? '',
      };
}
