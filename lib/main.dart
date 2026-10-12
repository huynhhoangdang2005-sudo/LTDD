import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ─────────────────────────── COLORS ────────────────────────────
const cPrimary = Color(0xffb84c24);
const cPrimaryDark = Color(0xff8f3417);
const cPrimarySoft = Color(0xfffff0e9);
const cInk = Color(0xff252320);
const cMuted = Color(0xff746f69);
const cLine = Color(0xffe9e5df);
const cSurface = Colors.white;
const cBg = Color(0xfff7f5f2);
const cSuccess = Color(0xff23835b);
const cSuccessSoft = Color(0xffe7f5ee);
const cWarning = Color(0xffb86a04);
const cWarningSoft = Color(0xfffff4df);
const cDanger = Color(0xffb83d3d);
const cDangerSoft = Color(0xfffdeaea);
const cBlue = Color(0xff2d6ca8);
const cBlueSoft = Color(0xffedf4fb);
const cDarkCard = Color(0xff221f1d);

// ─────────────────────────── MODELS ────────────────────────────
class AppUser {
  final int id;
  final String username;
  final String fullName;
  final String role;
  final String token;
  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.token,
  });
  bool get isAdmin => role == 'Quản lý';
}

class CategoryModel {
  int id;
  String name;
  CategoryModel({required this.id, required this.name});
  factory CategoryModel.fromJson(Map<String, dynamic> j) =>
      CategoryModel(id: j['id'] ?? 0, name: j['name'] ?? '');
}

class MenuItemModel {
  int id;
  String name;
  int price;
  int categoryId;
  String imageUrl;
  bool available;
  MenuItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    required this.imageUrl,
    this.available = true,
  });
  factory MenuItemModel.fromJson(Map<String, dynamic> j) => MenuItemModel(
    id: j['id'] ?? 0,
    name: j['name'] ?? '',
    price: (j['price'] as num?)?.round() ?? 0,
    categoryId: j['category_id'] ?? j['categoryId'] ?? 0,
    imageUrl: j['image_url'] ?? j['imageUrl'] ?? '',
    available: j['available'] == true || j['available'] == 1,
  );
}

class TableModel {
  int id;
  int number;
  int seats;
  String status;
  TableModel({
    required this.id,
    required this.number,
    required this.seats,
    required this.status,
  });
  String get code => 'B${number.toString().padLeft(2, '0')}';
  factory TableModel.fromJson(Map<String, dynamic> j) => TableModel(
    id: j['id'] ?? 0,
    number: j['number'] ?? j['table_number'] ?? 0,
    seats: j['seats'] ?? j['capacity'] ?? 4,
    status: j['status'] ?? 'Trống',
  );
}

class OrderModel {
  int id;
  int userId;
  int tableId;
  int total;
  String status;
  String createdAt;
  OrderModel({
    required this.id,
    required this.userId,
    required this.tableId,
    required this.total,
    required this.status,
    required this.createdAt,
  });
  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
    id: j['id'] ?? 0,
    userId: j['user_id'] ?? j['userId'] ?? 0,
    tableId: j['table_id'] ?? j['tableId'] ?? 0,
    total: (j['total'] as num?)?.round() ?? 0,
    status: j['status'] ?? '',
    createdAt: j['created_at'] ?? j['createdAt'] ?? '',
  );
}

class StaffUserModel {
  int id;
  String username;
  String fullName;
  String role;
  String status;
  String phone;
  String createdAt;
  StaffUserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.status,
    required this.phone,
    required this.createdAt,
  });
  bool get isActive => status == 'active';
  factory StaffUserModel.fromJson(Map<String, dynamic> j) => StaffUserModel(
    id: j['id'] ?? 0,
    username: j['username'] ?? '',
    fullName: j['full_name'] ?? '',
    role: j['role'] ?? '',
    status: j['status'] ?? 'active',
    phone: j['phone'] ?? '',
    createdAt: j['created_at'] ?? '',
  );
}

// ─────────────────────────── HELPERS ────────────────────────────
final _currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

String formatMoney(int v) {
  return _currencyFormatter.format(v).trim();
}

String _categoryName(int id, List<CategoryModel> cats) {
  try {
    return cats.firstWhere((c) => c.id == id).name;
  } catch (_) {
    return 'Khác';
  }
}

// ─────────────────────────── API SERVICE ────────────────────────
class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8080';
  static const Duration _requestTimeout = Duration(seconds: 30);

  static Future<AppUser> login(String username, String password) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(_requestTimeout);
    if (res.statusCode == 200) {
      final j = jsonDecode(res.body);
      return AppUser(
        id: j['id'] ?? j['user_id'] ?? 1,
        username: j['username'] ?? username,
        fullName: j['full_name'] ?? '',
        role: j['role'] ?? 'Khách hàng',
        token: j['token'] ?? j['access_token'] ?? '',
      );
    }
    throw Exception(jsonDecode(res.body)['detail'] ?? 'Đăng nhập thất bại');
  }

  static Future<AppUser> register(String username, String password) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(_requestTimeout);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return login(username, password);
    }
    throw Exception(jsonDecode(res.body)['detail'] ?? 'Đăng ký thất bại');
  }

  static Future<List<CategoryModel>> getCategories(String token) async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/menu/categories'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(_requestTimeout);
    if (res.statusCode == 200) {
      final List j = jsonDecode(res.body);
      return j.map((e) => CategoryModel.fromJson(e)).toList();
    }
    throw Exception('Lỗi tải danh mục');
  }

  static Future<List<MenuItemModel>> getMenuItems(String token) async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/menu/items'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(_requestTimeout);
    if (res.statusCode == 200) {
      final List j = jsonDecode(res.body);
      return j.map((e) => MenuItemModel.fromJson(e)).toList();
    }
    throw Exception('Lỗi tải thực đơn');
  }

  static Future<List<TableModel>> getTables(String token) async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/tables/'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(_requestTimeout);
    if (res.statusCode == 200) {
      final List j = jsonDecode(res.body);
      return j.map((e) => TableModel.fromJson(e)).toList();
    }
    throw Exception('Lỗi tải bàn');
  }

  static Future<List<OrderModel>> getOrders(String token, int userId) async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/orders/?user_id=$userId'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(_requestTimeout);
    if (res.statusCode == 200) {
      final List j = jsonDecode(res.body);
      return j.map((e) => OrderModel.fromJson(e)).toList();
    }
    throw Exception('Lỗi tải đơn hàng (${res.statusCode})');
  }

  static Future<List<OrderModel>> getAllOrders(String token) async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/orders/'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(_requestTimeout);
    if (res.statusCode == 200) {
      final List j = jsonDecode(res.body);
      return j.map((e) => OrderModel.fromJson(e)).toList();
    }
    throw Exception('Lỗi tải danh sách đơn hàng (${res.statusCode})');
  }

  static Future<Map<String, dynamic>?> getOrderDetails(
    String token,
    int orderId,
  ) async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/orders/$orderId'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(_requestTimeout);
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Lỗi tải chi tiết đơn hàng (${res.statusCode})');
  }

  static Future<void> createOrder(
    String token,
    int userId,
    int tableId,
    int total,
    List<Map<String, dynamic>> items,
  ) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/orders/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'user_id': userId,
            'table_id': tableId,
            'total': total,
            'items': items,
          }),
        )
        .timeout(_requestTimeout);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(jsonDecode(res.body)['error'] ?? 'Tạo đơn hàng thất bại');
    }
  }

  static Future<void> updateOrderStatus(
    String token,
    int orderId,
    String status,
  ) async {
    final res = await http
        .put(
          Uri.parse('$baseUrl/orders/$orderId/status'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'status': status}),
        )
        .timeout(_requestTimeout);
    if (res.statusCode != 200) {
      throw Exception(
        jsonDecode(res.body)['error'] ?? 'Cập nhật trạng thái đơn thất bại',
      );
    }
  }

  // ── Table status update ─────────────────────────────
  static Future<void> updateTableStatus(
    String token,
    int tableId,
    String status,
  ) async {
    final res = await http
        .put(
          Uri.parse('$baseUrl/tables/$tableId/status'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'status': status}),
        )
        .timeout(_requestTimeout);
    if (res.statusCode != 200) {
      throw Exception(
        jsonDecode(res.body)['error'] ?? 'Cập nhật trạng thái bàn thất bại',
      );
    }
  }

  // ── Staff / Users API ───────────────────────────────
  static Future<List<StaffUserModel>> getStaff(String token) async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/users/'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(_requestTimeout);
    if (res.statusCode == 200) {
      final List j = jsonDecode(res.body);
      return j
          .map((e) => StaffUserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Lỗi tải danh sách nhân viên (${res.statusCode})');
  }

  static Future<void> createStaff(
    String token,
    Map<String, dynamic> data,
  ) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/users/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(data),
        )
        .timeout(_requestTimeout);
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['error'] ?? 'Tạo nhân viên thất bại');
    }
  }

  static Future<void> updateStaff(
    String token,
    int id,
    Map<String, dynamic> data,
  ) async {
    final res = await http
        .put(
          Uri.parse('$baseUrl/users/$id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(data),
        )
        .timeout(_requestTimeout);
    if (res.statusCode != 200) {
      throw Exception(
        jsonDecode(res.body)['error'] ?? 'Cập nhật nhân viên thất bại',
      );
    }
  }

  static Future<void> updateStaffStatus(
    String token,
    int id,
    String status,
  ) async {
    final res = await http
        .put(
          Uri.parse('$baseUrl/users/$id/status'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'status': status}),
        )
        .timeout(_requestTimeout);
    if (res.statusCode != 200) {
      throw Exception(
        jsonDecode(res.body)['error'] ?? 'Cập nhật trạng thái thất bại',
      );
    }
  }

  static Future<void> deleteStaff(String token, int id) async {
    final res = await http
        .delete(
          Uri.parse('$baseUrl/users/$id'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(_requestTimeout);
    if (res.statusCode != 200) {
      throw Exception(
        jsonDecode(res.body)['error'] ?? 'Xóa nhân viên thất bại',
      );
    }
  }
}

// ─────────────────────────── MAIN ───────────────────────────────
void main() {
  runApp(const RestaurantApp());
}

class RestaurantApp extends StatelessWidget {
  const RestaurantApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nhà hàng Hương Việt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: cPrimary),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      builder: (context, child) {
        return Container(
          color: const Color(
            0xff1e1a17,
          ), // Nền tối trang trọng bên ngoài thiết bị
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ClipRRect(
              borderRadius: MediaQuery.of(context).size.width > 500
                  ? BorderRadius.circular(28)
                  : BorderRadius.zero,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    if (MediaQuery.of(context).size.width > 500)
                      BoxShadow(
                        color: Colors.black.withAlpha(80),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                  ],
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
      home: const SplashScreen(),
    );
  }
}

// ─────────────────────────── SPLASH ─────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cPrimary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.restaurant,
                color: Colors.white,
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Hương Việt',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhà hàng',
              style: TextStyle(
                color: Colors.white.withAlpha(180),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── SHARED WIDGETS ─────────────────────

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.size = 44.0});
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.restaurant, color: Colors.white, size: size * 0.55),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, {this.type = 'info'});
  final String label;
  final String type;
  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (type) {
      case 'success':
        bg = cSuccessSoft;
        fg = cSuccess;
        break;
      case 'warning':
        bg = cWarningSoft;
        fg = cWarning;
        break;
      case 'danger':
        bg = cDangerSoft;
        fg = cDanger;
        break;
      default:
        bg = cBlueSoft;
        fg = cBlue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({required this.title, this.subtitle, this.onBack});
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: cSurface,
      padding: EdgeInsets.fromLTRB(onBack != null ? 4 : 16, 16, 16, 12),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: cInk),
              onPressed: onBack,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cInk,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 12, color: cMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({this.hint = 'Tìm kiếm...', this.onChanged});
  final String hint;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cLine),
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: cMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: cMuted, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _ChipFilter extends StatelessWidget {
  const _ChipFilter({
    required this.items,
    required this.selected,
    required this.onTap,
  });
  final List<String> items;
  final String selected;
  final ValueChanged<String> onTap;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final isSelected = items[i] == selected;
          return GestureDetector(
            onTap: () => onTap(items[i]),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? cPrimary : cSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? cPrimary : cLine),
              ),
              child: Text(
                items[i],
                style: TextStyle(
                  color: isSelected ? Colors.white : cMuted,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.loading = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool loading;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: cPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

void _showToast(BuildContext context, String message, {bool success = true}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      bottom: 100,
      left: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: success ? const Color(0xff1a5c3e) : const Color(0xff8f2222),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Future.delayed(const Duration(milliseconds: 2400), () => entry.remove());
}

Future<bool?> _showConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirm,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, color: cInk),
      ),
      content: Text(body, style: const TextStyle(color: cMuted, fontSize: 13)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy', style: TextStyle(color: cMuted)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: cPrimary,
            foregroundColor: Colors.white,
          ),
          child: Text(confirm),
        ),
      ],
    ),
  );
}

