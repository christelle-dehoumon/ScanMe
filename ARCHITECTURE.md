# ScanMe Architecture

## Overview

ScanMe follows a **clean architecture pattern** with clear separation of concerns:

```
┌─────────────────────────────────────────────┐
│         Presentation Layer (UI)             │
│  Screens, Widgets, State Management         │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│      Business Logic Layer (Repositories)    │
│  Use Cases, Business Rules                  │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│    Data Layer (Firebase + Local Storage)    │
│  APIs, Database, Cache                      │
└─────────────────────────────────────────────┘
```

## Core Directories

### `lib/core/`

#### `theme/`
- **Purpose**: Centralized theming (colors, typography, spacing)
- **Files**: `theme.dart`, `colors.dart`
- **Usage**: All widgets import from here for consistent styling

```dart
AppTheme.darkTheme  // Used in MaterialApp
AppColors.primary   // Reusable color palette
GoogleFonts.spaceGrotesk()  // Typography
```

#### `database/`
- **Purpose**: Local data persistence with encryption
- **Files**: `hive_service.dart`
- **Details**:
  - Hive initialization with encryption
  - Lazy-loaded boxes (contacts, payments, transactions)
  - Automatic sync with Firebase

```dart
await HiveService.init()  // Called in main()
HiveService.contacts.put(key, value)  // Save locally
```

#### `providers/`
- **Purpose**: Riverpod dependency injection
- **Files**: `repositories.dart`
- **Pattern**: Provider factories for all repositories

```dart
final authRepositoryProvider = Provider((ref) => AuthRepository());
ref.watch(authRepositoryProvider)  // Watch state
ref.read(authRepositoryProvider)   // Read once
```

#### `utils/`
- **Purpose**: Helper functions and utilities
- **Files**: `encryption.dart`, `validators.dart`, `permissions.dart`
- **Key Functions**:
  - `EncryptionService.encrypt()` / `decrypt()`
  - `PermissionUtils.requestCameraPermission()`
  - `PhoneValidator.validate()`

#### `constants/`
- **Purpose**: App-wide constants and configurations
- **Files**: `app_constants.dart`, `firebase_options.dart` (generated)

### `lib/features/`

Each feature module is self-contained with its own structure:

```
feature_name/
├── screens/
│   ├── feature_screen.dart
│   └── sub_screen.dart
├── widgets/
│   ├── custom_widget.dart
│   └── card_widget.dart
└── models/
    └── feature_model.dart
```

#### Authentication (`auth/`)
- **Files**: `login_screen.dart`, `otp_screen.dart`, `profile_setup_screen.dart`
- **Flow**: Phone number → OTP verification → Profile setup
- **State**: Managed by `AuthRepository`

#### Scanner (`scanner/`)
- **Files**: `universal_scanner_screen.dart`
- **Features**:
  - QR code parsing (vCard, payment, social)
  - WhatsApp link detection
  - Mock scanning for testing
- **Outputs**: Routes to appropriate handler screen

#### Contacts (`contacts/`)
- **Files**: `scan_contact_result.dart`, `personal_qrs_screen.dart`, `pending_demands_screen.dart`
- **Features**:
  - Save contacts locally and to Firebase
  - Social media profile QR generation
  - Access request management

#### Payments (`payments/`)
- **Files**: `payment_input_screen.dart`, `payment_confirmation_screen.dart`, `payment_qr_list_screen.dart`
- **Features**:
  - Payment QR code generation
  - Mobile money operator integration
  - Receipt generation and sharing

#### Profile (`profile/`)
- **Files**: `profile_screen.dart`
- **Features**:
  - User settings and privacy controls
  - Account deletion
  - Data export

### `lib/data/`

#### Repositories
- **Purpose**: Bridge between UI and data sources
- **Files**: `auth_repository.dart`, `contacts_repository.dart`, `payments_repository.dart`
- **Pattern**: Each repository handles one domain

