# BẢNG TEST CASE — APP QUẢN LÝ NHÀ HÀNG "HƯƠNG VIỆT"

> **Dự án:** C:\LTDD (Flutter Web + Dart Backend + SQL Server)
> **URL test:** `http://localhost:5000` (hoặc `http://127.0.0.1:5000`)
> **API:** `http://127.0.0.1:8080`
> **Ngày tạo:** 07/11/2026
> **Người tạo:** Huynh Dang
> **Ngày test:** 08/11/2026

---

## I. THÔNG TIN MÔI TRƯỜNG TEST

| Hạng mục | Giá trị |
|---|---|
| URL Web App | `http://localhost:5000` |
| Backend API | `http://127.0.0.1:8080` |
| Database | SQL Server `MSSQL$MSSQLSERVER01`, DB `QLNH`, port 64517 |
| Tài khoản Quản lý | `admin` / `admin123` |
| Tài khoản Khách | `huynhhoangdang` / `123456` |
| Trình duyệt khuyến nghị | Chrome / Edge (desktop) |

### Dữ liệu seed có sẵn trong DB

- **Users:** admin (Quản lý), huynhhoangdang (Khách), test_user (Khách)
- **Categories (5):** Món khai vị, Món chính, Món phụ, Đồ uống, Tráng miệng
- **Menu items (9):** Gỏi cuốn tôm thịt (45k), Chả giò hải sản (55k), Cơm chiên hải sản (65k), Phở bò đặc biệt (55k), Bò lúc lắc (95k), Rau muống xào tỏi (45k), Cà phê sữa đá (25k), Trà đào cam sả (30k), Bánh flan (25k)
- **Tables (10):** Bàn 1–10, chỗ ngồi 2–8, status "Trống"

---

## II. TEST CASE

### MODULE 1: XÁC THỰC (AUTH)

| ID | Scenario | Pre-condition | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-AUTH-001 | Đăng nhập đúng (Quản lý) | Không cần | 1. Mở app<br>2. Tab "Đăng nhập"<br>3. Nhập `admin` / `admin123`<br>4. Bấm "Đăng nhập" | Hiển thị màn hình chính với quyền Quản lý (thấy tab Báo cáo, Nhân viên) | P0 |
| TC-AUTH-002 | Đăng nhập đúng (Khách) | Không cần | 1. Mở app<br>2. Tab "Đăng nhập"<br>3. Nhập `huynhhoangdang` / `123456`<br>4. Bấm "Đăng nhập" | Hiển thị màn hình chính quyền Khách (chọn bàn, gọi món) | P0 |
| TC-AUTH-003 | Đăng nhập sai mật khẩu | Không cần | 1. Nhập `admin` / `sai123`<br>2. Bấm "Đăng nhập" | Hiện thông báo lỗi "Sai thông tin đăng nhập", không vào được (403) | P0 |
| TC-AUTH-004 | Đăng nhập username không tồn tại | Không cần | 1. Nhập `nouser` / `123`<br>2. Bấm "Đăng nhập" | Hiện thông báo lỗi, không crash (403) | P1 |
| TC-AUTH-005 | Đăng ký user mới | Không cần | 1. Tab "Đăng ký"<br>2. Nhập username `khachmoi`<br>3. Nhập mật khẩu `abc123` + xác nhận<br>4. Bấm "Đăng ký" | Thông báo "Đăng ký thành công" (200) | P0 |
| TC-AUTH-006 | Đăng ký username trùng | User `admin` đã tồn tại | 1. Tab "Đăng ký"<br>2. Nhập `admin` / `xxx`<br>3. Bấm "Đăng ký" | Thông báo "Username đã tồn tại" (409) | P1 |
| TC-AUTH-007 | Đăng ký thiếu trường | Không cần | 1. Tab "Đăng ký"<br>2. Bỏ trống username<br>3. Bấm "Đăng ký" | Validate: "Vui lòng nhập đủ thông tin" (400) | P2 |
| TC-AUTH-008 | Đăng xuất | Đã đăng nhập | 1. Bấm nút "Đăng xuất" (hoặc icon) | Quay về màn hình Login, token bị xóa | P1 |
| TC-AUTH-009 | Truy cập khi chưa đăng nhập | App vừa mở, chưa login | 1. Mở app | Hiện màn hình Login (không cho vào trang chính) | P1 |

