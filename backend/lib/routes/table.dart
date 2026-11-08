import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../db.dart';

class TableRouter {
  final Future<DbConn> Function() _getDb;
  TableRouter([Future<DbConn> Function()? getDb])
      : _getDb = getDb ?? Database.getConnection;

  Future<DbConn> get _dbFuture => _getDb();

  Router get router {
    final router = Router();
    router.get('/', _listTables);
    router.post('/', _createTable);
    router.put('/<id>', _updateTable);
    router.put('/<id>/status', _updateTableStatus);
    router.delete('/<id>', _deleteTable);
    return router;
  }

  Future<Response> _listTables(Request request) async {
    final conn = await _dbFuture;
    // Reset tables that show "waiting to pay" but no longer have an open order.
    await conn.execute('''
      UPDATE [tables]
      SET status = N'Trống'
      WHERE status = N'Chờ thanh toán'
        AND id NOT IN (
          SELECT table_id
          FROM orders
          WHERE status IN ('pending', 'cooking', 'waiting_payment')
            AND table_id IS NOT NULL
        )
    ''');
    final results = await conn
        .query('SELECT id, number, seats, status FROM [tables] ORDER BY number');
    final list = results
        .map((row) => {
              'id': row['id'],
              'number': row['number'],
              'seats': row['seats'],
              'status': row['status'] ?? 'Trống',
            })
        .toList();
    return Response.ok(jsonEncode(list),
        headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _createTable(Request request) async {
    final data =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final number = data['number'];
    final seats = data['seats'];
    final status = data['status'] ?? 'Trống';
    if (number == null || seats == null) {
      return Response.badRequest(
          body: jsonEncode({'error': 'number and seats required'}));
    }
    final conn = await _dbFuture;
    await conn.execute(
        'INSERT INTO [tables] (number, seats, status) VALUES (?, ?, ?)',
        [number, seats, status]);
    return Response.ok(jsonEncode({'message': 'table created'}),
        headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _updateTable(Request request, String id) async {
    final data =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final number = data['number'];
    final seats = data['seats'];
    final status = data['status'];
    if (number == null && seats == null && status == null) {
      return Response.badRequest(
          body: jsonEncode({'error': 'at least one field required'}));
    }
    final conn = await _dbFuture;
    final updates = <String>[];
    final params = <Object?>[];
    if (number != null) {
      updates.add('number = ?');
      params.add(number);
    }
    if (seats != null) {
      updates.add('seats = ?');
      params.add(seats);
    }
    if (status != null) {
      updates.add('status = ?');
      params.add(status);
    }
    params.add(int.parse(id));
    await conn.execute(
        'UPDATE [tables] SET ${updates.join(', ')} WHERE id = ?', params);
    return Response.ok(jsonEncode({'message': 'table updated'}),
        headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _updateTableStatus(Request request, String id) async {
    final data =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final status = data['status'];
    if (status == null) {
      return Response.badRequest(
          body: jsonEncode({'error': 'status required'}));
    }
    final conn = await _dbFuture;
    await conn.execute(
        'UPDATE [tables] SET status = ? WHERE id = ?', [status, int.parse(id)]);
    return Response.ok(jsonEncode({'message': 'table status updated'}),
        headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _deleteTable(Request request, String id) async {
    final conn = await _dbFuture;
    await conn.execute(
        'DELETE FROM [tables] WHERE id = ?', [int.parse(id)]);
    return Response.ok(jsonEncode({'message': 'table deleted'}),
        headers: {'Content-Type': 'application/json'});
  }
}
