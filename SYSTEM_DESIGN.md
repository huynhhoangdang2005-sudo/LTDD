# TÀI LIỆU THIẾT KẾ KIẾN TRÚC VÀ DỮ LIỆU DỰ ÁN (PROJECT ARCHITECTURE & DATA DESIGN)
**Dự án:** Ứng dụng Quản lý Nhà hàng & Gọi món (Restaurant Management App)  
**Công nghệ:** Flutter (Frontend) + Dart Shelf (Backend API) + MySQL (Database)

---

## 1. SƠ ĐỒ HOẠT ĐỘNG (ACTIVITY DIAGRAM)

Mô tả luồng nghiệp vụ tổng thể từ khi người dùng đăng nhập hệ thống, phân quyền Khách hàng đặt món, lưu vào Database và Quản lý/Admin xử lý đơn hàng, chế biến tại bếp và thanh toán.

```mermaid
flowchart TD
    Start([Bắt đầu]) --> Login[Đăng nhập / Đăng ký hệ thống]

    Login --> CheckRole{Phân quyền tài khoản?}

    %% LUỒNG KHÁCH HÀNG
    subgraph CUSTOMER_FLOW ["Luồng Khách hàng"]
        CheckRole -->|Khách hàng thường| ViewTables[Xem danh sách bàn ăn]
        ViewTables --> SelectTable[Chọn bàn ăn còn trống]
        SelectTable --> ViewMenu[Duyệt danh mục & thực đơn món ăn]
        ViewMenu --> AddToCart[Thêm món & số lượng vào Giỏ hàng]
        AddToCart --> ConfirmCart{Xác nhận đặt món?}
        ConfirmCart -->|Chưa/Đổi món| ViewMenu
        ConfirmCart -->|Đồng ý| SendOrder[Gửi yêu cầu đặt món lên Server]
    end

    %% TẦNG HỆ THỐNG / BACKEND & DATABASE
    subgraph SYSTEM_BACKEND ["Hệ thống / Backend & Database"]
        SendOrder --> SaveDB[(Lưu vào bảng 'orders' & 'order_items')]
        SaveDB --> UpdateTableStatus[Cập nhật trạng thái bàn: 'Đang phục vụ']
        UpdateTableStatus --> NotifyAdmin[Thông báo đơn mới tới Admin]
    end

    %% LUỒNG ADMIN / QUẢN LÝ
    subgraph ADMIN_FLOW ["Luồng Admin / Quản lý nhà hàng"]
        CheckRole -->|Tài khoản 'admin'| AdminDash[Truy cập Dashboard Quản lý]
        NotifyAdmin -.-> AdminDash
        
        AdminDash --> ChooseAction{Chọn nghiệp vụ}
        
        ChooseAction -->|Bếp| ViewKitchen[Màn hình Bếp: Nhận vé món và chế biến]
        ViewKitchen --> CookingDone[Cập nhật trạng thái món hoàn tất]

        ChooseAction -->|Bàn ăn & Hóa đơn| ViewInvoices[Xem danh sách Hóa đơn từ Database]
        CookingDone --> ViewInvoices

        ViewInvoices --> RequestPayment[Khách yêu cầu thanh toán]
        RequestPayment --> SelectMethod[Chọn hình thức: Tiền mặt / Chuyển khoản / QR]
        SelectMethod --> ConfirmPay{Xác nhận thanh toán?}
        
        ConfirmPay -->|Hủy| ViewInvoices
        ConfirmPay -->|Xác nhận| ProcessPayment[Ghi nhận doanh thu & Xuất biên lai]
        ProcessPayment --> ClearTable[Chuyển trạng thái bàn về 'Trống']
        ClearTable --> UpdateStats[Cập nhật Báo cáo Doanh thu ngày]
    end

    UpdateStats --> End([Kết thúc phiên làm việc])
```

---

## 2. SƠ ĐỒ THỰC THỂ QUAN HỆ (ENTITY-RELATIONSHIP DIAGRAM - ERD)

Mô hình hóa cơ sở dữ liệu MySQL chuẩn 6 bảng hiện hành của dự án (`QLNH`).