---

### MODULE 2: THỰC ĐƠN (MENU)

| ID | Scenario | Pre-condition | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-MENU-001 | Xem danh sách danh mục | Đăng nhập (bất kỳ role) | 1. Vào tab "Thực đơn"<br>2. Chọn danh mục | Hiện 5 danh mục: Món khai vị, Món chính, Món phụ, Đồ uống, Tráng miệng | P0 |
| TC-MENU-002 | Xem món trong danh mục "Món chính" | Đăng nhập | 1. Chọn danh mục "Món chính"<br>2. Xem danh sách | Hiện 3 món: Cơm chiên hải sản (65k), Phở bò đặc biệt (55k), Bò lúc lắc (95k) | P0 |
| TC-MENU-003 | Xem chi tiết món | Đăng nhập | 1. Bấm vào 1 món | Hiện tên, giá, available, ảnh (nếu có) | P1 |
| TC-MENU-004 | Tìm kiếm / lọc món (UI) | Đăng nhập | 1. Chọn filter "Tất cả" / danh mục | UI lọc danh sách món theo danh mục đã chọn | P2 |
| TC-MENU-005 | Món hết / không available | Sửa DB: `UPDATE menu_items SET available=0 WHERE id=9` | 1. Vào Thực đơn<br>2. Xem "Bánh flan" (id=9) | Món bị ẩn hoặc hiện trạng thái "Hết" (available=false) | P2 |

---

### MODULE 3: BÀN (TABLES)

| ID | Scenario | Pre-condition | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-TBL-001 | Xem danh sách bàn | Đăng nhập | 1. Vào tab "Bàn" | Hiện 10 bàn (số 1–10), mỗi bàn có số chỗ, status "Trống" | P0 |
| TC-TBL-002 | Chọn bàn → gọi món | Đăng nhập | 1. Bấm vào Bàn 3<br>2. Chọn món | Screen chuyển sang gọi món cho bàn 3 | P0 |
| TC-TBL-003 | Trạng thái bàn sau khi đặt món | Bàn đang "Trống" | 1. Chọn bàn 5<br>2. Đặt 1 món<br>3. Xem lại danh sách bàn | Bàn 5 chuyển status "Đang phục vụ" | P1 |

---

### MODULE 4: ĐƠN HÀNG (ORDERS)

| ID | Scenario | Pre-condition | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-ORD-001 | Tạo đơn mới (1 món) | Đăng nhập, chọn bàn | 1. Chọn bàn 6<br>2. Chọn "Cà phê sữa đá" x2<br>3. Bấm "Đặt món" | Đơn tạo, total = 50.000đ, status "pending" | P0 |
| TC-ORD-002 | Tạo đơn nhiều món | Đăng nhập | 1. Chọn bàn 7<br>2. Thêm: Phở bò (x1) + Bánh flan (x2)<br>3. Đặt | Total = 105.000đ. DB `order_items` có 2 dòng | P0 |
| TC-ORD-003 | Xem danh sách đơn | Đã có đơn | 1. Vào tab "Đơn hàng" (Quản lý) | Hiện list đơn: số đơn, bàn, tổng tiền, trạng thái, thời gian | P0 |
| TC-ORD-004 | Xem chi tiết đơn | Đã có đơn | 1. Bấm vào 1 đơn | Hiện danh sách món + số lượng + giá đơn vị + tổng | P1 |
| TC-ORD-005 | Đổi trạng thái đơn | Đơn "pending" | 1. Vào đơn<br>2. Đổi sang "cooking" | Trạng thái cập nhật (200) | P0 |
| TC-ORD-006 | Đổi trạng thái → paid | Đơn "cooking" | 1. Đổi sang "paid" | Đơn tính vào doanh thu | P1 |
| TC-ORD-007 | Hủy đơn | Đơn "pending" | 1. Bấm "Hủy" | Status → "cancelled" | P2 |
| TC-ORD-008 | Khách tự đặt đơn | Đăng nhập khách | 1. Chọn bàn → gọi món → đặt | Khách tạo đơn, không thấy tab "Báo cáo"/"Nhân viên" | P1 |
| TC-ORD-009 | Đặt món số lượng = 0 | Đăng nhập | 1. Thử đặt số lượng 0 | Validate chặn (DB CHECK `quantity > 0`, 500) | P2 |