```dart
class AuthRepository {
  Future<void> sendOtp(String phone) async { ... }
  Future<bool> verifyOtp(String otp) async { ... }
  Future<void> registerProfile({required String name, required String accountType}) { ... }
}
```

#### Services
- **Purpose**: External integrations (Firebase, APIs)
- **Files**: `firebase_service.dart`
- **Responsibilities**:
  - Firebase Auth calls
  - Firestore queries
  - Error handling and retry logic

## State Management: Riverpod

### Provider Types Used

#### 1. **StateProvider** (Mutable state)
```dart
final counterProvider = StateProvider<int>((ref) => 0);
ref.read(counterProvider.notifier).state++;
```

#### 2. **Provider** (Immutable/computed)
```dart
final userProvider = Provider((ref) => ref.watch(authRepositoryProvider).currentUser);
```

#### 3. **FutureProvider** (Async data)
```dart
final contactsProvider = FutureProvider((ref) async {
  return ref.watch(contactsRepositoryProvider).getContacts();
});
```

#### 4. **RepositoryProvider** (Dependency injection)
```dart
final authRepositoryProvider = Provider((ref) => AuthRepository());
```

## Data Flow Example: Scanning a Contact

```
1. User opens UniversalScannerScreen
   ↓
2. MobileScannerController detects QR code
   ↓
3. QR data parsed: VCARD format detected
   ↓
4. Navigation to ScanContactResultScreen
   ↓
5. User taps "Save Contact"
   ↓
6. ContactsRepository.saveScannedContact() called
   ↓
7. Data encrypted using EncryptionService
   ↓
8. Saved to:
   - Local: Hive box ("contacts")
   - Cloud: Firestore ("users/{userId}/contacts")
   ↓
9. UI updates via setState/Riverpod
   ↓
10. Success snackbar shown
```

## Error Handling

### Current Implementation
```dart
try {
  await repository.doSomething();
} catch (e) {
  // Log error
  // Show user-friendly message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Une erreur est survenue.')),
  );
}
```

### Improvements (TODO)
- Implement custom `AppException` hierarchy
- Add automatic retry with exponential backoff
- Log errors to Sentry or similar
- Handle network errors gracefully

## Security Architecture

### Encryption
```
Sensitive Data (Phone, Payment Info)
         ↓
   AES-256 Encryption
         ↓
   Encrypted Storage (Hive)
         ↓
   Firebase (with HTTPS)
```

### Authentication Flow
```
Phone Number
     ↓
Firebase Auth OTP
     ↓
User Session (Firebase Token)
     ↓
Cached in Memory + Hive
```

### Firestore Security Rules
```javascript
// Each user can only access their own data
match /users/{userId}/contacts/{document=**} {
  allow read, write: if request.auth.uid == userId;
}
```

## Testing Strategy

### Unit Tests (Repositories, Utilities)
```dart
test('AuthRepository.verifyOtp returns true for valid OTP', () async {
  final auth = AuthRepository();
  expect(await auth.verifyOtp('123456'), true);
});
```

### Widget Tests (UI Components)
```dart
testWidgets('ContactCard displays name and phone', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(home: ContactCard(contact: mockContact)),
  );
  expect(find.text('John Doe'), findsOneWidget);
});
```

### Integration Tests (Full Features)
```dart
testWidgets('User can scan, save, and view contact', (WidgetTester tester) async {
  // Complete user journey
});
```

## Deployment & CI/CD

### GitHub Actions Workflow
```yaml
name: Tests & Quality
on: [push, pull_request]
jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter analyze
      - run: flutter test
```

## Future Improvements

1. **Backend API**
   - Custom Node.js/Python backend for advanced features
   - Proximity sharing coordination
   - Analytics aggregation

2. **Offline-First**
   - Better sync conflict resolution
   - Delta sync instead of full sync

3. **Performance**
   - Image caching
   - Pagination for large lists
   - Lazy loading

4. **Monitoring**
   - Error tracking (Sentry)
   - Analytics (Firebase Analytics)
   - Performance monitoring (Firebase Perf)
