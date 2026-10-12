-- Run once on databases created from the previous db_schema.sql.
ALTER TABLE users
  ADD COLUMN full_name VARCHAR(100) NOT NULL DEFAULT '',
  ADD COLUMN role VARCHAR(40) NOT NULL DEFAULT 'Khách hàng',
  ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'active',
  ADD COLUMN phone VARCHAR(30) NOT NULL DEFAULT '';

ALTER TABLE menu_items
  ADD COLUMN image_url VARCHAR(500) NOT NULL DEFAULT '',
  ADD COLUMN available BOOLEAN NOT NULL DEFAULT TRUE;

ALTER TABLE tables
  ADD COLUMN status VARCHAR(30) NOT NULL DEFAULT 'Trống';

-- Preserve the existing admin account as the initial manager.
UPDATE users SET role = 'Quản lý' WHERE username = 'admin';