---

### MODULE 5: BÁO CÁO (REPORTS) — CHỈ QUẢN LÝ

| ID | Scenario | Pre-condition | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-RPT-001 | Xem báo cáo doanh thu ngày | Có đơn "paid" | 1. Đăng nhập `admin`<br>2. Vào tab "Báo cáo" | Hiện tổng doanh thu, số đơn (200) | P0 |
| TC-RPT-002 | Báo cáo khi chưa có đơn paid | Xoá các đơn paid | 1. Vào tab Báo cáo | Hiện 0 hoặc "Chưa có dữ liệu" (không crash) | P1 |
| TC-RPT-003 | Khách bị chặn khỏi báo cáo | Đăng nhập khách | 1. Gõ API `/reports/daily` với token khách | **403 Forbidden** (đã fix bảo mật) | P0 |

---

### MODULE 6: QUẢN LÝ NHÂN VIÊN (USERS) — CHỈ QUẢN LÝ

| ID | Scenario | Pre-condition | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-USR-001 | Xem danh sách user | Đăng nhập admin | 1. Vào tab "Nhân viên" | Hiện list user với role, status (200) | P0 |
| TC-USR-002 | Thêm user mới | Đăng nhập admin | 1. Bấm "Thêm"<br>2. Nhập username, password, role "Phục vụ"<br>3. Lưu | User tạo (200) | P1 |
| TC-USR-003 | Đổi status user (khóa TK) | Có user | 1. Chọn user<br>2. Đổi status → "locked" | User không đăng nhập được | P1 |
| TC-USR-004 | Khách bị chặn khỏi /users/ | Đăng nhập khách | 1. Gọi API `/users/` với token khách | **403 Forbidden** | P0 |

---

### MODULE 7: UI / TRẢI NGHIỆM

| ID | Scenario | Steps | Expected Result | Priority |
|---|---|---|---|---|
| TC-UI-001 | Tiếng Việt hiển thị đúng | Mở app, xem toàn bộ | Không có ký tự lỗi (ô vuông, mojibake) | P0 |
| TC-UI-002 | Responsive trên mobile (375px) | F12 → Device → 375×667 | Không tràn ngang, chữ không cắt, nút bấm được | P1 |
| TC-UI-003 | Loading state khi gọi API | Tắt backend → mở app → bật lại | Hiện spinner / "Đang tải...", không crash | P2 |
| TC-UI-004 | Offline / không network | Tắt WiFi → refresh | Hiện thông báo "Không kết nối được" | P2 |
| TC-UI-005 | Nút back / navigation | Điều hướng giữa các tab | Không "mắc kẹt", back hoạt động đúng | P2 |

---

## III. CÁCH CHẠY TEST NHANH (API)

Mở PowerShell, chạy từng lệnh:

