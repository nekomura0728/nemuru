# Project Structure

## Root Directory
```
nemuru/
├── lib/                    # Main Dart source code
├── android/               # Android-specific files
├── ios/                   # iOS-specific files
├── assets/                # Static assets (images, fonts)
├── supabase/             # Backend configuration
├── docs/                 # Documentation
├── screenshots/          # App store screenshots
├── test/                 # Test files
└── web/                  # Web platform files (minimal)
```

## Core Application Structure (`lib/`)

### Main Entry Point
- `main.dart` - App initialization, service setup, routing

### Feature Organization
```
lib/
├── constants/            # App-wide constants
│   ├── api_constants.dart
│   ├── app_constants.dart
│   └── ui_constants.dart
├── models/              # Data models
│   ├── character.dart
│   ├── chat_log.dart
│   ├── message.dart
│   └── user_profile.dart
├── screens/             # UI screens/pages
│   ├── check_in_screen.dart
│   ├── ai_response_screen.dart
│   ├── chat_history_screen.dart
│   ├── settings_screen.dart
│   └── onboarding_screen.dart
├── services/            # Business logic & external integrations
│   ├── gpt_service.dart
│   ├── chat_log_service.dart
│   ├── subscription_service.dart
│   ├── notification_service.dart
│   └── preferences_service.dart
├── widgets/             # Reusable UI components
│   ├── character_image_widget.dart
│   └── character_image_painter.dart
├── theme/               # App theming
│   └── app_theme.dart
└── utils/               # Utility functions (currently empty)
```

## Architecture Patterns

### State Management
- **Provider Pattern**: Used throughout for dependency injection and state management
- **Services**: Business logic separated into service classes
- **Models**: Data structures with methods for serialization/deserialization

### Screen Flow
1. **Onboarding** → **Check-in** (mood selection)
2. **Check-in** → **AI Response** (conversation)
3. **AI Response** → **Chat History** (log viewing)
4. **Settings** (accessible from multiple screens)

### Service Layer
- `GPTService`: AI conversation management
- `ChatLogService`: Local chat history storage
- `SubscriptionService`: Premium feature management
- `PreferencesService`: User settings persistence
- `NotificationService`: Local notifications

## Asset Organization
```
assets/
├── images/              # Character images (1.png - 18.png)
│   ├── 1.png - 12.png  # Character avatars
│   └── 13.png - 18.png # Mood icons
├── icon/               # App icons
│   ├── app_icon.png
│   ├── app_icon_android.png
│   └── app_icon_ios.png
└── fonts/              # Custom fonts (currently empty)
```

## Platform-Specific Structure

### Android (`android/`)
- Standard Flutter Android project structure
- `app/build.gradle.kts` - Build configuration
- `app/src/main/AndroidManifest.xml` - App permissions & metadata
- Signing configuration in `key.properties`

### iOS (`ios/`)
- Standard Flutter iOS project structure
- `Runner.xcodeproj` - Xcode project
- `Info.plist` - App configuration
- CocoaPods integration via `Podfile`

## Backend Structure (`supabase/`)
```
supabase/
├── functions/           # Edge Functions
│   ├── chat-completion/ # AI conversation endpoint
│   └── verify-purchase/ # Purchase verification
├── migrations/          # Database schema
└── config.toml         # Supabase configuration
```

## Naming Conventions
- **Files**: snake_case (e.g., `check_in_screen.dart`)
- **Classes**: PascalCase (e.g., `CheckInScreen`)
- **Variables**: camelCase (e.g., `selectedMood`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `API_BASE_URL`)
- **Private members**: Leading underscore (e.g., `_textController`)

## Import Organization
1. Dart core libraries
2. Flutter framework imports
3. Third-party package imports
4. Local project imports (relative paths)

## Key Architectural Decisions
- **Local-first**: All user data stored locally via SharedPreferences
- **Service-oriented**: Business logic separated from UI
- **Provider pattern**: Consistent state management approach
- **Character-driven**: AI personalities defined as data models
- **Privacy-focused**: Minimal external data transmission