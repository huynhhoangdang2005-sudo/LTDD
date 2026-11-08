-- ============================================================================
-- DỰ ÁN QUẢN LÝ NHÀ HÀNG — Schema SQL Server (6 bảng theo thiết kế)
-- File: C:\LTDD\RestaurantDB.sql
-- Cách chạy: SSMS: mở file, chọn instance MSSQL$MSSQLSERVER01, F5
--            hoặc: sqlcmd -S "localhost" -E -i "C:\LTDD\RestaurantDB.sql"
-- File idempotent: có thể chạy lại nhiều lần mà không gây lỗi.
-- ============================================================================

USE master;
GO

-- ----------------------------------------------------------------------------
-- 1) TẠO DATABASE
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'QLNH')
BEGIN
    CREATE DATABASE [QLNH];
END
GO

USE [QLNH];
GO

-- ============================================================================
-- BẢNG 1: [users] — Quản lý tài khoản (Admin, Khách hàng)
-- Cột chính: id, username, password
-- ============================================================================
IF OBJECT_ID(N'dbo.[users]', N'U') IS NULL
BEGIN
    CREATE TABLE [users]
    (
        [id]         INT           IDENTITY(1,1) NOT NULL,
        [username]   NVARCHAR(50)  NOT NULL,
        [password]   NVARCHAR(255) NOT NULL,
        [full_name]  NVARCHAR(100) NOT NULL DEFAULT N'',
        [role]       NVARCHAR(40)  NOT NULL DEFAULT N'Khách hàng',
        [status]     NVARCHAR(20)  NOT NULL DEFAULT N'active',
        [phone]      NVARCHAR(30)  NOT NULL DEFAULT N'',
        [created_at] DATETIME2     NOT NULL DEFAULT SYSDATETIME(),

        CONSTRAINT [PK_users]          PRIMARY KEY ([id]),
        CONSTRAINT [UQ_users_username] UNIQUE ([username]),
        CONSTRAINT [CK_users_status]   CHECK ([status] IN (N'active', N'locked', N'deleted'))
    );
END
GO

-- ============================================================================
-- BẢNG 2: [categories] — Danh mục món ăn (Món chính, Khai vị, Đồ uống...)
-- Cột chính: id, name
-- ============================================================================
IF OBJECT_ID(N'dbo.[categories]', N'U') IS NULL
BEGIN
    CREATE TABLE [categories]
    (
        [id]   INT           IDENTITY(1,1) NOT NULL,
        [name] NVARCHAR(100) NOT NULL,

        CONSTRAINT [PK_categories]      PRIMARY KEY ([id]),
        CONSTRAINT [UQ_categories_name] UNIQUE ([name])
    );
END
GO

-- ============================================================================
-- BẢNG 3: [menu_items] — Danh sách món ăn trong thực đơn
-- Cột chính: id, name, price, category_id
-- ============================================================================
IF OBJECT_ID(N'dbo.[menu_items]', N'U') IS NULL
BEGIN
    CREATE TABLE [menu_items]
    (
        [id]           INT           IDENTITY(1,1) NOT NULL,
        [name]         NVARCHAR(100) NOT NULL,
        [price]        DECIMAL(10,2) NOT NULL,
        [category_id]  INT           NULL,
        [image_url]    NVARCHAR(500) NOT NULL DEFAULT N'',
        [available]    BIT           NOT NULL DEFAULT 1,
        [created_at]   DATETIME2     NOT NULL DEFAULT SYSDATETIME(),

        CONSTRAINT [PK_menu_items]      PRIMARY KEY ([id]),
        CONSTRAINT [FK_menuitems_cat]   FOREIGN KEY ([category_id])
            REFERENCES [categories]([id]) ON DELETE SET NULL,
        CONSTRAINT [CK_menuitems_price] CHECK ([price] >= 0)
    );
END
GO

-- ============================================================================
-- BẢNG 4: [tables] — Quản lý số bàn & số chỗ ngồi trong nhà hàng
-- Cột chính: id, number, seats
-- Ghi chú: "tables" là reserved word của SQL Server -> phải viết [tables]
-- ============================================================================
IF OBJECT_ID(N'dbo.[tables]', N'U') IS NULL
BEGIN
    CREATE TABLE [tables]
    (
        [id]     INT           IDENTITY(1,1) NOT NULL,
        [number] INT           NOT NULL,
        [seats]  INT           NOT NULL DEFAULT 4,
        [status] NVARCHAR(30)  NOT NULL DEFAULT N'Trống',

        CONSTRAINT [PK_tables]         PRIMARY KEY ([id]),
        CONSTRAINT [UQ_tables_number]  UNIQUE ([number]),
        CONSTRAINT [CK_tables_seats]   CHECK ([seats] > 0),
        CONSTRAINT [CK_tables_status]  CHECK ([status] IN
            (N'Trống', N'Đang phục vụ', N'Đã đặt', N'Chờ thanh toán'))
    );
END
GO