```powershell
# 1) Đăng nhập lấy token
$token = (Invoke-RestMethod -Uri "http://127.0.0.1:8080/auth/login" -Method POST -Body '{"username":"admin","password":"admin123"}' -ContentType "application/json").token

# 2) Xem danh mục
Invoke-RestMethod -Uri "http://127.0.0.1:8080/menu/categories"

# 3) Xem món
Invoke-RestMethod -Uri "http://127.0.0.1:8080/menu/items"

# 4) Xem bàn
Invoke-RestMethod -Uri "http://127.0.0.1:8080/tables/"

# 5) Tạo đơn (bàn 1, món id=4 x2)
$headers = @{ Authorization = "Bearer $token" }
Invoke-RestMethod -Uri "http://127.0.0.1:8080/orders/" -Method POST -Body '{"user_id":1,"table_id":1,"items":[{"menu_item_id":4,"quantity":2}]}' -Headers $headers -ContentType "application/json"

# 6) Xem đơn
Invoke-RestMethod -Uri "http://127.0.0.1:8080/orders/" -Headers $headers

# 7) Báo cáo (chỉ admin - khách bị 403)
Invoke-RestMethod -Uri "http://127.0.0.1:8080/reports/daily" -Headers $headers

# 8) Users (chỉ admin)
Invoke-RestMethod -Uri "http://127.0.0.1:8080/users/" -Headers $headers
```

---

## IV. BẢNG KẾT QUẢ THỰC TẾ (đã chạy tự động API, 08/11/2026)

> Chạy bằng script: `C:\LTDD\.agnes\work\run_full_test.ps1`
> Các mục **PASS/FAIL** = kết quả API thực tế. **THỦ CÔNG** = cần kiểm tra trực tiếp trên trình duyệt (app không tự động).

| ID | Kết quả | Ghi chú / Chi tiết |
|---|---|---|
| TC-AUTH-001 | ✅ PASS | HTTP 200 + JWT, role="Quản lý" |
| TC-AUTH-002 | ✅ PASS | HTTP 200, role="Khách hàng" |
| TC-AUTH-003 | ✅ PASS | HTTP 403 (invalid credentials) |
| TC-AUTH-004 | ✅ PASS | HTTP 403 (user không tồn tại) |
| TC-AUTH-005 | ✅ PASS | HTTP 200 (tạo user mới) |
| TC-AUTH-006 | ✅ PASS | HTTP 409 (trùng username) |
| TC-AUTH-007 | ✅ PASS | HTTP 400 (thiếu trường) |
| TC-AUTH-008 | ⏳ THỦ CÔNG | Thao tác UI (đăng xuất) - chưa kiểm tra trên app |
| TC-AUTH-009 | ⏳ THỦ CÔNG | Gate Login - chưa kiểm tra UI |
| TC-MENU-001 | ✅ PASS | API trả về đúng 5 danh mục |
| TC-MENU-002 | ✅ PASS | Danh mục "Món chính" có đúng 3 món |
| TC-MENU-003 | ✅ PASS | Đủ name / price / available |
| TC-MENU-004 | ⏳ THỦ CÔNG | Lọc theo danh mục ở UI - chưa kiểm tra |
| TC-MENU-005 | ✅ PASS | available=false phản ánh đúng (field boolean) |
| TC-TBL-001 | ✅ PASS | API trả về đúng 10 bàn (số 1–10) |
| TC-TBL-002 | ⏳ THỦ CÔNG | Flow UI chọn bàn - đã bao phủ ở TC-ORD-001 |
| TC-TBL-003 | ✅ PASS | Bàn đổi sang "Đang phục vụ" sau khi đặt món |
| TC-ORD-001 | ✅ PASS | total=50.000đ, status="pending" |
| TC-ORD-002 | ✅ PASS | total=105.000đ (nhiều món) |
| TC-ORD-003 | ✅ PASS | Có đơn trong list |
| TC-ORD-004 | ✅ PASS | Chi tiết đơn có items |
| TC-ORD-005 | ✅ PASS | Đổi status cooking (HTTP 200) |
| TC-ORD-006 | ✅ PASS | Đổi status paid (HTTP 200) |
| TC-ORD-007 | ✅ PASS | Hủy đơn cancelled (HTTP 200) |
| TC-ORD-008 | ✅ PASS | Khách tạo đơn (HTTP 200) |
| TC-ORD-009 | ✅ PASS | SL=0 bị chặn bởi DB CHECK constraint (500) |
| TC-RPT-001 | ✅ PASS | HTTP 200 (admin) |
| TC-RPT-002 | ⏳ THỦ CÔNG | Báo cáo khi DB trống - chưa kiểm tra UI |
| TC-RPT-003 | ✅ **ĐÃ FIX** | Trước: khách đọc được báo cáo (200) → Sau fix: khách bị chặn **403** |
| TC-USR-001 | ✅ PASS | Danh sách user (admin) |
| TC-USR-002 | ✅ PASS | Thêm user mới (HTTP 200) |
| TC-USR-003 | ⏳ THỦ CÔNG | Khóa TK - chưa kiểm tra UI |
| TC-USR-004 | ✅ PASS | Khách bị chặn /users/ (HTTP 403) |
| TC-UI-001 | ⏳ THỦ CÔNG | Kiểm tra tiếng Việt trên trình duyệt |
| TC-UI-002 | ⏳ THỦ CÔNG | F12 device 375px |
| TC-UI-003 | ⏳ THỦ CÔNG | Tắt backend → loading state |
| TC-UI-004 | ⏳ THỦ CÔNG | Tắt net → offline |
| TC-UI-005 | ⏳ THỦ CÔNG | Navigation giữa các tab |

