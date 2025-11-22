# projectz

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

# Seller App - B2B Construction Vendor Inventory Management

A Flutter-based B2B application for construction vendors to manage inventory, receive orders, and track sales.

## 🏗️ Architecture

This project follows **Clean Architecture** principles with feature-based organization:

```
lib/
├── core/                    # Core utilities and shared code
│   ├── constants/          # App constants, colors, strings
│   ├── config/             # Configuration and environment
│   ├── di/                 # Dependency injection
│   ├── error/              # Error handling
│   ├── routes/             # App routing
│   ├── theme/              # App theme
│   └── utils/              # Utility functions
├── features/               # Feature modules
│   ├── auth/               # Authentication feature
│   │   ├── data/          # Data layer (repositories, datasources)
│   │   └── domain/        # Domain layer (repositories interfaces)
│   ├── inventory/          # Inventory management
│   └── storage/            # Image storage
├── models/                 # Data models
├── widgets/                # Reusable widgets
└── main.dart              # App entry point
```

## 🚀 Features

### Implemented
- ✅ User authentication (Login/Register)
- ✅ Seller profile management
- ✅ Inventory management (CRUD operations)
- ✅ Inventory search and filtering
- ✅ Stock level tracking
- ✅ Clean architecture with repository pattern
- ✅ Error handling and logging
- ✅ Theme management

### In Progress / Planned
- ⏳ Order management (models created, UI pending)
- ⏳ Push notifications
- ⏳ Offline support
- ⏳ Analytics dashboard
- ⏳ Reports and exports

## 📋 Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Firebase project setup
- Supabase project setup

## 🔧 Setup Instructions

### 1. Clone the repository
```bash
git clone <repository-url>
cd projectz
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Firebase Setup
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android/iOS apps to your Firebase project
3. Download configuration files:
   - `google-services.json` for Android (place in `android/app/`)
   - `GoogleService-Info.plist` for iOS (place in `ios/Runner/`)
4. Update `lib/config/firebase_options.dart` with your Firebase configuration

### 4. Supabase Setup
1. Create a Supabase project at [Supabase](https://supabase.com/)
2. Get your project URL and anon key
3. Update `lib/core/config/environment.dart` with your Supabase credentials
   - Or use environment variables: `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

### 5. Run the app
```bash
flutter run
```

## 🏛️ Architecture Overview

### Clean Architecture Layers

1. **Domain Layer** (`features/*/domain/`)
   - Repository interfaces
   - Business logic contracts
   - No dependencies on external frameworks

2. **Data Layer** (`features/*/data/`)
   - Repository implementations
   - Remote and local data sources
   - Data models and DTOs

3. **Presentation Layer** (`features/*/presentation/` or screens)
   - UI components
   - State management
   - User interactions

### Dependency Injection

The app uses a `ServiceLocator` pattern for dependency injection:

```dart
final authRepo = ServiceLocator().authRepository;
final inventoryRepo = ServiceLocator().inventoryRepository;
```

### Repository Pattern

All data operations go through repositories:

```dart
// Instead of direct Firestore calls
await ServiceLocator().inventoryRepository.addInventoryItem(item);
```

## 📁 Key Files

- `lib/core/constants/app_constants.dart` - App-wide constants
- `lib/core/constants/app_colors.dart` - Color scheme
- `lib/core/constants/app_strings.dart` - String resources
- `lib/core/error/exception_handler.dart` - Error handling
- `lib/core/di/service_locator.dart` - Dependency injection
- `lib/models/inventory_item.dart` - Inventory model
- `lib/models/order.dart` - Order model

## 🔐 Security Notes

⚠️ **Important:** Currently, API keys are in the code. For production:
1. Use environment variables or `--dart-define`
2. Never commit API keys to version control
3. Implement proper Firestore security rules
4. Use secure storage for sensitive data

## 🧪 Testing

Testing infrastructure is set up but tests need to be written:
- Unit tests for repositories
- Widget tests for UI components
- Integration tests for critical flows

## 📱 Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web (partial)

## 🛠️ Development Guidelines

### Adding a New Feature

1. Create feature folder structure:
   ```
   lib/features/new_feature/
   ├── data/
   │   ├── datasources/
   │   └── repositories/
   └── domain/
       └── repositories/
   ```

2. Create repository interface in domain layer
3. Implement repository in data layer
4. Add to ServiceLocator
5. Create UI components

### Code Style

- Follow Dart/Flutter style guide
- Use meaningful variable names
- Add comments for complex logic
- Keep functions small and focused

## 📚 Documentation

- [REFACTORING_SUMMARY.md](REFACTORING_SUMMARY.md) - Detailed refactoring documentation
- [GAPS_AND_IMPROVEMENTS.md](GAPS_AND_IMPROVEMENTS.md) - List of gaps and improvements

## 🐛 Known Issues

See [GAPS_AND_IMPROVEMENTS.md](GAPS_AND_IMPROVEMENTS.md) for a comprehensive list of known issues and improvements needed.

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Write/update tests
4. Submit a pull request

## 📄 License

[Add your license here]

## 👥 Authors

[Add author information]

## 🙏 Acknowledgments

- Flutter team
- Firebase
- Supabase

---

**Note:** This is a work in progress. See the documentation files for detailed information about the current state and planned improvements.