```mermaid
erDiagram
    users ||--o{ orders : "places (tạo đơn)"
    tables ||--o{ orders : "serves (phục vụ tại)"
    categories ||--o{ menu_items : "contains (chứa)"
    orders ||--|{ order_items : "includes (chi tiết)"
    menu_items ||--o{ order_items : "ordered_in (được gọi trong)"

    users {
        int id PK "Khóa chính, tự tăng"
        varchar username "Tên đăng nhập (Unique)"
        varchar password "Mật khẩu"
    }

    categories {
        int id PK "Khóa chính, tự tăng"
        varchar name "Tên danh mục món"
    }

    menu_items {
        int id PK "Khóa chính, tự tăng"
        varchar name "Tên món ăn"
        decimal price "Giá món"
        int category_id FK "Tham chiếu categories(id)"
    }

    tables {
        int id PK "Khóa chính, tự tăng"
        int number "Số hiệu bàn (Unique)"
        int seats "Số chỗ ngồi"
    }

    orders {
        int id PK "Khóa chính, tự tăng"
        int user_id FK "Tham chiếu users(id)"
        int table_id FK "Tham chiếu tables(id)"
        decimal total "Tổng tiền hóa đơn"
        varchar status "Trạng thái (pending, paid...)"
        timestamp created_at "Thời gian tạo đơn"
    }

    order_items {
        int id PK "Khóa chính, tự tăng"
        int order_id FK "Tham chiếu orders(id)"
        int menu_item_id FK "Tham chiếu menu_items(id)"
        int quantity "Số lượng món đặt"
    }
```

---

## 3. SƠ ĐỒ LỚP (CLASS DIAGRAM)

Mô hình hóa cấu trúc hướng đối tượng trong Flutter bao gồm Model, Service và UI Shells.

```mermaid
classDiagram
    %% Entity / Data Models
    class AppUser {
        +int id
        +String username
        +String token
        +bool isAdmin
    }

    class CategoryModel {
        +int id
        +String name
        +fromJson(Map) CategoryModel
    }

    class MenuItemModel {
        +int id
        +String name
        +int price
        +int categoryId
        +String imageUrl
        +bool available
        +fromJson(Map) MenuItemModel
    }

    class TableModel {
        +int id
        +int number
        +int seats
        +String status
        +String code
        +fromJson(Map) TableModel
    }

    class OrderModel {
        +int id
        +int userId
        +int tableId
        +int total
        +String status
        +String createdAt
        +fromJson(Map) OrderModel
    }

    class OrderItemModel {
        +int id
        +int orderId
        +int menuItemId
        +int quantity
    }

    %% Service Layer
    class ApiService {
        +String baseUrl$
        +login(String username, String password)$ Future~AppUser~
        +register(String username, String password)$ Future~AppUser~
        +getCategories(String token)$ Future~List~CategoryModel~~
        +getMenuItems(String token)$ Future~List~MenuItemModel~~
        +getTables(String token)$ Future~List~TableModel~~
        +getOrders(String token, int userId)$ Future~List~OrderModel~~
        +getAllOrders(String token)$ Future~List~OrderModel~~
        +getOrderDetails(String token, int orderId)$ Future~Map~
        +createOrder(String token, int userId, int tableId, int total, List items)$ Future~void~
    }

    %% UI Shells
    class AuthScreen {
        -bool _isLogin
        -TextEditingController _userCtrl
        -TextEditingController _passCtrl
        -_submit() void
    }

    class AdminShell {
        +AppUser user
        -int _tab
        -String _screen
        -List~TableModel~ _tables
        -List~MenuItemModel~ _menu
        -List~CategoryModel~ _cats
        -List~OrderModel~ _dbOrders
        -_loadData() Future~void~
        -_navigate(String screen, int tableId) void
        -_completePayment() void
    }

    class CustomerShell {
        +AppUser user
        -int _tab
        -List~CategoryModel~ _cats
        -List~MenuItemModel~ _menuItems
        -List~TableModel~ _tables
        -int _selectedTableId
        -Map~int, int~ _cart
        -_loadData() Future~void~
    }

    %% Relationships
    CategoryModel "1" <-- "*" MenuItemModel : thuộc về
    AppUser "1" <-- "*" OrderModel : tạo đơn
    TableModel "1" <-- "*" OrderModel : gán cho bàn
    OrderModel "1" *-- "1..*" OrderItemModel : chi tiết
    MenuItemModel "1" <-- "*" OrderItemModel : tham chiếu món

    AuthScreen ..> ApiService : xác thực
    AuthScreen ..> AdminShell : phân quyền Admin
    AuthScreen ..> CustomerShell : phân quyền Khách

    AdminShell ..> ApiService : đồng bộ dữ liệu
    CustomerShell ..> ApiService : đồng bộ & gửi đơn

    AdminShell o-- TableModel
    AdminShell o-- MenuItemModel
    AdminShell o-- OrderModel
    CustomerShell o-- MenuItemModel
    CustomerShell o-- TableModel
```

