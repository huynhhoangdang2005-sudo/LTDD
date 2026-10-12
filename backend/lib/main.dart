import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:logging/logging.dart';
import 'config.dart';
import 'db.dart';
import 'routes/auth.dart';
import 'routes/menu.dart';
import 'routes/table.dart';
import 'routes/order.dart';
import 'routes/report.dart';
import 'routes/user.dart';

final _log = Logger('RestaurantBackend');

// CORS middleware — adds headers to all responses and catches unhandled exceptions
Middleware corsMiddleware = (Handler innerHandler) {
  return (Request request) async {
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type,Authorization',
    };
    if (request.method == 'OPTIONS') {
      return Response.ok('', headers: corsHeaders);
    }
    try {
      final response = await innerHandler(request);
      return response.change(headers: corsHeaders);
    } catch (e, stack) {
      _log.severe('Error processing request ${request.method} ${request.url}: $e\n$stack');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      );
    }
  };
};

Future<void> main() async {
  // Initialize logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((r) => stdout.writeln('[${r.level.name}] ${r.time}: ${r.message}'));

  // Load environment variables (if .env exists)
  Config.loadEnv();

  // Test database connection at startup
  try {
    await Database.getConnection();
    _log.info('Initial MySQL connection verified successfully.');
  } catch (e) {
    _log.warning('Initial MySQL connection failed: $e. Server will retry when requests arrive.');
  }

  // Build router
  final router = Router()
    ..mount('/auth/', AuthRouter().router.call)
    ..mount('/menu/', MenuRouter().router.call)
    ..mount('/tables/', TableRouter().router.call)
    ..mount('/orders/', OrderRouter().router.call)
    ..mount('/reports/', ReportRouter().router.call)
    ..mount('/users/', UserRouter().router.call);

  // Add middleware (CORS, logging)
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsMiddleware)
      .addHandler(router.call);

  final ip = InternetAddress.anyIPv4;
  const int port = 8080;
  final server = await io.serve(handler, ip, port);
  _log.info('Server listening on http://${server.address.host}:${server.port}');
}
