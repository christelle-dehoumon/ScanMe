# Development Setup Guide

## Prerequisites

### Required
- Flutter SDK 3.10.7+
- Dart SDK (comes with Flutter)
- Git
- IDE (VS Code or Android Studio)

### Platform-Specific

#### iOS
- Xcode 14+
- CocoaPods
- iOS deployment target: 12.0+

#### Android
- Android SDK 21+ (API level)
- Android Studio
- Android Gradle Plugin 7.0+

## Installation Steps

### 1. Clone Repository
```bash
git clone https://github.com/christelle-dehoumon/ScanMe.git
cd ScanMe
```

### 2. Install Flutter Dependencies
```bash
flutter pub get
```

### 3. Firebase Setup

#### 3.1 Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create project"
3. Name: "ScanMe"
4. Enable Google Analytics (optional)
5. Create project

#### 3.2 Add Firebase Apps

**For Android:**
1. In Firebase, click "Add app" → Android
2. Download `google-services.json`
3. Place in: `android/app/`

**For iOS:**
1. Click "Add app" → iOS
2. Download `GoogleService-Info.plist`
3. Place in: `ios/Runner/`
4. Add to Xcode: Xcode → Runner → Build Phases → Copy Bundle Resources

#### 3.3 Configure with FlutterFire
```bash
flutter pub global activate flutterfire_cli
flutterfire configure
```

Select:
- Platforms: Android, iOS (and Web if needed)
- Firebase project: your-project-id
- Services: Authentication, Firestore, Cloud Messaging

### 4. Setup Pre-commit Hooks
```bash
# Install pre-commit framework
pip install pre-commit

# Install hooks
pre-commit install

# Test hooks on all files
pre-commit run --all-files
```

### 5. Configure IDE

#### VS Code
```bash
code .
```

Install extensions:
- Flutter (Dart Code)
- Dart (Dart Code)
- Firebase Explorer (mightynerd.firebaseexplorer)

#### Android Studio
1. Open project
2. Wait for indexing to complete
3. Run → Run on device

## Running the App

### Android Emulator
```bash
# List available emulators
flutter emulators

# Launch emulator
flutter emulators --launch emulator-name

# Run app
flutter run
```

### iOS Simulator
```bash
# Launch simulator
open -a Simulator

# Run app
flutter run
```

### Chrome (Web)
```bash
flutter run -d chrome
```

### Physical Device
```bash
# Enable developer mode on device
# Connect via USB
# Run:
flutter run
```

## Development Workflow

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
flutter format .

# Run tests
flutter test

# Check test coverage
flutter test --coverage
```

### Database Setup

#### Firestore
1. Firebase Console → Firestore Database
2. Click "Create database"
3. Select "Start in test mode" (development only)
4. Choose region closest to your users

#### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      match /{document=**} {
        allow read, write: if request.auth.uid == userId;
      }
    }
  }
}
```

### Environment Configuration

Create `.env` file (not committed):
```
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_WEB_API_KEY=your-api-key
LOG_LEVEL=debug
```

Load in `main.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load();
  runApp(const ScanMeApp());
}
```

## Troubleshooting

### Build Issues

**"Unable to find flutter SDK"**
```bash
flutter clean
flutter pub get
flutter pub cache repair
```

**"Gradle build failed"**
```bash
cd android
./gradlew clean
cd ..
flutter pub get
```

**"Pod install failed" (iOS)**
```bash
cd ios
pod install
cd ..
```

### Firebase Issues

**"google-services.json not found"**
- Ensure file is in `android/app/`
- Run `flutterfire configure` again

**"GoogleService-Info.plist not found"** (iOS)
- Add to Xcode: Right-click Runner → Add Files
- Select `GoogleService-Info.plist`
- Check "Copy items if needed"

**"Firebase initialization error"**
```dart
// Add debug logging
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
print('Firebase initialized successfully');
```

### Common Errors

**"Unsupported android_id on emulator"**
- Run with `-DUSE_DEBUG_ID=true` flag

**"Permission denied (camera, contacts)"**
- Grant permissions in device settings
- Request permissions in-app

**"No connected devices"**
```bash
flutter devices  # List devices
flutter run -d device-id  # Run on specific device
```

## Testing

### Unit Tests
```bash
flutter test test/unit/
```

### Widget Tests
```bash
flutter test test/widget/
```

### Integration Tests
```bash
flutter test test/integration/
```

### All Tests
```bash
flutter test
```

## Deployment

### Build for Production

#### Android APK
```bash
flutter build apk --release
# Output: build/app/release/app-release.apk
```

#### Android App Bundle
```bash
flutter build appbundle --release
# Output: build/app/release/app-release.aab
```

#### iOS
```bash
flutter build ios --release
# Output in build/ios/iphoneos/
```

### Deploy to Play Store
1. Build app bundle: `flutter build appbundle --release`
2. Go to [Google Play Console](https://play.google.com/console/)
3. Upload .aab file
4. Fill in store listing
5. Submit for review

### Deploy to App Store
1. Build iOS: `flutter build ios --release`
2. Use Xcode to create archive
3. Go to [App Store Connect](https://appstoreconnect.apple.com/)
4. Upload via Xcode or Transporter
5. Submit for review

## Useful Commands

```bash
# Clean everything
flutter clean

# Get latest dependencies
flutter pub upgrade

# Generate generated code (if using build_runner)
flutter pub run build_runner build

# View logs
flutter logs

# Run with verbosity
flutter run -v

# Profile performance
flutter run --profile
```

## Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase for Flutter](https://firebase.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Flutter Best Practices](https://flutter.dev/docs/testing/best-practices)