// ─────────────────────────── AUTH SCREEN ─────────────────────────
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String _error = '';
  bool _obscure = true;
  bool _obscureConfirm = true;

  Future<void> _submit() async {
    final u = _userCtrl.text.trim();
    final p = _passCtrl.text.trim();
    if (u.isEmpty || p.isEmpty) {
      setState(() => _error = 'Vui lòng nhập đầy đủ thông tin');
      return;
    }
    if (!_isLogin && p != _confirmCtrl.text.trim()) {
      setState(() => _error = 'Mật khẩu xác nhận không khớp');
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final user = _isLogin
          ? await ApiService.login(u, p)
          : await ApiService.register(u, p);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              user.isAdmin ? AdminShell(user: user) : CustomerShell(user: user),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffff8f2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const _BrandMark(size: 60),
              const SizedBox(height: 16),
              const Text(
                'Nhà hàng Hương Việt',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: cInk,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Cổng đặt món cho khách hàng',
                style: TextStyle(fontSize: 13, color: cMuted),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: cSurface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _isLogin = true;
                              _error = '';
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isLogin ? cPrimary : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Đăng nhập',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _isLogin ? Colors.white : cMuted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _isLogin = false;
                              _error = '';
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isLogin
                                    ? cPrimary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Đăng ký',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: !_isLogin ? Colors.white : cMuted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildField(
                      controller: _userCtrl,
                      label: 'Tên đăng nhập',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _passCtrl,
                      label: 'Mật khẩu',
                      icon: Icons.lock_outline,
                      obscure: _obscure,
                      toggleObscure: () => setState(() => _obscure = !_obscure),
                    ),
                    if (!_isLogin) ...[
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _confirmCtrl,
                        label: 'Xác nhận mật khẩu',
                        icon: Icons.lock_outline,
                        obscure: _obscureConfirm,
                        toggleObscure: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ],
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cDangerSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _error,
                          style: const TextStyle(color: cDanger, fontSize: 12),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _PrimaryButton(
                      label: _isLogin
                          ? 'Đăng nhập vào nhà hàng'
                          : 'Đăng ký tài khoản',
                      onTap: _submit,
                      loading: _loading,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    VoidCallback? toggleObscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: cMuted, size: 20),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: cMuted,
                  size: 20,
                ),
                onPressed: toggleObscure,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cPrimary, width: 1.5),
        ),
        filled: true,
        fillColor: cBg,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
        labelStyle: const TextStyle(color: cMuted, fontSize: 13),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ──────────────────────── ADMIN SHELL ──────────────────────────
// ═══════════════════════════════════════════════════════════════
class AdminShell extends StatefulWidget {
  final AppUser user;
  const AdminShell({super.key, required this.user});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _tab = 0;
  String _screen = 'home';
  Timer? _refreshTimer;
  bool _isLoadingData = false;

  List<TableModel> _tables = [];
  List<MenuItemModel> _menu = [];
  List<CategoryModel> _cats = [];
  List<OrderModel> _dbOrders = [];
  final Map<int, List<Map<String, dynamic>>> _tableOrderItems = {};
  // Local map for order totals per table (tableId -> total)
  final Map<int, int> _tableOrderTotals = {};
  // Local map for table start times (tableId -> time string)
  final Map<int, String> _tableStartTimes2 = {};

  // Payment state
  int? _payingTableId;
  String _payMethod = 'cash';
  String? _receiptTableCode;
  int? _receiptAmount;
  String? _receiptMethod;

  // Order screen
  int? _orderingTableId;
  final Map<int, int> _orderCart = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_screen != 'order' && _screen != 'receipt' && !_isLoadingData) {
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_isLoadingData) return;
    _isLoadingData = true;
    try {
      // Load tables (with real status from DB)
      try {
        final tables = await ApiService.getTables(widget.user.token);
        if (mounted) setState(() => _tables = tables);
      } catch (_) {}
      // Load menu categories
      try {
        final cats = await ApiService.getCategories(widget.user.token);
        if (mounted) setState(() => _cats = cats);
      } catch (_) {}
      // Load menu items
      try {
        final items = await ApiService.getMenuItems(widget.user.token);
        if (mounted) setState(() => _menu = items);
      } catch (_) {}
      // Load orders to populate totals per table
      try {
        final orders = await ApiService.getAllOrders(widget.user.token);
        final orderItemsByTable = <int, List<Map<String, dynamic>>>{};
        for (final order in orders.where(
          (order) =>
              order.status == 'pending' || order.status == 'waiting_payment',
        )) {
          try {
            final details = await ApiService.getOrderDetails(
              widget.user.token,
              order.id,
            );
            final items = (details?['items'] as List<dynamic>? ?? const [])
                .cast<Map<String, dynamic>>();
            orderItemsByTable
                .putIfAbsent(order.tableId, () => [])
                .addAll(items);
          } catch (_) {}
        }
        if (mounted) {
          setState(() {
            _dbOrders = orders;
            _tableOrderItems
              ..clear()
              ..addAll(orderItemsByTable);
            _tableOrderTotals.clear();
            _tableStartTimes2.clear();
            for (final ord in orders) {
              if (ord.status == 'pending' ||
                  ord.status == 'cooking' ||
                  ord.status == 'waiting_payment') {
                _tableOrderTotals[ord.tableId] =
                    (_tableOrderTotals[ord.tableId] ?? 0) + ord.total;
                if (!_tableStartTimes2.containsKey(ord.tableId)) {
                  // Parse time from createdAt
                  try {
                    final dt = DateTime.parse(
                      ord.createdAt.replaceFirst(' ', 'T'),
                    );
                    _tableStartTimes2[ord.tableId] =
                        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                  } catch (_) {}
                }
              }
            }
          });
        }
      } catch (_) {}
    } finally {
      _isLoadingData = false;
    }
  }

  Future<void> _setTableStatus(int tableId, String status) async {
    try {
      await ApiService.updateTableStatus(widget.user.token, tableId, status);
      await _loadData();
      if (mounted) _showToast(context, 'Đã cập nhật trạng thái bàn');
    } catch (e) {
      if (mounted)
        _showToast(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          success: false,
        );
    }
  }

  void _navigate(String screen, {int? tableId}) {
    setState(() {
      _screen = screen;
      if (tableId != null) {
        if (screen == 'payment') _payingTableId = tableId;
        if (screen == 'order') _orderingTableId = tableId;
      }
    });
  }

  void _switchTab(int t) {
    setState(() {
      _tab = t;
      switch (t) {
        case 0:
          _screen = 'home';
          break;
        case 1:
          _screen = 'tables';
          break;
        case 2:
          _screen = 'menu';
          break;
        case 3:
          _screen = 'invoices';
          break;
        case 4:
          _screen = 'profile';
          break;
      }
    });
  }

  Future<void> _completePayment() async {
    if (_tables.isEmpty) return;
    final tbl = _tables.firstWhere(
      (t) => t.id == _payingTableId,
      orElse: () => _tables[0],
    );
    final paidOrders = _dbOrders
        .where(
          (o) =>
              o.tableId == _payingTableId &&
              (o.status == 'pending' || o.status == 'waiting_payment'),
        )
        .toList();
    try {
      await Future.wait(
        paidOrders.map(
          (order) =>
              ApiService.updateOrderStatus(widget.user.token, order.id, 'paid'),
        ),
      );
      if (_payingTableId != null) {
        await ApiService.updateTableStatus(
          widget.user.token,
          _payingTableId!,
          'Trống',
        );
      }
    } catch (e) {
      if (mounted)
        _showToast(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          success: false,
        );
      return;
    }

    _receiptTableCode = tbl.code;
    _receiptAmount = _tableOrderTotals[_payingTableId] ?? 0;
    _receiptMethod = _payMethod == 'cash'
        ? 'Tiền mặt'
        : _payMethod == 'bank'
        ? 'Chuyển khoản'
        : 'QR thanh toán';
    setState(() {
      _dbOrders.removeWhere((o) => o.tableId == _payingTableId);
      _tableOrderTotals.remove(_payingTableId);
      _tableStartTimes2.remove(_payingTableId);
      for (int i = 0; i < _tables.length; i++) {
        if (_tables[i].id == _payingTableId) {
          _tables[i] = TableModel(
            id: _tables[i].id,
            number: _tables[i].number,
            seats: _tables[i].seats,
            status: 'Trống',
          );
        }
      }
      _screen = 'receipt';
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabScreens = ['home', 'tables', 'menu', 'invoices', 'profile'];
    final mainTab = tabScreens.contains(_screen)
        ? tabScreens.indexOf(_screen)
        : _tab;

    Widget body;
    switch (_screen) {
      case 'home':
        body = AdminHomeScreen(
          user: widget.user,
          tables: _tables,
          menu: _menu,
          orders: _dbOrders,
          onNavigate: _navigate,
        );
        break;
      case 'tables':
        body = AdminTablesScreen(
          tables: _tables,
          tableOrderTotals: _tableOrderTotals,
          tableStartTimes: _tableStartTimes2,
          onNavigate: _navigate,
          onUpdateStatus: _setTableStatus,
        );
        break;
      case 'menu':
        body = AdminMenuScreen(menu: _menu, cats: _cats, onNavigate: _navigate);
        break;
      case 'invoices':
        body = AdminInvoicesScreen(
          tables: _tables,
          orders: _dbOrders,
          tableOrderTotals: _tableOrderTotals,
          onNavigate: _navigate,
        );
        break;
      case 'profile':
        body = AdminProfileScreen(
          user: widget.user,
          onLogout: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AuthScreen()),
            );
          },
          onNavigate: _navigate,
        );
        break;
      case 'order':
        if (_tables.isEmpty) {
          body = const Center(child: CircularProgressIndicator());
          break;
        }
        body = AdminOrderScreen(
          table: _tables.firstWhere(
            (t) => t.id == _orderingTableId,
            orElse: () => _tables[0],
          ),
          menu: _menu,
          cats: _cats,
          cart: _orderCart,
          onBack: () => setState(() => _screen = 'tables'),
          onSubmit: () async {
            // Save order to DB then update table status
            final cart = Map<int, int>.from(_orderCart);
            final tableId = _orderingTableId ?? _tables[0].id;
            final items = cart.entries
                .map((e) => {'menu_item_id': e.key, 'quantity': e.value})
                .toList();
            final total = cart.entries.fold<int>(0, (sum, e) {
              final item = _menu.firstWhere(
                (m) => m.id == e.key,
                orElse: () => _menu[0],
              );
              return sum + item.price * e.value;
            });
            try {
              await ApiService.createOrder(
                widget.user.token,
                widget.user.id,
                tableId,
                total,
                items,
              );
              await ApiService.updateTableStatus(
                widget.user.token,
                tableId,
                'Đang phục vụ',
              );
            } catch (e) {
              if (mounted)
                _showToast(
                  context,
                  e.toString().replaceFirst('Exception: ', ''),
                  success: false,
                );
              return;
            }
            _orderCart.clear();
            // Reload data to reflect new state
            await _loadData();
            setState(() => _screen = 'tables');
            if (mounted) _showToast(context, 'Đã gọi món thành công!');
          },
        );
        break;
      case 'payment':
        if (_tables.isEmpty) {
          body = const Center(child: CircularProgressIndicator());
          break;
        }
        body = AdminPaymentScreen(
          table: _tables.firstWhere(
            (t) => t.id == _payingTableId,
            orElse: () => _tables[0],
          ),
          amount: _tableOrderTotals[_payingTableId] ?? 0,
          items: _tableOrderItems[_payingTableId] ?? const [],
          payMethod: _payMethod,
          onMethodChange: (m) => setState(() => _payMethod = m),
          onBack: () => setState(() => _screen = 'tables'),
          onConfirm: () async {
            final ok = await _showConfirmDialog(
              context,
              title: 'Xác nhận thanh toán',
              body: 'Bạn có chắc chắn muốn hoàn tất thanh toán cho bàn này?',
              confirm: 'Xác nhận',
            );
            if (ok == true) await _completePayment();
          },
        );
        break;
      case 'receipt':
        body = AdminReceiptScreen(
          tableCode: _receiptTableCode ?? '',
          amount: _receiptAmount ?? 0,
          method: _receiptMethod ?? 'Tiền mặt',
          cashier: widget.user.fullName.isEmpty
              ? widget.user.username
              : widget.user.fullName,
          onHome: () => setState(() {
            _screen = 'home';
            _tab = 0;
          }),
        );
        break;
      case 'reports':
        body = AdminReportsScreen(
          token: widget.user.token,
          onBack: () => setState(() => _screen = 'home'),
        );
        break;
      case 'staff':
        body = AdminStaffScreen(
          token: widget.user.token,
          onBack: () => setState(() => _screen = 'home'),
        );
        break;
      case 'shifts':
        body = AdminShiftsScreen(
          onBack: () => setState(() => _screen = 'home'),
        );
        break;
      case 'kitchen':
        body = AdminKitchenScreen(
          orders: _dbOrders,
          onBack: () => setState(() => _screen = 'tables'),
          onUpdateStatus: (orderId, status) async {
            await ApiService.updateOrderStatus(
              widget.user.token,
              orderId,
              status,
            );
            await _loadData();
          },
        );
        break;
      case 'categories':
        body = AdminCategoriesScreen(
          cats: _cats,
          onBack: () => setState(() => _screen = 'menu'),
        );
        break;
      case 'notifications':
        body = AdminNotificationsScreen(
          onBack: () => setState(() => _screen = 'home'),
        );
        break;
      default:
        body = AdminHomeScreen(
          user: widget.user,
          tables: _tables,
          menu: _menu,
          orders: _dbOrders,
          onNavigate: _navigate,
        );
    }

    final showNav = tabScreens.contains(_screen);

    return Scaffold(
      backgroundColor: cBg,
      body: body,
      bottomNavigationBar: showNav
          ? _AdminBottomNav(
              current: mainTab < 0 ? _tab : mainTab,
              onTap: _switchTab,
            )
          : null,
    );
  }
}

