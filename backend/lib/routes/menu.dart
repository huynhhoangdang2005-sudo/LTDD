import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:mysql1/mysql1.dart';
import '../db.dart';

class MenuRouter {
  final Future<MySqlConnection> Function() _getDb;
  MenuRouter([Future<MySqlConnection> Function()? getDb])
      : _getDb = getDb ?? Database.getConnection;

  Future<MySqlConnection> get _dbFuture => _getDb();

  Router get router {
    final router = Router();
    router.get('/categories', _getCategories);
    router.post('/categories', _createCategory);
    router.put('/categories/<id>', _updateCategory);
    router.delete('/categories/<id>', _deleteCategory);

    router.get('/items', _getItems);
    router.post('/items', _createItem);
    router.put('/items/<id>', _updateItem);
    router.delete('/items/<id>', _deleteItem);
    return router;
  }

  // ---------- Categories ----------
  Future<Response> _getCategories(Request request) async {
    final conn = await _dbFuture;
    final results = await conn.query('SELECT id, name FROM categories');
    final list =
        results.map((row) => {'id': row['id'], 'name': row['name']}).toList();
    return Response.ok(jsonEncode(list),
        headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _createCategory(Request request) async {
    final data =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final name = data['name'];
    if (name == null)
      return Response.badRequest(body: jsonEncode({'error': 'name required'}));
    final conn = await _dbFuture;
    await conn.query('INSERT INTO categories (name) VALUES (?)', [name]);
    return Response.ok(jsonEncode({'message': 'category created'}),
        headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _updateCategory(Request request, String id) async {
    final data =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final name = data['name'];
    if (name == null)
      return Response.badRequest(body: jsonEncode({'error': 'name required'}));
    final conn = await _dbFuture;
    await conn.query(
        'UPDATE categories SET name = ? WHERE id = ?', [name, int.parse(id)]);
    return Response.ok(jsonEncode({'message': 'category updated'}),
        headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _deleteCategory(Request request, String id) async {
    final conn = await _dbFuture;
    await conn.query('DELETE FROM categories WHERE id = ?', [int.parse(id)]);
    return Response.ok(jsonEncode({'message': 'category deleted'}),
        headers: {'Content-Type': 'application/json'});
  }

  // ---------- Menu Items ----------
  Future<Response> _getItems(Request request) async {
    final conn = await _dbFuture;
    final results = await conn.query(
        'SELECT id, name, price, category_id, image_url, available FROM menu_items');
    final list = results
        .map((row) => {
              'id': row['id'],
              'name': row['name'],
              'price': row['price'],
              'category_id': row['category_id'],
              'image_url': row['image_url'] ?? '',
              'available': row['available'] == 1 || row['available'] == true,
            })
        .toList();
    return Response.ok(jsonEncode(list),
        headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _createItem(Request request) async {
    final data =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final name = data['name'];
    final price = data['price'];
    final categoryId = data['category_id'];
    final imageUrl = data['image_url'] ?? '';
    final available = data['available'] ?? true;
    if (name == null || price == null || categoryId == null) {
      return Response.badRequest(
          body: jsonEncode({'error': 'name, price, category_id required'}));
    }
    final conn = await _dbFuture;
    await conn.query(
        'INSERT INTO menu_items (name, price, category_id, image_url, available) VALUES (?,?,?,?,?)',
        [name, price, categoryId, imageUrl, available]);
    return Response.ok(jsonEncode({'message': 'menu item created'}),
        headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _updateItem(Request request, String id) async {
    final data =
        jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final name = data['name'];
    final price = data['price'];
    final categoryId = data['category_id'];
    final imageUrl = data['image_url'];
    final available = data['available'];
    if (name == null &&
        price == null &&
        categoryId == null &&
        imageUrl == null &&
        available == null) {
      return Response.badRequest(
          body: jsonEncode({'error': 'at least one field required'}));
    }
    final conn = await _dbFuture;
    final updates = <String>[];
    final params = <dynamic>[];
    if (name != null) {
      updates.add('name = ?');
      params.add(name);
    }
    if (price != null) {
      updates.add('price = ?');
      params.add(price);
    }
    if (categoryId != null) {
      updates.add('category_id = ?');
      params.add(categoryId);
    }
    if (imageUrl != null) {
      updates.add('image_url = ?');
      params.add(imageUrl);
    }
    if (available != null) {
      updates.add('available = ?');
      params.add(available);
    }
    params.add(int.parse(id));
    await conn.query(
        'UPDATE menu_items SET ${updates.join(', ')} WHERE id = ?', params);
    return Response.ok(jsonEncode({'message': 'menu item updated'}),
        headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _deleteItem(Request request, String id) async {
    final conn = await _dbFuture;
    await conn.query('DELETE FROM menu_items WHERE id = ?', [int.parse(id)]);
    return Response.ok(jsonEncode({'message': 'menu item deleted'}),
        headers: {'Content-Type': 'application/json'});
  }
}
