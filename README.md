# ScanMe 📱

A modern mobile app designed to simplify and streamline daily contact sharing, QR code management, and mobile money payments. Built with Flutter and Firebase for West African users.

## Features

### Contact Management
- Scan contact QR codes (vCard format)
- Social media profile linking (Instagram, TikTok, Snapchat)
- Grant/revoke access to your contacts
- Local contact storage with cloud sync
- Secure contact data encryption

### Payment Integration
- Generate payment QR codes
- Support for Orange Money, Moov Money, and Wave
- Transaction history with receipt generation
- Share payment receipts

### Scanner
- Universal QR code scanner
- WhatsApp link detection
- Contact, payment, and social profile parsing

### Security
- End-to-end encryption for sensitive data
- Firebase authentication with OTP
- Privacy controls and data deletion
- RGPD compliant

## Getting Started

### Prerequisites
- Flutter SDK: ^3.10.7
- Firebase account
- Xcode (for iOS) or Android Studio (for Android)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/christelle-dehoumon/ScanMe.git
   cd ScanMe
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   ```bash
   flutterfire configure
   ```
   This generates `lib/firebase_options.dart`

4. **Run the app**
   ```bash
   flutter run
   ```

### Setup Pre-commit Hooks

```bash
# Install pre-commit framework
pip install pre-commit

# Install hooks
pre-commit install

# (Optional) Run hooks on all files
pre-commit run --all-files
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── core/
│   ├── theme/              # App theming
│   ├── database/           # Hive local storage
│   ├── providers/          # Riverpod providers
│   ├── utils/              # Helper functions
│   └── constants/          # App constants
├── features/
│   ├── auth/               # Authentication screens
│   ├── home/               # Home dashboard
│   ├── scanner/            # QR code scanner
│   ├── contacts/           # Contact management
│   ├── payments/           # Payment features
│   └── profile/            # User profile
└── data/
    ├── repositories/       # Business logic
    └── services/           # Firebase services

test/
├── unit/                   # Unit tests
├── widget/                 # Widget tests
└── fixtures/               # Test data
```

## 🧪 Testing

### Run Tests
```bash
# All tests
flutter test

# Specific test file
flutter test test/unit/auth_test.dart

# With coverage
flutter test --coverage
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
flutter format .

# Check formatting
flutter format --set-exit-if-changed .
```

## Security

### Data Encryption
Sensitive data (phone numbers, transaction details) is encrypted using AES encryption:

```dart
import 'package:scanme_app/core/utils/encryption.dart';

// Encrypt
final encrypted = EncryptionService.encrypt(phoneNumber);

// Decrypt
final decrypted = EncryptionService.decrypt(encrypted);
```

### Best Practices
- All Firebase rules are configured for user isolation
- OTP validation required for authentication
- Phone numbers are masked in UI displays
- Transaction data is never stored in plain text
- Local cache is encrypted using Hive encryption

## Architecture

ScanMe follows a clean architecture pattern:

- **Presentation Layer**: Flutter widgets with Riverpod state management
- **Business Logic Layer**: Repositories and use cases
- **Data Layer**: Firebase and local Hive storage

### State Management
We use **Riverpod** for:
- Provider-based dependency injection
- Reactive state management
- Async data fetching

##  Development

### Running in Development Mode
```bash
flutter run -d chrome  # Web
flutter run -d emulator-5554  # Android emulator
```

### Mock Data (Testing)
Use the simulator helpers in `universal_scanner_screen.dart` to mock QR scans:
```dart
_simulateScan('contact');  // Mock contact QR
_simulateScan('orange_payment');  // Mock payment QR
```

## Localization

Currently supports French. To add more languages:
1. Add language files to `assets/l10n/`
2. Update `pubspec.yaml` with new locales

## Build for Production

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Troubleshooting

### Firebase Connection Issues
- Ensure `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) are configured
- Run `flutterfire configure` again

### Scanner Permissions
- Grant camera permissions in app settings
- On Android, ensure "Allow all the time" is selected for location (if needed)

### Local Storage Issues
- Clear app data: `flutter clean`
- Reinstall: `flutter pub get`

## Contributing

1. Create a feature branch: `git checkout -b feature/amazing-feature`
2. Commit changes with meaningful messages
3. Push to the branch: `git push origin feature/amazing-feature`
4. Open a Pull Request

### Code Standards
- Run `flutter analyze` before committing
- Ensure all tests pass: `flutter test`
- Format code: `flutter format .`
- Pre-commit hooks will run automatically

## License

This project is private and proprietary.

## Support

For issues or questions:
- Open an GitHub issue
- Contact: christelle-dehoumon@example.com

## Roadmap

- [ ] Proximity-based contact sharing (Bluetooth/NFC)
- [ ] Offline-first architecture
- [ ] Web dashboard
- [ ] Multi-language support
- [ ] Advanced analytics
- [ ] API rate limiting
- [ ] User notifications

---

**Made for West Africa**
