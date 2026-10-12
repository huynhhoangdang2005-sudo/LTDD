import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:mysql1/mysql1.dart';
import '../db.dart';

class OrderRouter {
  final Future<MySqlConnection> Function() _getDb;
  OrderRouter([Future<MySqlConnection> Function()? getDb])
      : _getDb = getDb ?? Database.getConnection;

  Future<MySqlConnection> get _dbFuture => _getDb();

  Router get router {
    final router = Router();
    router.post('/', _createOrder);
    router.get('/', _listOrders);
    router.get('/<id>', _getOrderDetails);
    router.put('/<id>/status', _updateOrderStatus);
    return router;
  }

  // Create an order with cart items
  Future<Response> _createOrder(Request request) async {
    final data =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final int? userId = data['user_id'];
    final int? tableId = data['table_id'];
    final List<dynamic>? items = data['items']; // [{menu_item_id, quantity}]
    if (userId == null || tableId == null || items == null) {
      return Response.badRequest(
          body: jsonEncode({'error': 'user_id, table_id, items required'}),
          headers: {'Content-Type': 'application/json'});
    }
    // Calculate total price
    final conn = await _dbFuture;
    double total = 0.0;
    for (var item in items) {
      final int menuItemId = item['menu_item_id'];
      final int quantity = item['quantity'];
      final result = await conn
          .query('SELECT price FROM menu_items WHERE id = ?', [menuItemId]);
      if (result.isEmpty) {
        return Response.badRequest(
            body: jsonEncode({'error': 'invalid menu_item_id $menuItemId'}),
            headers: {'Content-Type': 'application/json'});
      }
      final price = result.first['price'] as num;
      total += price * quantity;
    }

    // Insert order
    final orderResult = await conn.query(
        'INSERT INTO orders (user_id, table_id, total, status) VALUES (?, ?, ?, ?)',
        [userId, tableId, total, 'pending']);
    final orderId = orderResult.insertId;

    // Insert order items
    for (var item in items) {
      final int menuItemId = item['menu_item_id'];
      final int quantity = item['quantity'];
      await conn.query(
          'INSERT INTO order_items (order_id, menu_item_id, quantity) VALUES (?,?,?)',
          [orderId, menuItemId, quantity]);
    }
    await conn.query(
        "UPDATE tables SET status = 'Đang phục vụ' WHERE id = ?", [tableId]);

    return Response.ok(
        jsonEncode({'order_id': orderId, 'total': total, 'status': 'pending'}),
        headers: {'Content-Type': 'application/json'});
  }

  // List orders (supports ?user_id=...)
  Future<Response> _listOrders(Request request) async {
    final conn = await _dbFuture;
    final userIdParam = request.url.queryParameters['user_id'];
    Results results;
    if (userIdParam != null) {
      results = await conn.query(
        'SELECT id, user_id, table_id, total, status, created_at FROM orders WHERE user_id = ? ORDER BY id DESC',
        [int.parse(userIdParam)],
      );
    } else {
      results = await conn.query(
          'SELECT id, user_id, table_id, total, status, created_at FROM orders ORDER BY id DESC');
    }
    final list = results
        .map((row) => {
              'id': row['id'],
              'user_id': row['user_id'],
              'table_id': row['table_id'],
              'total': row['total'],
              'status': row['status'],
              'created_at': row['created_at'].toString()
            })
        .toList();
    return Response.ok(jsonEncode(list),
        headers: {'Content-Type': 'application/json'});
  }

  // Get order details with items
  Future<Response> _getOrderDetails(Request request, String id) async {
    final conn = await _dbFuture;
    final orderRes = await conn.query(
        'SELECT id, user_id, table_id, total, status, created_at FROM orders WHERE id = ?',
        [int.parse(id)]);
    if (orderRes.isEmpty) {
      return Response.notFound(jsonEncode({'error': 'order not found'}),
          headers: {'Content-Type': 'application/json'});
    }
    final order = orderRes.first;
    final itemsRes = await conn.query('''
      SELECT oi.id, oi.menu_item_id, oi.quantity, m.name, m.price
      FROM order_items oi
      JOIN menu_items m ON oi.menu_item_id = m.id
      WHERE oi.order_id = ?
    ''', [int.parse(id)]);
    final items = itemsRes
        .map((r) => {
              'id': r['id'],
              'menu_item_id': r['menu_item_id'],
              'quantity': r['quantity'],
              'name': r['name'],
              'price': r['price'],
            })
        .toList();
    return Response.ok(
        jsonEncode({
          'id': order['id'],
          'user_id': order['user_id'],
          'table_id': order['table_id'],
          'total': order['total'],
          'status': order['status'],
          'created_at': order['created_at'].toString(),
          'items': items,
        }),
        headers: {'Content-Type': 'application/json'});
  }

  // Update order status and keep the table state aligned with all its orders.
  Future<Response> _updateOrderStatus(Request request, String id) async {
    final data =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final status = data['status'];
    const allowedStatuses = {
      'pending',
      'cooking',
      'waiting_payment',
      'paid',
      'cancelled'
    };
    if (status is! String || !allowedStatuses.contains(status)) {
      return Response.badRequest(
          body: jsonEncode({'error': 'invalid order status'}),
          headers: {'Content-Type': 'application/json'});
    }
    final conn = await _dbFuture;
    final orderId = int.parse(id);
    final order =
        await conn.query('SELECT table_id FROM orders WHERE id = ?', [orderId]);
    if (order.isEmpty) {
      return Response.notFound(jsonEncode({'error': 'order not found'}),
          headers: {'Content-Type': 'application/json'});
    }
    final tableId = order.first['table_id'];
    await conn
        .query('UPDATE orders SET status = ? WHERE id = ?', [status, orderId]);

    final tableOrders = await conn.query('''
      SELECT
        SUM(status IN ('pending', 'cooking')) AS in_progress,
        SUM(status = 'waiting_payment') AS waiting_payment
      FROM orders
      WHERE table_id = ?
    ''', [tableId]);
    final inProgress = (tableOrders.first['in_progress'] as num?)?.toInt() ?? 0;
    final waitingPayment =
        (tableOrders.first['waiting_payment'] as num?)?.toInt() ?? 0;
    final tableStatus = inProgress > 0
        ? 'Đang phục vụ'
        : waitingPayment > 0
            ? 'Chờ thanh toán'
            : 'Trống';
    await conn.query(
        'UPDATE tables SET status = ? WHERE id = ?', [tableStatus, tableId]);

    return Response.ok(
        jsonEncode({
          'message': 'order status updated',
          'id': int.parse(id),
          'status': status
        }),
        headers: {'Content-Type': 'application/json'});
  }
}
