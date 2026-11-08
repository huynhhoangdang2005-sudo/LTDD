import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../db.dart';

class AuthRouter {
  final Future<DbConn> Function() _getDb;
  AuthRouter([Future<DbConn> Function()? getDb])
      : _getDb = getDb ?? Database.getConnection;

  Future<DbConn> get _dbFuture => _getDb();

  Router get router {
    final router = Router();
    router.post('/register', _register);
    router.post('/login', _login);
    return router;
  }

  Future<Response> _register(Request request) async {
    final payload = await request.readAsString();
    final data = jsonDecode(payload) as Map<String, dynamic>;
    final username = data['username'];
    final password = data['password'];
    if (username == null || password == null) {
      return Response.badRequest(
          body: jsonEncode({'error': 'username and password required'}));
    }
    final conn = await _dbFuture;
    // Simple password storage (plaintext) for demo – replace with hash in prod
    try {
      final userId = await conn.insertId(
          'INSERT INTO users (username, password) VALUES (?, ?)',
          [username, password]);
      return Response.ok(
          jsonEncode({
            'message': 'registered',
            'user_id': userId,
            'username': username
          }),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      if (e.toString().contains('UQ_users_username')) {
        return Response(409,
            body: jsonEncode({'error': 'Username đã tồn tại'}),
            headers: {'Content-Type': 'application/json'});
      }
      rethrow;
    }
  }

  Future<Response> _login(Request request) async {
    final payload = await request.readAsString();
    final data = jsonDecode(payload) as Map<String, dynamic>;
    final username = data['username'];
    final password = data['password'];
    if (username == null || password == null) {
      return Response.badRequest(
          body: jsonEncode({'error': 'username and password required'}));
    }
    final conn = await _dbFuture;
    final results = await conn.query(
      'SELECT id, password, full_name, role, status FROM users WHERE username = ?',
      [username],
    );
    if (results.isEmpty ||
        results.first['password'] != password ||
        results.first['status'] != 'active') {
      return Response.forbidden(jsonEncode({'error': 'invalid credentials'}),
          headers: {'Content-Type': 'application/json'});
    }
    final user = results.first;
    final userId = user['id'];
    final role = user['role'] ?? 'Khách hàng';
    // Generate JWT (valid 24h)
    final jwt = JWT({
      'sub': userId,
      'username': username,
      'role': role,
    });
    final token = jwt.sign(
      SecretKey('your-very-secret-key'),
      expiresIn: const Duration(hours: 24),
    );
    return Response.ok(
        jsonEncode({
          'token': token,
          'user_id': userId,
          'username': username,
          'full_name': user['full_name'] ?? '',
          'role': role,
        }),
        headers: {'Content-Type': 'application/json'});
  }
}