-- ============================================================================
-- BẢNG 5: [orders] — Đơn đặt món của khách hàng
-- Cột chính: id, user_id, table_id, total, status, created_at
-- ============================================================================
IF OBJECT_ID(N'dbo.[orders]', N'U') IS NULL
BEGIN
    CREATE TABLE [orders]
    (
        [id]         INT           IDENTITY(1,1) NOT NULL,
        [user_id]    INT          NULL,
        [table_id]   INT          NULL,
        [total]      DECIMAL(10,2) NOT NULL DEFAULT 0,
        [status]     NVARCHAR(20) NOT NULL DEFAULT N'pending',
        [created_at] DATETIME2    NOT NULL DEFAULT SYSDATETIME(),

        CONSTRAINT [PK_orders]        PRIMARY KEY ([id]),
        CONSTRAINT [FK_orders_user]   FOREIGN KEY ([user_id])
            REFERENCES [users]([id]) ON DELETE SET NULL,
        CONSTRAINT [FK_orders_table]  FOREIGN KEY ([table_id])
            REFERENCES [tables]([id]) ON DELETE SET NULL,
        CONSTRAINT [CK_orders_total]  CHECK ([total] >= 0),
        CONSTRAINT [CK_orders_status] CHECK ([status] IN
            (N'pending', N'cooking', N'waiting_payment', N'paid', N'cancelled'))
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_orders_created')
    CREATE INDEX [IX_orders_created] ON [orders]([created_at] DESC);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_orders_table_status')
    CREATE INDEX [IX_orders_table_status] ON [orders]([table_id], [status]);
GO

-- ============================================================================
-- BẢNG 6: [order_items] — Chi tiết các món & số lượng trong từng đơn
-- Cột chính: id, order_id, menu_item_id, quantity
-- ============================================================================
IF OBJECT_ID(N'dbo.[order_items]', N'U') IS NULL
BEGIN
    CREATE TABLE [order_items]
    (
        [id]             INT           IDENTITY(1,1) NOT NULL,
        [order_id]       INT           NOT NULL,
        [menu_item_id]   INT           NOT NULL,
        [quantity]       INT           NOT NULL,

        CONSTRAINT [PK_order_items]       PRIMARY KEY ([id]),
        CONSTRAINT [FK_orderitems_order]  FOREIGN KEY ([order_id])
            REFERENCES [orders]([id]) ON DELETE CASCADE,
        CONSTRAINT [FK_orderitems_menu]   FOREIGN KEY ([menu_item_id])
            REFERENCES [menu_items]([id]),
        CONSTRAINT [CK_orderitems_qty]    CHECK ([quantity] > 0)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_orderitems_order')
    CREATE INDEX [IX_orderitems_order] ON [order_items]([order_id]);
GO

-- ============================================================================
-- DỮ LIỆU MẪU (chỉ insert lần đầu, an toàn chạy lại)
-- ============================================================================
IF NOT EXISTS (SELECT 1 FROM [users] WHERE [username] = N'admin')
BEGIN
    INSERT INTO [users] ([username], [password], [full_name], [role]) VALUES
        (N'admin', N'admin123', N'Quản trị viên', N'Quản lý');
END
GO

IF NOT EXISTS (SELECT 1 FROM [categories])
BEGIN
    INSERT INTO [categories] ([name]) VALUES
        (N'Món khai vị'),
        (N'Món chính'),
        (N'Món phụ'),
        (N'Đồ uống'),
        (N'Tráng miệng');
END
GO

IF NOT EXISTS (SELECT 1 FROM [menu_items])
BEGIN
    INSERT INTO [menu_items] ([name], [price], [category_id]) VALUES
        (N'Gỏi cuốn tôm thịt',    45000, 1),
        (N'Chả giò hải sản',      55000, 1),
        (N'Cơm chiên hải sản',    65000, 2),
        (N'Phở bò đặc biệt',      55000, 2),
        (N'Bò lúc lắc',           95000, 2),
        (N'Rau muống xào tỏi',    45000, 3),
        (N'Cà phê sữa đá',        25000, 4),
        (N'Trà đào cam sả',       30000, 4),
        (N'Bánh flan',            25000, 5);
END
GO

IF NOT EXISTS (SELECT 1 FROM [tables])
BEGIN
    INSERT INTO [tables] ([number], [seats]) VALUES
        (1, 4), (2, 2), (3, 6), (4, 4), (5, 4),
        (6, 8), (7, 2), (8, 4), (9, 6), (10, 2);
END
GO

-- ============================================================================
-- PERMISSIONS (dành cho dev local)
-- ============================================================================
USE [master];
GO
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'restaurant_user')
    CREATE LOGIN [restaurant_user] WITH PASSWORD = N'your_password', CHECK_POLICY = OFF;
GO
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'restaurant_user')
    ALTER SERVER ROLE [sysadmin] ADD MEMBER [restaurant_user];
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'restaurant_user')
    CREATE USER [restaurant_user] FOR LOGIN [restaurant_user];
GO
EXEC sp_addrolemember N'db_owner', N'restaurant_user';
GO
GRANT CONNECT ON ENDPOINT::[TSQL Default TCP] TO [restaurant_user];
GO
GRANT CONNECT ON ENDPOINT::[TSQL Named Pipes] TO [restaurant_user];
GO

-- ============================================================================
-- KIỂM TRA SAU KHI CHẠY
-- ============================================================================
PRINT N'-- Database QLNH đã sẵn sàng. Kiểm tra:';
SELECT name FROM sys.tables ORDER BY name;
