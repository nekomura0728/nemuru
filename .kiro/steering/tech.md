# Technology Stack

## Framework & Language
- **Flutter**: Cross-platform mobile app framework
- **Dart**: Programming language (SDK >=2.19.0 <4.0.0)
- **Target Platforms**: iOS and Android

## Key Dependencies
### Core Flutter
- `flutter`: SDK framework
- `cupertino_icons`: iOS-style icons
- `provider`: State management solution

### Data & Storage
- `shared_preferences`: Local key-value storage
- `uuid`: Unique identifier generation

### UI & Design
- `google_fonts`: Custom font integration
- `flutter_svg`: SVG image support
- `flutter_markdown`: Markdown rendering
- `table_calendar`: Calendar widget

### External Services
- `http`: HTTP client for API calls
- `url_launcher`: External URL handling
- `package_info_plus`: App version info

### Platform Features
- `flutter_local_notifications`: Push notifications
- `timezone`: Timezone handling
- `in_app_purchase`: App Store/Play Store purchases

### Development
- `flutter_test`: Testing framework
- `flutter_lints`: Code linting rules
- `flutter_launcher_icons`: App icon generation

## Backend Services
- **Supabase**: Backend-as-a-Service
  - Edge Functions for AI chat completion
  - Purchase verification
  - Database for subscription management
- **OpenAI API**: GPT-4o-mini for AI conversations

## Common Commands

### Development
```bash
# Get dependencies
flutter pub get

# Run app (debug mode)
flutter run

# Run on specific device
flutter run -d <device-id>

# Hot reload during development
# Press 'r' in terminal or save files in IDE
```

### Building
```bash
# Build APK (Android)
flutter build apk

# Build App Bundle (Android - recommended for Play Store)
flutter build appbundle

# Build iOS (requires Xcode)
flutter build ios

# Build for release
flutter build apk --release
flutter build ios --release
```

### Testing & Analysis
```bash
# Run tests
flutter test

# Analyze code
flutter analyze

# Check for outdated dependencies
flutter pub outdated

# Update dependencies
flutter pub upgrade
```

### Icon Generation
```bash
# Generate app icons from flutter_launcher_icons.yaml
flutter pub run flutter_launcher_icons:main
```

## Build Configuration
- **Android**: Gradle-based build system
- **iOS**: Xcode project with CocoaPods
- **Minimum SDK**: Android API level varies, iOS deployment target in Info.plist
- **Signing**: Android uses keystore (nemuru-upload-key.jks), iOS uses provisioning profiles