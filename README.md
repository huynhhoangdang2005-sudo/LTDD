# Restaurant App

A full‑stack restaurant management solution built with:

- **Backend**: Dart with `shelf` exposing a REST API, connected to a MySQL database.
- **Mobile app**: Flutter (Dart) for Android/iOS.

## Features

| Feature | Description |
|--------|-------------|
| Login / Register | JWT based authentication. |
| Employee Management | Managers can create, edit, lock/unlock, and remove staff accounts. |
| Manage Tables | Create, update, delete restaurant tables. |
| Menu Management | CRUD for menu categories & items. |
| Order Placement | Customers can browse the menu, add items to a cart, place an order. |
| Payment | Simple mock‑payment endpoint (replace with real gateway). |
| Revenue Report | Daily / monthly sales summary. |

## Project Structure

```
restaurant_app/
├─ backend/          # Dart Shelf API
│   ├─ lib/
│   │   ├─ main.dart
│   │   └─ routes/ (auth, menu, order, table, report)
│   └─ pubspec.yaml
└─ mobile/           # Flutter client
    ├─ lib/
    │   ├─ main.dart
    │   ├─ models/ (user, menu_item, order, table, report)
    │   ├─ services/ (api_service.dart)
    │   └─ screens/ (login, menu, cart, payment, table, report)
    └─ pubspec.yaml
```

## Prerequisites

- **Flutter SDK** (>=3.19) – https://flutter.dev/docs/get-started/install
- **Dart SDK** (bundled with Flutter) – used for the backend as well.
- **MySQL** server (local or remote) – create a database `restaurant_db`.

## Quick Start (Windows)

1. **Clone / create the folder**
   ```powershell
   cd d:\
   git clone <repo‑url> restaurant_app   # or just work inside the existing folder
   ```
2. **Setup MySQL**
   ```sql
   CREATE DATABASE restaurant_db;
   CREATE USER 'restaurant_user'@'%' IDENTIFIED BY 'your_password';
   GRANT ALL ON restaurant_db.* TO 'restaurant_user'@'%';
   FLUSH PRIVILEGES;
   ```
   For a new database, apply `backend/db_schema.sql`. The backend checks for and adds missing columns on startup for existing databases; `backend/db_migration.sql` is also available for manual migration of an untouched previous schema.
   Register the first account in the app, then grant it manager access:
   ```sql
   UPDATE users SET role = 'Quản lý' WHERE username = 'your_username';
   ```
   Sign in again after changing the role. Employee-management endpoints require an active manager account.
3. **Backend**
   ```powershell
   cd d:\restaurant_app\backend
   dart pub get
   # Edit lib/config.dart if you need to change DB credentials
   dart run lib/main.dart
   ```
   The API will start on `http://localhost:8080`.
4. **Mobile App**
   ```powershell
   cd d:\restaurant_app\mobile
   flutter pub get
   flutter run
   ```
   Choose an emulator/device.

## Configuration

- **Backend DB connection** – edit `lib/config.dart` (host, port, user, password, db).
- **API base URL** – the Flutter app reads `API_BASE_URL` from `lib/services/api_service.dart`. Change it if the backend runs on a different host.

## Next Steps

- Replace the mock payment endpoint with a real gateway (Stripe, PayPal, …).
- Add unit / integration tests.
- Deploy backend (Docker, Cloud Run, etc.) and point the mobile app to the production URL.

---

*This scaffold is intentionally minimal but functional. Feel free to extend the UI, add validation, or improve error handling.*
