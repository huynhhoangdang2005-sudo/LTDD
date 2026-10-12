import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:mysql1/mysql1.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../db.dart';

class AuthRouter {
  final Future<MySqlConnection> Function() _getDb;
  AuthRouter([Future<MySqlConnection> Function()? getDb])
      : _getDb = getDb ?? Database.getConnection;

  Future<MySqlConnection> get _dbFuture => _getDb();

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
    final result = await conn.query(
        'INSERT INTO users (username, password) VALUES (?, ?)',
        [username, password]);
    return Response.ok(
        jsonEncode({
          'message': 'registered',
          'user_id': result.insertId,
          'username': username
        }),
        headers: {'Content-Type': 'application/json'});
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
    // Create JWT payload without expiration
    final jwt = JWT({
      'sub': userId,
      'username': username,
      'role': role,
    });
    // Sign the token with expiration (24 hours)
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
