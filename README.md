# Restaurant Waiter Order System

A Flutter and Firebase Firestore application for a restaurant waiter to manage menu items, take table orders, and track each order from `Pending` until `Paid`.

The app is intentionally simple for assignment use:

- No login
- No registration
- No authentication
- No role management
- The app opens directly to the Orders screen

## Features

### Menu management

- Add new menu items
- View menu items
- Filter menu items by category
- Edit menu item details
- Delete menu items
- Toggle item availability
- Store menu data in Firestore

Menu item fields:

- `name`
- `price`
- `category`
- `available`
- `created_at`
- `updated_at`

### Order management

- Create new table orders
- Select a table number
- Add menu items to an order
- Adjust item quantities
- View subtotals and calculated total
- Save orders and related order items to Firestore
- Edit Pending orders
- Cancel Pending orders
- View order details
- Move orders through the required lifecycle

Order status lifecycle:

```text
Pending -> Preparing -> Served -> Paid
```

Only the next valid status is allowed. Paid orders have no further action.

### Table handling

- Every order is assigned to a table.
- Table selection is required before placing an order.
- Active orders block reuse of the same table.
- Paid orders do not block table reuse.

Active statuses:

- `Pending`
- `Preparing`
- `Served`

## Technology used

- Dart
- Flutter
- Material 3
- Firebase Core
- Cloud Firestore
- `setState` for simple local UI state

Main dependencies:

```yaml
firebase_core
cloud_firestore
```

## Firestore collections

The app uses three top-level Firestore collections.

### `menu_items`

Stores restaurant menu items.

| Field        | Description                 |
| ------------ | --------------------------- |
| `name`       | Menu item name              |
| `price`      | Item price                  |
| `category`   | Item category               |
| `available`  | Whether item can be ordered |
| `created_at` | Created timestamp           |
| `updated_at` | Updated timestamp           |

### `orders`

Stores the parent order record.

| Field        | Description             |
| ------------ | ----------------------- |
| `table_no`   | Restaurant table number |
| `status`     | Order status            |
| `total`      | Stored order total      |
| `created_at` | Created timestamp       |
| `updated_at` | Updated timestamp       |

### `order_items`

Stores line items linked to an order.

| Field            | Description                        |
| ---------------- | ---------------------------------- |
| `order_id`       | Parent order document ID           |
| `menu_item_id`   | Menu item document ID              |
| `name_snapshot`  | Item name at the time of ordering  |
| `price_snapshot` | Item price at the time of ordering |
| `quantity`       | Ordered quantity                   |

`name_snapshot` and `price_snapshot` keep old orders correct even if a menu item is later edited or deleted.

## Main screens

The app includes the required screens:

1. Orders List
2. New Order
3. Order Detail
4. Menu List
5. Add/Edit Menu Item

The home screen provides bottom navigation between:

- Orders
- Menu

## Project structure

```text
lib/
|-- app.dart
|-- firebase_options.dart
|-- main.dart
|-- models/
|-- screens/
|   |-- home_screen.dart
|   |-- menu/
|   `-- orders/
|-- services/
|-- theme/
|-- utils/
`-- widgets/
```

## Firebase setup

Firebase is initialized in `main.dart` before `runApp()`:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

The project includes:

- `lib/firebase_options.dart`
- `android/app/google-services.json`

## Firestore classroom-use note

This assignment intentionally has no login, authentication, or role management because the only app user is a waiter.

If this project is using Firestore test-mode or open development rules, that is suitable only for classroom development and emulator testing. Do not deploy the app unchanged for a real restaurant system without adding proper Firebase security rules and authentication.

## How to run

Install dependencies:

```bash
flutter pub get
```

Run on an emulator or connected device:

```bash
flutter run
```

Build a debug APK:

```bash
flutter build apk --debug
```

The debug APK is generated at:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## Verification commands

Format the project:

```bash
dart format .
```

Analyze the project:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Current verified result:

```text
flutter test
69 tests passed

flutter analyze
No issues found
```

## Notes for submission

Before creating the final ZIP file, exclude generated or temporary files/folders such as:

- `build/`
- `.dart_tool/`
- `.idea/`
- `.agents/`
- `dart_format.txt`
- `flutter_analyze.txt`
- `flutter_test.txt`
- `flutter_build.txt`

Suggested final ZIP filename format:

```text
FinalTest_<MatricNo>_<Name>.zip
```

Also include the required assignment report PDF separately or as instructed by the lecturer.