class _AdminBottomNav extends StatelessWidget {
  const _AdminBottomNav({required this.current, required this.onTap});
  final int current;
  final ValueChanged<int> onTap;
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, Icons.home, 'Trang chủ'),
      (Icons.table_bar_outlined, Icons.table_bar, 'Bàn ăn'),
      (Icons.menu_book_outlined, Icons.menu_book, 'Thực đơn'),
      (Icons.receipt_long_outlined, Icons.receipt_long, 'Hóa đơn'),
      (Icons.person_outline, Icons.person, 'Cá nhân'),
    ];
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: cSurface,
        border: const Border(top: BorderSide(color: cLine)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final isActive = i == current;
          return GestureDetector(
            onTap: () => onTap(i),
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isActive ? items[i].$2 : items[i].$1,
                    color: isActive ? cPrimary : cMuted,
                    size: 22,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    items[i].$3,
                    style: TextStyle(
                      color: isActive ? cPrimary : cMuted,
                      fontSize: 10,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class AdminHomeScreen extends StatelessWidget {
  final AppUser user;
  final List<TableModel> tables;
  final List<MenuItemModel> menu;
  final List<OrderModel> orders;
  final void Function(String, {int? tableId}) onNavigate;
  const AdminHomeScreen({
    super.key,
    required this.user,
    required this.tables,
    required this.menu,
    required this.orders,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final serving = tables.where((t) => t.status == 'Đang phục vụ').length;
    final empty = tables.where((t) => t.status == 'Trống').length;
    final today = DateTime.now();
    final todayOrders = orders.where((order) {
      final createdAt = DateTime.tryParse(
        order.createdAt.replaceFirst(' ', 'T'),
      );
      return createdAt != null &&
          createdAt.year == today.year &&
          createdAt.month == today.month &&
          createdAt.day == today.day;
    }).toList();
    final revenue = todayOrders
        .where((order) => order.status == 'paid')
        .fold(0, (sum, order) => sum + order.total);
    final processingOrders = orders
        .where(
          (order) => order.status == 'pending' || order.status == 'cooking',
        )
        .length;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero
            // Top Bar showing restaurant name
            Container(
              width: double.infinity,
              color: cSurface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const _BrandMark(size: 34),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Nhà hàng Hương Việt',
                      style: TextStyle(
                        color: cInk,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onNavigate('notifications'),
                    child: Stack(
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          color: cInk,
                          size: 24,
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: cPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: cLine),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    // Overview header
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TỔNG QUAN HÔM NAY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: cMuted,
                                  letterSpacing: 1,
                                ),
                              ),
                              const Text(
                                'Hoạt động nhà hàng',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: cInk,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const _Badge('Đang mở cửa', type: 'success'),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Revenue card with fl_chart
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xff282522),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Doanh thu hôm nay',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    formatMoney(revenue),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: cSuccess.withAlpha(40),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.trending_up, color: Color(0xff4caf50), size: 14),
                                    SizedBox(width: 4),
                                    Text('↑ 12.5%', style: TextStyle(color: Color(0xff4caf50), fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 70,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: 10,
                                barTouchData: BarTouchData(enabled: false),
                                titlesData: const FlTitlesData(show: false),
                                borderData: FlBorderData(show: false),
                                gridData: const FlGridData(show: false),
                                barGroups: [
                                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 4, color: Colors.white24, width: 8, borderRadius: BorderRadius.circular(4))]),
                                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 6, color: Colors.white24, width: 8, borderRadius: BorderRadius.circular(4))]),
                                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 5, color: Colors.white24, width: 8, borderRadius: BorderRadius.circular(4))]),
                                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 8, color: Colors.white24, width: 8, borderRadius: BorderRadius.circular(4))]),
                                  BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 7, color: Colors.white24, width: 8, borderRadius: BorderRadius.circular(4))]),
                                  BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 9, color: Colors.white38, width: 8, borderRadius: BorderRadius.circular(4))]),
                                  BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 10, color: cPrimary, width: 8, borderRadius: BorderRadius.circular(4))]),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Stats 2x2
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.6,
                      children: [
                        _StatCard(
                          icon: Icons.receipt_long,
                          value:
                              '${todayOrders.where((order) => order.status == 'paid').length}',
                          label: 'Đã thanh toán hôm nay',
                          bg: cSuccessSoft,
                          fg: cSuccess,
                        ),
                        _StatCard(
                          icon: Icons.table_bar,
                          value: '$serving',
                          label: 'Đang phục vụ',
                          bg: cPrimarySoft,
                          fg: cPrimary,
                        ),
                        _StatCard(
                          icon: Icons.check_circle_outline,
                          value: '$empty',
                          label: 'Bàn còn trống',
                          bg: cBlueSoft,
                          fg: cBlue,
                        ),
                        _StatCard(
                          icon: Icons.access_time,
                          value: '$processingOrders',
                          label: 'Đơn đang xử lý',
                          bg: const Color(0xfff1ebfa),
                          fg: const Color(0xff7251a5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Quick actions
                    const Text(
                      'Thao tác nhanh',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: cInk,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.3,
                      children: [
                        _QuickAction(
                          icon: Icons.table_bar,
                          label: 'Bàn ăn',
                          onTap: () => onNavigate('tables'),
                        ),
                        _QuickAction(
                          icon: Icons.menu_book,
                          label: 'Thực đơn',
                          onTap: () => onNavigate('menu'),
                        ),
                        _QuickAction(
                          icon: Icons.receipt_long,
                          label: 'Hóa đơn',
                          onTap: () => onNavigate('invoices'),
                        ),
                        _QuickAction(
                          icon: Icons.group,
                          label: 'Nhân viên',
                          onTap: () => onNavigate('staff'),
                        ),
                        _QuickAction(
                          icon: Icons.schedule,
                          label: 'Ca làm',
                          onTap: () => onNavigate('shifts'),
                        ),
                        _QuickAction(
                          icon: Icons.bar_chart,
                          label: 'Báo cáo',
                          onTap: () => onNavigate('reports'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Recent invoices
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Hóa đơn gần đây',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: cInk,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => onNavigate('invoices'),
                          child: const Text(
                            'Xem tất cả',
                            style: TextStyle(color: cPrimary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (orders.isNotEmpty)
                      ...orders.take(3).map((ord) {
                        final tblCode =
                            'B${ord.tableId.toString().padLeft(2, '0')}';
                        final timeStr = ord.createdAt.length >= 16
                            ? ord.createdAt.substring(11, 16)
                            : 'Vừa xong';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _InvoiceCompactRow(
                            tableCode: tblCode,
                            amount: ord.total,
                            time: timeStr,
                            method: ord.status == 'pending'
                                ? 'Chưa TT (DB)'
                                : 'Đã TT',
                          ),
                        );
                      })
                    else
                      const Text(
                        'Chưa có hóa đơn trong cơ sở dữ liệu',
                        style: TextStyle(color: cMuted, fontSize: 12),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.bg,
    required this.fg,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color bg, fg;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: fg,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(color: fg.withAlpha(180), fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cLine),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: cPrimary, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: cInk,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceCompactRow extends StatelessWidget {
  const _InvoiceCompactRow({
    required this.tableCode,
    required this.amount,
    required this.time,
    required this.method,
  });
  final String tableCode;
  final int amount;
  final String time;
  final String method;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cLine),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cPrimarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long, color: cPrimary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HD-$tableCode',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cInk,
                  ),
                ),
                Text(
                  '$tableCode • $time • $method',
                  style: const TextStyle(fontSize: 10, color: cMuted),
                ),
              ],
            ),
          ),
          Text(
            formatMoney(amount),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: cPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────── ADMIN TABLES ────────────────────────────────────
class AdminTablesScreen extends StatefulWidget {
  final List<TableModel> tables;
  final Map<int, int> tableOrderTotals;
  final Map<int, String> tableStartTimes;
  final void Function(String, {int? tableId}) onNavigate;
  final Future<void> Function(int tableId, String status) onUpdateStatus;
  const AdminTablesScreen({
    super.key,
    required this.tables,
    required this.tableOrderTotals,
    required this.tableStartTimes,
    required this.onNavigate,
    required this.onUpdateStatus,
  });
  @override
  State<AdminTablesScreen> createState() => _AdminTablesScreenState();
}

class _AdminTablesScreenState extends State<AdminTablesScreen> {
  String _filter = 'Tất cả';
  String _search = '';

  Color _tableColor(String s) {
    switch (s) {
      case 'Đang phục vụ':
        return cBlue;
      case 'Chờ thanh toán':
        return cWarning;
      case 'Đã đặt':
        return cWarning;
      case 'Trống':
        return cSuccess;
      default:
        return cMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final emptyCount = widget.tables.where((t) => t.status == 'Trống').length;
    final filters = [
      'Tất cả',
      'Trống',
      'Đang phục vụ',
      'Đã đặt',
      'Chờ thanh toán',
    ];
    final filtered = widget.tables.where((t) {
      if (_filter != 'Tất cả' && t.status != _filter) return false;
      if (_search.isNotEmpty &&
          !t.code.toLowerCase().contains(_search.toLowerCase()))
        return false;
      return true;
    }).toList();

    return SafeArea(
      child: widget.tables.isEmpty
          ? const Center(child: CircularProgressIndicator(color: cPrimary))
          : Column(
              children: [
                _ScreenHeader(
                  title: 'Bàn ăn',
                  subtitle: '$emptyCount bàn trống • 3 khu vực',
                ),
                _SearchBox(
                  hint: 'Tìm bàn...',
                  onChanged: (v) => setState(() => _search = v),
                ),
                _ChipFilter(
                  items: filters,
                  selected: _filter,
                  onTap: (v) => setState(() => _filter = v),
                ),
                // Legend
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      _legendDot(cSuccess, 'Trống'),
                      const SizedBox(width: 12),
                      _legendDot(cBlue, 'Phục vụ'),
                      const SizedBox(width: 12),
                      _legendDot(cWarning, 'Đặt/Chờ thu'),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.0,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final t = filtered[i];
                      final color = _tableColor(t.status);
                      final amount = widget.tableOrderTotals[t.id];
                      final time = widget.tableStartTimes[t.id];
                      final canPay =
                          t.status == 'Chờ thanh toán' && amount != null;
                      final hasOpenOrder = widget.tableOrderTotals.containsKey(
                        t.id,
                      );
                      return Container(
                        decoration: BoxDecoration(
                          color: cSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border(
                            top: BorderSide(color: color, width: 3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(8),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  t.code,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: cInk,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.table_bar,
                                      color: color,
                                      size: 20,
                                    ),
                                    PopupMenuButton<String>(
                                      tooltip: 'Đổi trạng thái bàn',
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: cMuted,
                                      ),
                                      onSelected: (status) =>
                                          widget.onUpdateStatus(t.id, status),
                                      itemBuilder: (_) => [
                                        for (final status in [
                                          'Trống',
                                          'Đang phục vụ',
                                          'Đã đặt',
                                          if (hasOpenOrder) 'Chờ thanh toán',
                                        ])
                                          if (status != t.status)
                                            PopupMenuItem(
                                              value: status,
                                              child: Text(status),
                                            ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.status,
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${t.seats} chỗ${time != null ? ' • $time' : ''}',
                              style: const TextStyle(
                                color: cMuted,
                                fontSize: 10,
                              ),
                            ),
                            if (amount != null)
                              Text(
                                formatMoney(amount),
                                style: const TextStyle(
                                  color: cPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 34,
                              child: canPay
                                  ? ElevatedButton.icon(
                                      onPressed: () => widget.onNavigate(
                                        'payment',
                                        tableId: t.id,
                                      ),
                                      icon: const Icon(
                                        Icons.payments_outlined,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'Thu tiền',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: cPrimary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    )
                                  : OutlinedButton.icon(
                                      onPressed: () => hasOpenOrder
                                          ? widget.onNavigate('kitchen')
                                          : widget.onNavigate(
                                              'order',
                                              tableId: t.id,
                                            ),
                                      icon: Icon(
                                        hasOpenOrder
                                            ? Icons.soup_kitchen_outlined
                                            : Icons.add,
                                        size: 16,
                                      ),
                                      label: Text(
                                        hasOpenOrder ? 'Mở bếp' : 'Gọi món',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: cInk,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        side: const BorderSide(color: cLine),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _legendDot(Color c, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: cMuted, fontSize: 10)),
      ],
    );
  }
}

// ─────────────── ADMIN MENU ──────────────────────────────────────
class AdminMenuScreen extends StatefulWidget {
  final List<MenuItemModel> menu;
  final List<CategoryModel> cats;
  final void Function(String, {int? tableId}) onNavigate;
  const AdminMenuScreen({
    super.key,
    required this.menu,
    required this.cats,
    required this.onNavigate,
  });
  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  String _filter = 'Tất cả';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final available = widget.menu.where((m) => m.available).length;
    final filterItems = ['Tất cả', ...widget.cats.map((c) => c.name)];
    final filtered = widget.menu.where((m) {
      if (_search.isNotEmpty &&
          !m.name.toLowerCase().contains(_search.toLowerCase()))
        return false;
      if (_filter != 'Tất cả') {
        final cat = _categoryName(m.categoryId, widget.cats);
        if (cat != _filter) return false;
      }
      return true;
    }).toList();

    return SafeArea(
      child: Column(
        children: [
          _ScreenHeader(
            title: 'Thực đơn',
            subtitle: '$available món đang kinh doanh',
          ),
          _SearchBox(
            hint: 'Tìm món ăn...',
            onChanged: (v) => setState(() => _search = v),
          ),
          _ChipFilter(
            items: filterItems,
            selected: _filter,
            onTap: (v) => setState(() => _filter = v),
          ),
          // Management banner
          GestureDetector(
            onTap: () => widget.onNavigate('categories'),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cDarkCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.grid_view, color: Colors.white70, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Quản lý danh mục',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white54,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final m = filtered[i];
                final cat = _categoryName(m.categoryId, widget.cats);
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cLine),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: m.imageUrl,
                          width: 82,
                          height: 76,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(
                            width: 82,
                            height: 76,
                            color: cLine,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (_, _, _) => Container(
                            width: 82,
                            height: 76,
                            color: cLine,
                            child: const Icon(
                              Icons.restaurant,
                              color: cMuted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Badge(cat, type: 'info'),
                            const SizedBox(height: 4),
                            Text(
                              m.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: cInk,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatMoney(m.price),
                              style: const TextStyle(
                                color: cPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (!m.available)
                              const _Badge('Hết hàng', type: 'danger'),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: cMuted,
                        size: 14,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────── ADMIN ORDER ─────────────────────────────────────
class AdminOrderScreen extends StatefulWidget {
  final TableModel table;
  final List<MenuItemModel> menu;
  final List<CategoryModel> cats;
  final Map<int, int> cart;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  const AdminOrderScreen({
    super.key,
    required this.table,
    required this.menu,
    required this.cats,
    required this.cart,
    required this.onBack,
    required this.onSubmit,
  });
  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> {
  String _filter = 'Tất cả';
  String _search = '';

  int get _total => widget.cart.entries.fold(0, (sum, e) {
    final item = widget.menu.firstWhere(
      (m) => m.id == e.key,
      orElse: () => widget.menu.first,
    );
    return sum + item.price * e.value;
  });
  int get _count => widget.cart.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final filterItems = ['Tất cả', ...widget.cats.map((c) => c.name)];
    final available = widget.menu.where((m) {
      if (!m.available) return false;
      if (_search.isNotEmpty &&
          !m.name.toLowerCase().contains(_search.toLowerCase()))
        return false;
      if (_filter != 'Tất cả') {
        if (_categoryName(m.categoryId, widget.cats) != _filter) return false;
      }
      return true;
    }).toList();

    return SafeArea(
      child: Column(
        children: [
          _ScreenHeader(
            title: 'Gọi món • ${widget.table.code}',
            subtitle: 'Chọn món cho bàn',
            onBack: widget.onBack,
          ),
          _SearchBox(onChanged: (v) => setState(() => _search = v)),
          _ChipFilter(
            items: filterItems,
            selected: _filter,
            onTap: (v) => setState(() => _filter = v),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: available.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final m = available[i];
                final qty = widget.cart[m.id] ?? 0;
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cLine),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          m.imageUrl,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              Container(width: 64, height: 64, color: cLine),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: cInk,
                              ),
                            ),
                            Text(
                              formatMoney(m.price),
                              style: const TextStyle(
                                color: cPrimary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (qty == 0)
                        GestureDetector(
                          onTap: () => setState(() => widget.cart[m.id] = 1),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: cPrimary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            _stepBtn(Icons.remove, () {
                              setState(() {
                                if ((widget.cart[m.id] ?? 0) <= 1) {
                                  widget.cart.remove(m.id);
                                } else {
                                  widget.cart[m.id] = widget.cart[m.id]! - 1;
                                }
                              });
                            }),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                '$qty',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _stepBtn(
                              Icons.add,
                              () => setState(() => widget.cart[m.id] = qty + 1),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_count > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cSurface,
                border: const Border(top: BorderSide(color: cLine)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_count món',
                          style: const TextStyle(color: cMuted, fontSize: 12),
                        ),
                        Text(
                          formatMoney(_total),
                          style: const TextStyle(
                            color: cInk,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: widget.onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Xác nhận đơn →'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: cBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: cLine),
        ),
        child: Icon(icon, size: 14, color: cInk),
      ),
    );
  }
}

// ─────────────── ADMIN INVOICES ──────────────────────────────────
class AdminInvoicesScreen extends StatefulWidget {
  final List<TableModel> tables;
  final List<OrderModel> orders;
  final Map<int, int> tableOrderTotals;
  final void Function(String, {int? tableId}) onNavigate;
  const AdminInvoicesScreen({
    super.key,
    required this.tables,
    required this.orders,
    required this.tableOrderTotals,
    required this.onNavigate,
  });
  @override
  State<AdminInvoicesScreen> createState() => _AdminInvoicesScreenState();
}

class _AdminInvoicesScreenState extends State<AdminInvoicesScreen> {
  String _filter = 'Tất cả';

  @override
  Widget build(BuildContext context) {
    final processingOrders = widget.orders
        .where(
          (order) => order.status == 'pending' || order.status == 'cooking',
        )
        .toList();
    final waitingOrders = widget.orders
        .where((order) => order.status == 'waiting_payment')
        .toList();
    final paidOrders = widget.orders
        .where((order) => order.status == 'paid')
        .toList();
    final cancelledOrders = widget.orders
        .where((order) => order.status == 'cancelled')
        .toList();
    final totalWait = waitingOrders.fold(0, (sum, order) => sum + order.total);

    return SafeArea(
      child: Column(
        children: [
          _ScreenHeader(title: 'Hóa đơn', subtitle: 'Theo dõi và thu tiền'),
          _SearchBox(),
          _ChipFilter(
            items: const ['Tất cả', 'Chưa TT', 'Đã TT', 'Đã hủy'],
            selected: _filter,
            onTap: (v) => setState(() => _filter = v),
          ),
          // Summary strip
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cDarkCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Chờ thanh toán • ${waitingOrders.length} hóa đơn',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  formatMoney(totalWait),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_filter == 'Tất cả' || _filter == 'Chưa TT') ...[
                  if (processingOrders.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Đang chế biến • ${processingOrders.length} đơn',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: cWarning,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => widget.onNavigate('kitchen'),
                          icon: const Icon(
                            Icons.soup_kitchen_outlined,
                            size: 16,
                          ),
                          label: const Text('Mở bếp'),
                        ),
                      ],
                    ),
                    ...processingOrders.map(
                      (order) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _InvoiceCompactRow(
                          tableCode:
                              'B${order.tableId.toString().padLeft(2, '0')}',
                          amount: order.total,
                          time: order.createdAt.length >= 16
                              ? order.createdAt.substring(11, 16)
                              : '',
                          method: order.status == 'pending'
                              ? 'Chờ bếp nhận'
                              : 'Đang nấu',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Text(
                    'Chờ thanh toán',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: cPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...waitingOrders.map((ord) {
                    final timeStr = ord.createdAt.length >= 16
                        ? ord.createdAt.substring(11, 16)
                        : 'Vừa xong';
                    final matchingTables = widget.tables
                        .where((item) => item.id == ord.tableId)
                        .toList();
                    final table = matchingTables.isEmpty
                        ? TableModel(
                            id: ord.tableId,
                            number: ord.tableId,
                            seats: 4,
                            status: 'Đang phục vụ',
                          )
                        : matchingTables.first;
                    return _InvoiceCard(
                      table: table,
                      amount: ord.total,
                      time: timeStr,
                      onPay: () =>
                          widget.onNavigate('payment', tableId: ord.tableId),
                    );
                  }),
                ],
                if (_filter == 'Tất cả' || _filter == 'Đã TT') ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Đã thanh toán',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: cMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...paidOrders.map((order) {
                    final matchingTables = widget.tables
                        .where((item) => item.id == order.tableId)
                        .toList();
                    final time = order.createdAt.length >= 16
                        ? order.createdAt.substring(11, 16)
                        : '';
                    return _InvoiceCompactRow(
                      tableCode: matchingTables.isEmpty
                          ? 'B${order.tableId.toString().padLeft(2, '0')}'
                          : matchingTables.first.code,
                      amount: order.total,
                      time: time,
                      method: 'Đã thanh toán',
                    );
                  }),
                ],
                if (_filter == 'Đã hủy')
                  ...cancelledOrders.map(
                    (order) => _InvoiceCompactRow(
                      tableCode: 'B${order.tableId.toString().padLeft(2, '0')}',
                      amount: order.total,
                      time: order.createdAt.length >= 16
                          ? order.createdAt.substring(11, 16)
                          : '',
                      method: 'Đã hủy',
                    ),
                  ),
                if ((_filter == 'Chưa TT' &&
                        waitingOrders.isEmpty &&
                        processingOrders.isEmpty) ||
                    (_filter == 'Đã TT' && paidOrders.isEmpty) ||
                    (_filter == 'Đã hủy' && cancelledOrders.isEmpty) ||
                    (_filter == 'Tất cả' && widget.orders.isEmpty))
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Không có hóa đơn trong cơ sở dữ liệu',
                        style: TextStyle(color: cMuted),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.table,
    required this.amount,
    required this.time,
    required this.onPay,
  });
  final TableModel table;
  final int amount;
  final String time;
  final VoidCallback onPay;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cLine),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: table.status == 'Chờ thanh toán'
                      ? cWarningSoft
                      : cBlueSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: table.status == 'Chờ thanh toán' ? cWarning : cBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HD-${table.code}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cInk,
                      ),
                    ),
                    Text(
                      '${table.code} • $time',
                      style: const TextStyle(color: cMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              _Badge(
                table.status == 'Chờ thanh toán' ? 'Chờ TT' : 'Đang phục vụ',
                type: table.status == 'Chờ thanh toán' ? 'warning' : 'info',
              ),
            ],
          ),
          const Divider(height: 16, color: cLine),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatMoney(amount),
                style: const TextStyle(
                  color: cPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (table.status == 'Chờ thanh toán')
                ElevatedButton(
                  onPressed: onPay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(90, 34),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Thu tiền', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────── ADMIN PAYMENT ───────────────────────────────────
class AdminPaymentScreen extends StatelessWidget {
  final TableModel table;
  final int amount;
  final List<Map<String, dynamic>> items;
  final String payMethod;
  final ValueChanged<String> onMethodChange;
  final VoidCallback onBack;
  final VoidCallback onConfirm;
  const AdminPaymentScreen({
    super.key,
    required this.table,
    required this.amount,
    required this.items,
    required this.payMethod,
    required this.onMethodChange,
    required this.onBack,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ScreenHeader(
              title: 'Thanh toán',
              subtitle: 'HD-${table.code} • ${table.code}',
              onBack: onBack,
            ),
            const SizedBox(height: 16),
            // Bill card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cLine),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'CHI TIẾT HÓA ĐƠN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: cMuted,
                          letterSpacing: 1,
                        ),
                      ),
                      const _Badge('Chưa thanh toán', type: 'warning'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    const Text(
                      'Không có chi tiết món trong cơ sở dữ liệu',
                      style: TextStyle(color: cMuted, fontSize: 12),
                    )
                  else
                    ...items.map((item) {
                      final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
                      final price = (item['price'] as num?)?.round() ?? 0;
                      return _BillRow(
                        name: '${item['name']} x$quantity',
                        price: price * quantity,
                      );
                    }),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: List.generate(
                        30,
                        (i) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            height: 1,
                            color: i.isEven ? cLine : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng thanh toán',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cInk,
                        ),
                      ),
                      Text(
                        formatMoney(amount),
                        style: const TextStyle(
                          color: cPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Phương thức thanh toán',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: cInk,
              ),
            ),
            const SizedBox(height: 10),
            _PaymentMethodTile(
              label: 'Tiền mặt',
              icon: Icons.payments_outlined,
              value: 'cash',
              selected: payMethod,
              onTap: onMethodChange,
            ),
            _PaymentMethodTile(
              label: 'Chuyển khoản',
              icon: Icons.account_balance_outlined,
              value: 'bank',
              selected: payMethod,
              onTap: onMethodChange,
            ),
            _PaymentMethodTile(
              label: 'QR thanh toán',
              icon: Icons.qr_code_2,
              value: 'qr',
              selected: payMethod,
              onTap: onMethodChange,
            ),
            const SizedBox(height: 24),
            _PrimaryButton(
              label: 'Xác nhận thanh toán • ${formatMoney(amount)}',
              onTap: onConfirm,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({required this.name, required this.price});
  final String name;
  final int price;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 13, color: cInk)),
          Text(
            formatMoney(price),
            style: const TextStyle(fontSize: 13, color: cMuted),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
  });
  final String label, value, selected;
  final IconData icon;
  final ValueChanged<String> onTap;
  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? cPrimarySoft : cSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? cPrimary : cLine,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? cPrimary : cMuted, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? cPrimary : cInk,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: cPrimary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────── ADMIN RECEIPT ───────────────────────────────────
class AdminReceiptScreen extends StatelessWidget {
  final String tableCode;
  final int amount;
  final String method;
  final String cashier;
  final VoidCallback onHome;
  const AdminReceiptScreen({
    super.key,
    required this.tableCode,
    required this.amount,
    required this.method,
    required this.cashier,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} - ${now.day}/${now.month}/${now.year}';

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff1a5c3e), cBg],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: cSuccess,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: cSuccess.withAlpha(80),
                          blurRadius: 20,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'THANH TOÁN THÀNH CÔNG',
                    style: TextStyle(
                      color: cSuccess,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatMoney(amount),
                    style: const TextStyle(
                      color: cInk,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bàn $tableCode đã thanh toán xong',
                    style: const TextStyle(color: cMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cLine),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const _BrandMark(size: 36),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Nhà hàng Hương Việt',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: cInk,
                                  ),
                                ),
                                Text(
                                  'HD-$tableCode',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: cMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 20, color: cLine),
                        _ReceiptRow(
                          label: 'Mã hóa đơn',
                          value: 'HD-$tableCode',
                        ),
                        _ReceiptRow(label: 'Thời gian', value: timeStr),
                        _ReceiptRow(label: 'Phương thức', value: method),
                        _ReceiptRow(label: 'Thu ngân', value: cashier),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final doc = pw.Document();
                            doc.addPage(
                              pw.Page(
                                pageFormat: PdfPageFormat.roll80,
                                build: (pw.Context context) {
                                  return pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                                    children: [
                                      pw.Text('NHA HANG HUONG VIET', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                                      pw.SizedBox(height: 4),
                                      pw.Text('HOA DON THANH TOAN', style: const pw.TextStyle(fontSize: 12)),
                                      pw.Divider(),
                                      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                                        pw.Text('Ban:'),
                                        pw.Text(tableCode),
                                      ]),
                                      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                                        pw.Text('Thoi gian:'),
                                        pw.Text(timeStr),
                                      ]),
                                      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                                        pw.Text('PT Thanh toan:'),
                                        pw.Text(method),
                                      ]),
                                      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                                        pw.Text('Thu ngan:'),
                                        pw.Text(cashier),
                                      ]),
                                      pw.Divider(),
                                      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                                        pw.Text('TONG CONG:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                                        pw.Text(formatMoney(amount), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                                      ]),
                                      pw.SizedBox(height: 10),
                                      pw.Text('Cam on quy khach & Hen gap lai!', style: const pw.TextStyle(fontSize: 9)),
                                    ],
                                  );
                                },
                              ),
                            );
                            await Printing.layoutPdf(
                              onLayout: (PdfPageFormat format) async => doc.save(),
                              name: 'HoaDon_$tableCode',
                            );
                          },
                          icon: const Icon(Icons.print_outlined, size: 16),
                          label: const Text('In biên lai'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: cInk,
                            side: const BorderSide(color: cLine),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.share_outlined, size: 16),
                          label: const Text('Chia sẻ'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: cInk,
                            side: const BorderSide(color: cLine),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: onHome,
                      child: const Text(
                        'Về trang chủ',
                        style: TextStyle(
                          color: cPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: cMuted, fontSize: 12)),
          Text(
            value,
            style: const TextStyle(
              color: cInk,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────── ADMIN REPORTS ───────────────────────────────────
class AdminReportsScreen extends StatefulWidget {
  final String token;
  final VoidCallback onBack;
  const AdminReportsScreen({
    super.key,
    required this.token,
    required this.onBack,
  });
  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  int _totalRevenue = 0;
  List<Map<String, dynamic>> _dailyReport = [];
  bool _loading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/reports/daily'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode != 200)
        throw Exception('Lỗi tải báo cáo (${res.statusCode})');
      final List list = jsonDecode(res.body);
      if (mounted) {
        setState(() {
          _dailyReport = list.cast<Map<String, dynamic>>();
          _totalRevenue = _dailyReport
              .fold<num>(
                0,
                (sum, row) =>
                    sum +
                    (num.tryParse(row['revenue']?.toString() ?? '0') ?? 0),
              )
              .toInt();
        });
      }
    } catch (e) {
      if (mounted)
        setState(
          () => _loadError = e.toString().replaceFirst('Exception: ', ''),
        );
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ScreenHeader(title: 'Báo cáo doanh thu', onBack: widget.onBack),
            const SizedBox(height: 12),
            // Report hero
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cDarkCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DOANH THU 7 NGÀY GẦN NHẤT',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    formatMoney(_totalRevenue),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cLine),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Doanh thu theo ngày',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cInk,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_loading)
                      const Center(
                        child: CircularProgressIndicator(color: cPrimary),
                      )
                    else if (_loadError != null)
                      Text(_loadError!, style: const TextStyle(color: cDanger))
                    else if (_dailyReport.isEmpty)
                      const Text(
                        'Chưa có doanh thu trong cơ sở dữ liệu',
                        style: TextStyle(color: cMuted),
                      )
                    else
                      ..._dailyReport.map(
                        (row) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                row['day']?.toString() ?? '',
                                style: const TextStyle(
                                  color: cInk,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                formatMoney(
                                  (num.tryParse(
                                            row['revenue']?.toString() ?? '0',
                                          ) ??
                                          0)
                                      .round(),
                                ),
                                style: const TextStyle(
                                  color: cPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────── ADMIN STAFF ─────────────────────────────────────
class AdminStaffScreen extends StatefulWidget {
  final String token;
  final VoidCallback onBack;
  const AdminStaffScreen({
    super.key,
    required this.token,
    required this.onBack,
  });
  @override
  State<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends State<AdminStaffScreen> {
  List<StaffUserModel> _staff = [];
  bool _loading = true;
  String? _loadError;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final list = await ApiService.getStaff(widget.token);
      if (mounted) setState(() => _staff = list);
    } catch (e) {
      if (mounted)
        setState(
          () => _loadError = e.toString().replaceFirst('Exception: ', ''),
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddEditDialog([StaffUserModel? item]) {
    final isEdit = item != null;
    final userCtrl = TextEditingController(text: item?.username ?? '');
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController(text: item?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: item?.phone ?? '');
    String selectedRole = item?.role ?? 'Phục vụ';
    const roles = ['Quản lý', 'Phục vụ', 'Thu ngân', 'Đầu bếp'];
    String err = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isEdit ? 'Sửa thông tin nhân viên' : 'Thêm nhân viên mới',
            style: const TextStyle(fontWeight: FontWeight.bold, color: cInk),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isEdit)
                  TextField(
                    controller: userCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên đăng nhập *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                if (!isEdit) const SizedBox(height: 12),
                if (!isEdit)
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu *',
                      border: OutlineInputBorder(),
                    ),
                  )
                else
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu mới (bỏ trống nếu không đổi)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: roles.contains(selectedRole) ? selectedRole : roles[0],
                  decoration: const InputDecoration(
                    labelText: 'Vai trò',
                    border: OutlineInputBorder(),
                  ),
                  items: roles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDlgState(() => selectedRole = v);
                  },
                ),
                if (err.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    err,
                    style: const TextStyle(color: cDanger, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy', style: TextStyle(color: cMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (!isEdit && userCtrl.text.trim().isEmpty) {
                  setDlgState(() => err = 'Vui lòng nhập tên đăng nhập');
                  return;
                }
                if (!isEdit && passCtrl.text.trim().isEmpty) {
                  setDlgState(() => err = 'Vui lòng nhập mật khẩu');
                  return;
                }
                try {
                  if (isEdit) {
                    final data = {
                      'full_name': nameCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'role': selectedRole,
                    };
                    if (passCtrl.text.trim().isNotEmpty) {
                      data['password'] = passCtrl.text.trim();
                    }
                    await ApiService.updateStaff(widget.token, item.id, data);
                  } else {
                    await ApiService.createStaff(widget.token, {
                      'username': userCtrl.text.trim(),
                      'password': passCtrl.text.trim().isEmpty
                          ? '123456'
                          : passCtrl.text.trim(),
                      'full_name': nameCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'role': selectedRole,
                    });
                  }
                  if (mounted) {
                    Navigator.pop(ctx);
                    _loadStaff();
                    _showToast(
                      context,
                      isEdit
                          ? 'Cập nhật thành công!'
                          : 'Thêm nhân viên thành công!',
                    );
                  }
                } catch (e) {
                  setDlgState(
                    () => err = e.toString().replaceFirst('Exception: ', ''),
                  );
                }
              },
              child: Text(isEdit ? 'Lưu' : 'Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStatus(StaffUserModel s) async {
    final newStatus = s.isActive ? 'locked' : 'active';
    try {
      await ApiService.updateStaffStatus(widget.token, s.id, newStatus);
      await _loadStaff();
      if (mounted)
        _showToast(
          context,
          newStatus == 'active'
              ? 'Đã mở khóa tài khoản!'
              : 'Đã khóa tài khoản!',
        );
    } catch (e) {
      if (mounted)
        _showToast(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          success: false,
        );
    }
  }

  Future<void> _deleteStaff(StaffUserModel s) async {
    final ok = await _showConfirmDialog(
      context,
      title: 'Xóa nhân viên',
      body: 'Bạn có chắc muốn xóa tài khoản "${s.username}" (${s.fullName})?',
      confirm: 'Xóa',
    );
    if (ok == true) {
      try {
        await ApiService.deleteStaff(widget.token, s.id);
        await _loadStaff();
        if (mounted) _showToast(context, 'Đã xóa nhân viên!');
      } catch (e) {
        if (mounted)
          _showToast(
            context,
            e.toString().replaceFirst('Exception: ', ''),
            success: false,
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _staff.where((s) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return s.fullName.toLowerCase().contains(q) ||
          s.username.toLowerCase().contains(q) ||
          s.role.toLowerCase().contains(q);
    }).toList();
    final activeCount = _staff.where((s) => s.isActive).length;

    return SafeArea(
      child: Scaffold(
        backgroundColor: cBg,
        floatingActionButton: FloatingActionButton(
          backgroundColor: cPrimary,
          onPressed: () => _showAddEditDialog(),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: Column(
          children: [
            _ScreenHeader(
              title: 'Nhân viên',
              subtitle:
                  '${_staff.length} tài khoản • $activeCount đang hoạt động',
              onBack: widget.onBack,
            ),
            _SearchBox(
              hint: 'Tìm nhân viên...',
              onChanged: (v) => setState(() => _search = v),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: cPrimary),
                    )
                  : _loadError != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _loadError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: cDanger),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _loadStaff,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    )
                  : filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'Không có nhân viên nào',
                        style: TextStyle(color: cMuted),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final s = filtered[i];
                        final initial =
                            (s.fullName.isNotEmpty ? s.fullName : s.username)
                                .characters
                                .first
                                .toUpperCase();
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: cLine),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: cPrimarySoft,
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    color: cPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.fullName.isNotEmpty
                                          ? s.fullName
                                          : s.username,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: cInk,
                                      ),
                                    ),
                                    Text(
                                      '${s.role}${s.phone.isNotEmpty ? " • ${s.phone}" : ""} (@${s.username})',
                                      style: const TextStyle(
                                        color: cMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _toggleStatus(s),
                                child: _Badge(
                                  s.isActive ? 'Hoạt động' : 'Đã khóa',
                                  type: s.isActive ? 'success' : 'danger',
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: cMuted,
                                  size: 20,
                                ),
                                onSelected: (action) {
                                  if (action == 'edit') _showAddEditDialog(s);
                                  if (action == 'toggle') _toggleStatus(s);
                                  if (action == 'delete') _deleteStaff(s);
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 18, color: cInk),
                                        SizedBox(width: 8),
                                        Text('Chỉnh sửa'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'toggle',
                                    child: Row(
                                      children: [
                                        Icon(
                                          s.isActive
                                              ? Icons.lock
                                              : Icons.lock_open,
                                          size: 18,
                                          color: cWarning,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          s.isActive
                                              ? 'Khóa tài khoản'
                                              : 'Mở khóa',
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (s.role != 'Quản lý')
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            size: 18,
                                            color: cDanger,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Xóa',
                                            style: TextStyle(color: cDanger),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────── ADMIN SHIFTS ─────────────────────────────────────
class AdminShiftsScreen extends StatelessWidget {
  final VoidCallback onBack;
  const AdminShiftsScreen({super.key, required this.onBack});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _ScreenHeader(title: 'Ca làm việc', onBack: onBack),
          Expanded(
            child: const Center(
              child: Text(
                'Chưa có lịch ca trong cơ sở dữ liệu',
                style: TextStyle(color: cMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────── ADMIN KITCHEN ───────────────────────────────────
class AdminKitchenScreen extends StatefulWidget {
  final List<OrderModel> orders;
  final VoidCallback onBack;
  final Future<void> Function(int orderId, String status) onUpdateStatus;
  const AdminKitchenScreen({
    super.key,
    required this.orders,
    required this.onBack,
    required this.onUpdateStatus,
  });
  @override
  State<AdminKitchenScreen> createState() => _AdminKitchenScreenState();
}

class _AdminKitchenScreenState extends State<AdminKitchenScreen> {
  int _tab = 0;
  final Set<int> _updatingOrders = {};

  @override
  Widget build(BuildContext context) {
    const tabs = ['Chờ chế biến', 'Đang làm', 'Hoàn thành'];
    final statuses = [
      ['pending'],
      ['cooking'],
      ['waiting_payment'],
    ];
    final orders = widget.orders
        .where((order) => statuses[_tab].contains(order.status))
        .toList();
    return SafeArea(
      child: Column(
        children: [
          _ScreenHeader(title: 'Theo dõi chế biến', onBack: widget.onBack),
          Row(
            children: List.generate(3, (i) {
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tab = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _tab == i ? cPrimary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      tabs[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _tab == i ? cPrimary : cMuted,
                        fontSize: 12,
                        fontWeight: _tab == i
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final order = orders[i];
                final tableCode =
                    'B${order.tableId.toString().padLeft(2, '0')}';
                final time = order.createdAt.length >= 16
                    ? order.createdAt.substring(11, 16)
                    : '';
                final nextStatus = order.status == 'pending'
                    ? 'cooking'
                    : 'waiting_payment';
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cLine),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cPrimarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: cPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đơn hàng #OD${order.id} • ${formatMoney(order.total)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: cInk,
                              ),
                            ),
                            Text(
                              '$tableCode • $time',
                              style: const TextStyle(
                                color: cMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (order.status == 'waiting_payment')
                        const _Badge('Chờ thanh toán', type: 'warning')
                      else
                        TextButton(
                          onPressed: _updatingOrders.contains(order.id)
                              ? null
                              : () async {
                                  setState(() => _updatingOrders.add(order.id));
                                  try {
                                    await widget.onUpdateStatus(
                                      order.id,
                                      nextStatus,
                                    );
                                  } catch (e) {
                                    if (mounted) {
                                      _showToast(
                                        context,
                                        e.toString().replaceFirst(
                                          'Exception: ',
                                          '',
                                        ),
                                        success: false,
                                      );
                                    }
                                  } finally {
                                    if (mounted)
                                      setState(
                                        () => _updatingOrders.remove(order.id),
                                      );
                                  }
                                },
                          child: Text(
                            order.status == 'pending' ? 'Nhận đơn' : 'Hoàn tất',
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────── ADMIN CATEGORIES ────────────────────────────────
class AdminCategoriesScreen extends StatelessWidget {
  final List<CategoryModel> cats;
  final VoidCallback onBack;
  const AdminCategoriesScreen({
    super.key,
    required this.cats,
    required this.onBack,
  });
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _ScreenHeader(
            title: 'Danh mục món',
            subtitle: '${cats.length} danh mục',
            onBack: onBack,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cWarningSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: cWarning, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Thay đổi danh mục sẽ ảnh hưởng đến tất cả món ăn thuộc danh mục đó.',
                      style: TextStyle(color: cWarning, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cats.length,
              separatorBuilder: (_, _) =>
                  const Divider(color: cLine, height: 1),
              itemBuilder: (_, i) {
                return ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cPrimarySoft,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.grid_view,
                      color: cPrimary,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    cats[i].name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: cInk,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: cMuted,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────── ADMIN NOTIFICATIONS ─────────────────────────────
class AdminNotificationsScreen extends StatelessWidget {
  final VoidCallback onBack;
  const AdminNotificationsScreen({super.key, required this.onBack});
  @override
  Widget build(BuildContext context) {
    const List<(String, String, bool, IconData, Color, Color)> notifs = [];
    return SafeArea(
      child: Column(
        children: [
          _ScreenHeader(
            title: 'Thông báo',
            subtitle: '${notifs.length} thông báo chưa đọc',
            onBack: onBack,
          ),
          Expanded(
            child: notifs.isEmpty
                ? const Center(
                    child: Text(
                      'Chưa có thông báo trong cơ sở dữ liệu',
                      style: TextStyle(color: cMuted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final n = notifs[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: n.$3 ? cBg : cSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: n.$3 ? cLine : cLine),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: n.$5,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(n.$4, color: n.$6, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.$1,
                                    style: TextStyle(
                                      fontWeight: n.$3
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 13,
                                      color: cInk,
                                    ),
                                  ),
                                  Text(
                                    n.$2,
                                    style: const TextStyle(
                                      color: cMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (n.$3)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: cPrimary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────── ADMIN PROFILE ───────────────────────────────────
class AdminProfileScreen extends StatelessWidget {
  final AppUser user;
  final VoidCallback onLogout;
  final void Function(String, {int? tableId}) onNavigate;
  const AdminProfileScreen({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onNavigate,
  });
  @override
  Widget build(BuildContext context) {
    final initial = user.username.isNotEmpty
        ? user.username[0].toUpperCase()
        : 'A';
    final settings = [
      (
        Icons.notifications_outlined,
        'Thông báo',
        () => onNavigate('notifications'),
      ),
      (Icons.bar_chart, 'Báo cáo doanh thu', () => onNavigate('reports')),
      (Icons.group_outlined, 'Quản lý nhân viên', () => onNavigate('staff')),
      (Icons.schedule, 'Ca làm việc', () => onNavigate('shifts')),
      (Icons.restaurant_menu, 'Bếp & chế biến', () => onNavigate('kitchen')),
      (Icons.help_outline, 'Trợ giúp', () {}),
    ];
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Hero
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xffa43c1c), Color(0xffc55c31)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white.withAlpha(50),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.fullName.isEmpty ? user.username : user.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${user.username} • ${user.role}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  const _Badge('Đang hoạt động', type: 'success'),
                ],
              ),
            ),
            // Restaurant card
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cLine),
              ),
              child: const Row(
                children: [
                  _BrandMark(size: 40),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nhà hàng Hương Việt',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cInk,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Settings
            ...settings.map(
              (s) => ListTile(
                leading: Icon(s.$1, color: cPrimary, size: 22),
                title: Text(
                  s.$2,
                  style: const TextStyle(color: cInk, fontSize: 13),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 13,
                  color: cMuted,
                ),
                onTap: s.$3,
              ),
            ),
            const Divider(color: cLine, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.logout, color: cDanger, size: 22),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(
                  color: cDanger,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: onLogout,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ─────────────────────── CUSTOMER SHELL ───────────────────────
// ═══════════════════════════════════════════════════════════════
class CustomerShell extends StatefulWidget {
  final AppUser user;
  const CustomerShell({super.key, required this.user});
  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _tab = 0;
  List<CategoryModel> _cats = [];
  List<MenuItemModel> _menuItems = [];
  List<TableModel> _tables = [];
  List<OrderModel> _customerOrders = [];
  int? _selectedTableId;
  final Map<int, int> _cart = {};
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final cats = await ApiService.getCategories(widget.user.token);
      final items = await ApiService.getMenuItems(widget.user.token);
      final tables = await ApiService.getTables(widget.user.token);
      final orders = await ApiService.getOrders(
        widget.user.token,
        widget.user.id,
      );
      if (mounted) {
        setState(() {
          _cats = cats;
          _menuItems = items;
          _tables = tables;
          _customerOrders = orders;
        });
      }
    } catch (e) {
      if (mounted)
        setState(
          () => _loadError = e.toString().replaceFirst('Exception: ', ''),
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: cBg,
        body: Center(child: CircularProgressIndicator(color: cPrimary)),
      );
    }
    if (_loadError != null) {
      return Scaffold(
        backgroundColor: cBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: cDanger),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final screens = [
      CustomerHomeScreen(
        user: widget.user,
        tables: _tables,
        menuItems: _menuItems,
        cats: _cats,
        selectedTableId: _selectedTableId,
        onSelectTable: (id) => setState(() => _selectedTableId = id),
        onGoMenu: () => setState(() => _tab = 1),
        cart: _cart,
        onAddToCart: (id) => setState(() => _cart[id] = (_cart[id] ?? 0) + 1),
      ),
      CustomerMenuScreen(
        user: widget.user,
        menuItems: _menuItems,
        cats: _cats,
        selectedTableId: _selectedTableId,
        cart: _cart,
        onUpdateCart: (id, delta) => setState(() {
          final current = _cart[id] ?? 0;
          final next = current + delta;
          if (next <= 0) {
            _cart.remove(id);
          } else {
            _cart[id] = next;
          }
        }),
        showSelectTableHint: () =>
            _showToast(context, 'Vui lòng chọn bàn trước', success: false),
      ),
      CustomerOrdersScreen(
        user: widget.user,
        menuItems: _menuItems,
        cats: _cats,
        tables: _tables,
        orders: _customerOrders,
        selectedTableId: _selectedTableId,
        cart: _cart,
        onUpdateCart: (id, delta) => setState(() {
          final current = _cart[id] ?? 0;
          final next = current + delta;
          if (next <= 0) {
            _cart.remove(id);
          } else {
            _cart[id] = next;
          }
        }),
        onPlaceOrder: () async {
          if (_selectedTableId == null) {
            _showToast(context, 'Vui lòng chọn bàn trước', success: false);
            return;
          }
          final total = _cart.entries.fold(0, (s, e) {
            final item = _menuItems.firstWhere(
              (m) => m.id == e.key,
              orElse: () => _menuItems.first,
            );
            return s + item.price * e.value;
          });
          final items = _cart.entries
              .map((e) => {'menu_item_id': e.key, 'quantity': e.value})
              .toList();
          try {
            await ApiService.createOrder(
              widget.user.token,
              widget.user.id,
              _selectedTableId!,
              total,
              items,
            );
          } catch (e) {
            if (context.mounted) {
              _showToast(
                context,
                e.toString().replaceFirst('Exception: ', ''),
                success: false,
              );
            }
            return;
          }
          setState(() => _cart.clear());
          try {
            final orders = await ApiService.getOrders(
              widget.user.token,
              widget.user.id,
            );
            if (mounted) setState(() => _customerOrders = orders);
          } catch (_) {}
          if (!context.mounted) return;
          _showToast(context, 'Đặt món thành công!');
        },
      ),
      CustomerProfileScreen(
        user: widget.user,
        onLogout: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AuthScreen()),
          );
        },
      ),
    ];

    return Scaffold(
      backgroundColor: cBg,
      body: screens[_tab],
      bottomNavigationBar: _CustomerBottomNav(
        current: _tab,
        onTap: (t) => setState(() => _tab = t),
      ),
    );
  }
}

class _CustomerBottomNav extends StatelessWidget {
  const _CustomerBottomNav({required this.current, required this.onTap});
  final int current;
  final ValueChanged<int> onTap;
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, Icons.home, 'Trang chủ'),
      (Icons.menu_book_outlined, Icons.menu_book, 'Thực đơn'),
      (Icons.receipt_long_outlined, Icons.receipt_long, 'Đơn của tôi'),
      (Icons.person_outline, Icons.person, 'Tài khoản'),
    ];
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: cSurface,
        border: const Border(top: BorderSide(color: cLine)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final isActive = i == current;
          return GestureDetector(
            onTap: () => onTap(i),
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isActive ? items[i].$2 : items[i].$1,
                    color: isActive ? cPrimary : cMuted,
                    size: 22,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    items[i].$3,
                    style: TextStyle(
                      color: isActive ? cPrimary : cMuted,
                      fontSize: 10,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────── CUSTOMER HOME ───────────────────────────────────
class CustomerHomeScreen extends StatelessWidget {
  final AppUser user;
  final List<TableModel> tables;
  final List<MenuItemModel> menuItems;
  final List<CategoryModel> cats;
  final int? selectedTableId;
  final ValueChanged<int> onSelectTable;
  final VoidCallback onGoMenu;
  final Map<int, int> cart;
  final ValueChanged<int> onAddToCart;

  const CustomerHomeScreen({
    super.key,
    required this.user,
    required this.tables,
    required this.menuItems,
    required this.cats,
    required this.selectedTableId,
    required this.onSelectTable,
    required this.onGoMenu,
    required this.cart,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final emptyTables = tables.where((t) => t.status == 'Trống').toList();
    final featuredItems = menuItems.where((m) => m.available).take(4).toList();

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero
            // Top Bar showing restaurant name
            Container(
              width: double.infinity,
              color: cSurface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: const Row(
                children: [
                  _BrandMark(size: 34),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nhà hàng Hương Việt',
                      style: TextStyle(
                        color: cInk,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.notifications_outlined,
                    color: cInk,
                    size: 24,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: cLine),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    // Tables section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Chọn bàn của bạn',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: cInk,
                          ),
                        ),
                        _Badge(
                          '${emptyTables.length} bàn trống',
                          type: 'success',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 70,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: emptyTables.length,
                        itemBuilder: (_, i) {
                          final t = emptyTables[i];
                          final isSelected = t.id == selectedTableId;
                          return GestureDetector(
                            onTap: () => onSelectTable(t.id),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              width: 75,
                              decoration: BoxDecoration(
                                color: isSelected ? cPrimary : cSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? cPrimary : cLine,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.table_bar,
                                    color: isSelected ? Colors.white : cPrimary,
                                    size: 22,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    t.code,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : cInk,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${t.seats} chỗ',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white70
                                          : cMuted,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Featured menu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Thực đơn nổi bật',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: cInk,
                          ),
                        ),
                        GestureDetector(
                          onTap: onGoMenu,
                          child: const Text(
                            'Xem tất cả',
                            style: TextStyle(color: cPrimary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...featuredItems.map((m) {
                      final qty = cart[m.id] ?? 0;
                      final catName = _categoryName(m.categoryId, cats);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cLine),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                m.imageUrl,
                                width: 56,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 56,
                                  height: 52,
                                  color: cLine,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    catName,
                                    style: const TextStyle(
                                      color: cMuted,
                                      fontSize: 9,
                                    ),
                                  ),
                                  Text(
                                    m.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: cInk,
                                    ),
                                  ),
                                  Text(
                                    formatMoney(m.price),
                                    style: const TextStyle(
                                      color: cPrimary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => onAddToCart(m.id),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: qty > 0 ? cPrimary : cBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: qty > 0 ? Colors.white : cPrimary,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────── CUSTOMER MENU ───────────────────────────────────
class CustomerMenuScreen extends StatefulWidget {
  final AppUser user;
  final List<MenuItemModel> menuItems;
  final List<CategoryModel> cats;
  final int? selectedTableId;
  final Map<int, int> cart;
  final void Function(int id, int delta) onUpdateCart;
  final VoidCallback showSelectTableHint;

  const CustomerMenuScreen({
    super.key,
    required this.user,
    required this.menuItems,
    required this.cats,
    required this.selectedTableId,
    required this.cart,
    required this.onUpdateCart,
    required this.showSelectTableHint,
  });
  @override
  State<CustomerMenuScreen> createState() => _CustomerMenuScreenState();
}

class _CustomerMenuScreenState extends State<CustomerMenuScreen> {
  String _filter = 'Tất cả';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final chipItems = ['Tất cả', ...widget.cats.map((c) => c.name)];
    final filtered = widget.menuItems.where((m) {
      if (!m.available) return false;
      if (_search.isNotEmpty &&
          !m.name.toLowerCase().contains(_search.toLowerCase()))
        return false;
      if (_filter != 'Tất cả') {
        if (_categoryName(m.categoryId, widget.cats) != _filter) return false;
      }
      return true;
    }).toList();

    return SafeArea(
      child: Column(
        children: [
          _ScreenHeader(
            title: 'Thực đơn',
            subtitle:
                '${widget.menuItems.where((m) => m.available).length} món',
          ),
          _SearchBox(onChanged: (v) => setState(() => _search = v)),
          _ChipFilter(
            items: chipItems,
            selected: _filter,
            onTap: (v) => setState(() => _filter = v),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final m = filtered[i];
                final qty = widget.cart[m.id] ?? 0;
                final catName = _categoryName(m.categoryId, widget.cats);
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cLine),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          m.imageUrl,
                          width: 82,
                          height: 76,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              Container(width: 82, height: 76, color: cLine),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Badge(catName, type: 'info'),
                            const SizedBox(height: 4),
                            Text(
                              m.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: cInk,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatMoney(m.price),
                              style: const TextStyle(
                                color: cPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (qty == 0)
                        GestureDetector(
                          onTap: () {
                            if (widget.selectedTableId == null) {
                              widget.showSelectTableHint();
                              return;
                            }
                            setState(() => widget.onUpdateCart(m.id, 1));
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: cPrimary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            _stepBtn(
                              Icons.remove,
                              () =>
                                  setState(() => widget.onUpdateCart(m.id, -1)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Text(
                                '$qty',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            _stepBtn(
                              Icons.add,
                              () =>
                                  setState(() => widget.onUpdateCart(m.id, 1)),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: cBg,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: cLine),
        ),
        child: Icon(icon, size: 15, color: cInk),
      ),
    );
  }
}

// ─────────────── CUSTOMER ORDERS ─────────────────────────────────
class CustomerOrdersScreen extends StatelessWidget {
  final AppUser user;
  final List<MenuItemModel> menuItems;
  final List<CategoryModel> cats;
  final List<TableModel> tables;
  final List<OrderModel> orders;
  final int? selectedTableId;
  final Map<int, int> cart;
  final void Function(int id, int delta) onUpdateCart;
  final VoidCallback onPlaceOrder;

  const CustomerOrdersScreen({
    super.key,
    required this.user,
    required this.menuItems,
    required this.cats,
    required this.tables,
    required this.orders,
    required this.selectedTableId,
    required this.cart,
    required this.onUpdateCart,
    required this.onPlaceOrder,
  });

  int get _total => cart.entries.fold(0, (sum, e) {
    final item = menuItems.firstWhere(
      (m) => m.id == e.key,
      orElse: () => menuItems.first,
    );
    return sum + item.price * e.value;
  });

  @override
  Widget build(BuildContext context) {
    final selectedTable = selectedTableId != null
        ? tables.where((t) => t.id == selectedTableId).isNotEmpty
              ? tables.firstWhere((t) => t.id == selectedTableId)
              : null
        : null;

    return SafeArea(
      child: Column(
        children: [
          const _ScreenHeader(title: 'Đơn của tôi'),
          if (selectedTable != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cBlueSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.table_bar, color: cBlue, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Bàn: ${selectedTable.code} • ${selectedTable.seats} chỗ',
                    style: const TextStyle(
                      color: cBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: cart.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (orders.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'Bạn chưa có đơn hàng',
                              style: TextStyle(color: cMuted),
                            ),
                          ),
                        )
                      else ...[
                        const Text(
                          'Lịch sử đơn hàng',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: cInk,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...orders.map((order) {
                          final matchingTables = tables
                              .where((table) => table.id == order.tableId)
                              .toList();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _InvoiceCompactRow(
                              tableCode: matchingTables.isEmpty
                                  ? 'B${order.tableId.toString().padLeft(2, '0')}'
                                  : matchingTables.first.code,
                              amount: order.total,
                              time: order.createdAt.length >= 16
                                  ? order.createdAt.substring(11, 16)
                                  : '',
                              method: order.status,
                            ),
                          );
                        }),
                      ],
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final entry = cart.entries.toList()[i];
                      final item = menuItems.firstWhere(
                        (m) => m.id == entry.key,
                        orElse: () => menuItems.first,
                      );
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cLine),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.imageUrl,
                                width: 56,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 56,
                                  height: 52,
                                  color: cLine,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: cInk,
                                    ),
                                  ),
                                  Text(
                                    formatMoney(item.price * entry.value),
                                    style: const TextStyle(
                                      color: cPrimary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _CustStepBtn(
                                  icon: Icons.remove,
                                  onTap: () => onUpdateCart(entry.key, -1),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: Text(
                                    '${entry.value}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                _CustStepBtn(
                                  icon: Icons.add,
                                  onTap: () => onUpdateCart(entry.key, 1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cSurface,
                border: const Border(top: BorderSide(color: cLine)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng cộng',
                        style: TextStyle(color: cMuted, fontSize: 13),
                      ),
                      Text(
                        formatMoney(_total),
                        style: const TextStyle(
                          color: cInk,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _PrimaryButton(label: 'Đặt món', onTap: onPlaceOrder),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CustStepBtn extends StatelessWidget {
  const _CustStepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: cBg,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: cLine),
        ),
        child: Icon(icon, size: 15, color: cInk),
      ),
    );
  }
}

// ─────────────── CUSTOMER PROFILE ────────────────────────────────
class CustomerProfileScreen extends StatelessWidget {
  final AppUser user;
  final VoidCallback onLogout;
  const CustomerProfileScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });
  @override
  Widget build(BuildContext context) {
    final initial = user.username.isNotEmpty
        ? user.username[0].toUpperCase()
        : 'K';
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const _ScreenHeader(title: 'Tài khoản'),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: cPrimarySoft,
              child: Text(
                initial,
                style: const TextStyle(
                  color: cPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user.username,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cInk,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Khách hàng',
              style: TextStyle(color: cMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cLine),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.receipt_long_outlined,
                      color: cPrimary,
                    ),
                    title: const Text(
                      'Lịch sử đặt món',
                      style: TextStyle(color: cInk, fontSize: 13),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: cMuted,
                    ),
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: cLine),
                  ListTile(
                    leading: const Icon(Icons.help_outline, color: cPrimary),
                    title: const Text(
                      'Trợ giúp',
                      style: TextStyle(color: cInk, fontSize: 13),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: cMuted,
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout, color: cDanger, size: 18),
                  label: const Text(
                    'Đăng xuất',
                    style: TextStyle(
                      color: cDanger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: cDangerSoft),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
