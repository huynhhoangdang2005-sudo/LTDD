import 'dart:io';
import 'package:mssql/mssql.dart';

const host = '127.0.0.1';
const port = 64517;
const user = 'restaurant_user';
const pass = 'your_password';
const db = 'QLNH';

Future<MssqlConnection> connectWithRetry(int retries) async {
  for (int i = 0; i < retries; i++) {
    try {
      print('Attempt ${i+1}/$retries ...');
      final conn = await MssqlConnection.connect(
        host: host, port: port, user: user, password: pass, database: db,
        encrypt: false, trustServerCertificate: true,
        timeout: const Duration(seconds: 20),
      );
      print('CONNECTED OK');
      return conn;
    } catch (e) {
      print('  Error: $e');
      await Future.delayed(Duration(seconds: 3));
    }
  }
  throw Exception('All $retries connection attempts failed');
}

Future<void> main() async {
  final conn = await connectWithRetry(3);

  // VA1: food images
  final imageUrls = [
    'https://images.pexels.com/photos/45346/pexels-photo-45346.jpeg?auto=compress&cs=tinysrgb&w=400&h=300&fit=crop',
    'https://images.pexels.com/photos/2100547/pexels-photo-2100547.jpeg?auto=compress&cs=tinysrgb&w=400&h=300&fit=crop',
    'https://images.pexels.com/photos/1167580/pexels-photo-1167580.jpeg?auto=compress&cs=tinysrgb&w=400&h=300&fit=crop',
    'https://images.pexels.com/photos/1053841/pexels-photo-1053841.jpeg?auto=compress&cs=tinysrgb&w=400&h=300&fit=crop',
    'https://images.pexels.com/photos/7087277/pexels-photo-7087277.jpeg?auto=compress&cs=tinysrgb&w=400&h=300&fit=crop',
    'https://images.pexels.com/photos/1639537/pexels-photo-1639537.jpeg?auto=compress&cs=tinysrgb&w=400&h=300&fit=crop',
    'https://images.pexels.com/photos/2912875/pexels-photo-2912875.jpeg?auto=compress&cs=tinysrgb&w=400&h=300&fit=crop',
    'https://images.pexels.com/photos/1163408/pexels-photo-1163408.jpeg?auto=compress&cs=tinysrgb&w=400&h=300&fit=crop',
    'https://images.pexels.com/photos/1585715/pexels-photo-1585715.jpeg?auto=compress&cs=tinysrgb&w=400&h=300&fit=crop',
  ];
  print('VA1: updating menu images...');
  for (int i = 0; i < imageUrls.length; i++) {
    int id = i + 1;
    final sql = 'UPDATE menu_items SET image_url = \'${imageUrls[i]}\' WHERE id = $id';
    await conn.execute(sql, const <String, dynamic>{});
    print('  id=$id done');
  }

  // VA3: shifts table
  print('VA3: creating shifts table...');
  await conn.execute("IF OBJECT_ID('shifts') IS NULL EXEC('CREATE TABLE shifts (id INT IDENTITY(1,1) PRIMARY KEY, user_id INT NULL, user_name NVARCHAR(120) NULL, shift NVARCHAR(60) NOT NULL, start_time NVARCHAR(20) NOT NULL, end_time NVARCHAR(20) NOT NULL, [date] NVARCHAR(30) NULL, notes NVARCHAR(255) NULL, created_at NVARCHAR(30) NULL)')", const <String, dynamic>{});
  await conn.execute('DELETE FROM shifts', const <String, dynamic>{});
  await conn.execute("INSERT INTO shifts (user_id,user_name,shift,start_time,end_time,[date],notes,created_at) VALUES (1,N'admin',N'Buổi sáng','08:00','14:00','2026-11-09',N'Phục vụ bàn chính','2026-11-08 09:00')", const <String, dynamic>{});
  await conn.execute("INSERT INTO shifts (user_id,user_name,shift,start_time,end_time,[date],notes,created_at) VALUES (1,N'admin',N'Buổi chiều','14:00','21:00','2026-11-09',N'Mở cửa + bếp','2026-11-08 09:00')", const <String, dynamic>{});
  await conn.execute("INSERT INTO shifts (user_id,user_name,shift,start_time,end_time,[date],notes,created_at) VALUES (1,N'admin',N'Buổi tối','21:00','02:00','2026-11-09',N'Ca khuya - thu ngân','2026-11-08 09:00')", const <String, dynamic>{});
  var sc = await conn.query('SELECT COUNT(*) AS n FROM shifts', const <String, dynamic>{});
  print('  shifts rows=${sc.rows.first['n']}');

  // VA4: notifications table
  print('VA4: creating notifications table...');
  await conn.execute("IF OBJECT_ID('notifications') IS NULL EXEC('CREATE TABLE notifications (id INT IDENTITY(1,1) PRIMARY KEY, title NVARCHAR(200) NOT NULL, body NVARCHAR(400) NULL, level NVARCHAR(30) NULL, table_id INT NULL, order_id INT NULL, created_at NVARCHAR(30) NULL, read_flag BIT NOT NULL DEFAULT 0)')", const <String, dynamic>{});
  await conn.execute('DELETE FROM notifications', const <String, dynamic>{});
  await conn.execute("INSERT INTO notifications (title,body,level,order_id,created_at,read_flag) VALUES (N'Đơn mới ở Bàn 07',N'Khách đặt Phở bò + Bánh flan (105.000đ)','info',1,N'2026-11-08 17:10',0)", const <String, dynamic>{});
  await conn.execute("INSERT INTO notifications (title,body,level,order_id,created_at,read_flag) VALUES (N'Đơn chờ thanh toán',N'Hóa đơn HD-B01 (Bàn 01) 45.000đ','warning',2,N'2026-11-08 17:35',0)", const <String, dynamic>{});
  await conn.execute("INSERT INTO notifications (title,body,level,order_id,created_at,read_flag) VALUES (N'Đơn đã thanh toán',N'Hóa đơn HD-B01 đã nhận 45.000đ (tiền mặt)','success',1,N'2026-11-08 17:40',1)", const <String, dynamic>{});
  var nc = await conn.query('SELECT COUNT(*) AS n FROM notifications', const <String, dynamic>{});
  print('  notifications rows=${nc.rows.first['n']}');

  // Verify
  print('=== VERIFY: menu images ===');
  var v = await conn.query('SELECT id, name, image_url FROM menu_items ORDER BY id', const <String, dynamic>{});
  for (final r in v.rows) {
    print('  ${r['id']}. ${r['name']} -> ${r['image_url']}');
  }

  await conn.close();
  print('ALL DONE');
  exit(0);
}