### Tổng kết

| Chỉ số | Giá trị |
|---|---|
| **Tổng test cases** | 37 |
| **PASS (API tự động)** | **27** |
| **FAIL** | **0** |
| **THỦ CÔNG (UI, chưa chạy)** | 10 |
| **Lỗi bảo mật phát hiện & fix** | 1 (TC-RPT-003) |

---

## V. BUG PHÁT HIỆN & ĐÃ FIX TRONG LẦN TEST NÀY

| # | Bug | Mức độ | Trạng thái |
|---|---|---|---|
| 1 | `/reports/*` cho phép **khách hàng đọc báo cáo doanh thu** (200 thay vì 403) - lỗ hổng phân quyền | 🔴 Cao | ✅ **Đã fix** (thêm `_authorizeManager` vào `report.dart`) |

### Chi tiết Bug #1

- **Phát hiện:** TC-RPT-003 - gọi `/reports/daily` với token **Khách hàng** → HTTP **200** (dữ liệu doanh thu bị lộ)
- **Gốc rễ:** `backend/lib/routes/report.dart` không có kiểm tra JWT/role
- **Fix:** Thêm hàm `_authorizeManager` (giống pattern trong `user.dart`) vào `report.dart`, chặn 403 khi role ≠ "Quản lý"
- **Kiểm tra sau fix:**
  - Khách gọi `/reports/daily` → **403** ✅
  - Khách gọi `/reports/monthly` → **403** ✅
  - Admin gọi `/reports/daily` → **200** ✅

---

## VI. LƯU Ý KHI TEST

1. **Trước khi test:** đảm bảo 3 service đang chạy (SQL 64517, backend 8080, web 5000). Chạy `powershell -NoProfile -File C:\LTDD\.agnes\work\run_web_release.ps1` nếu cần.
2. **Reset data:** nếu muốn làm sạch đơn hàng để test lại:
   ```sql
   DELETE FROM order_items;
   DELETE FROM orders;
   ```
3. **Kiểm tra DB trực tiếp:**
   ```sql
   SELECT * FROM QLNH.dbo.orders;
   SELECT * FROM QLNH.dbo.order_items;
   SELECT COUNT(*) FROM QLNH.dbo.users;
   ```
4. **Priority:** P0 = phải pass trước, P1 = nên pass, P2 = nice-to-have.
5. **Để chạy lại suite test:** `powershell -NoProfile -File C:\LTDD\.agnes\work\run_full_test.ps1`
