# SafeKey 🔐

**SafeKey** is a modern, privacy-focused, and highly secure TOTP (Time-based One-Time Password) Authenticator app built with Flutter. Designed as a drop-in replacement for Google Authenticator, SafeKey brings robust encryption and an elegant user experience to your 2FA needs.

## ✨ Features

- **Google Authenticator Import:** Seamlessly migrate from Google Authenticator by scanning your Google Export QR Codes. SafeKey automatically parses Protobuf payloads and handles batch imports!
- **Encrypted Local Storage:** All your TOTP secrets are encrypted at rest using **SQLCipher** (256-bit AES encryption) via Drift.
- **Biometric App Lock:** Secure the entire app behind your device's fingerprint or face unlock using `local_auth`.
- **Privacy First (Hidden Codes):** Prevent shoulder-surfing by hiding codes by default. Simply tap a code to temporarily reveal it.
- **Gallery & Camera Scanning:** Add new accounts by scanning QR codes via your camera (powered by ML Kit) or by picking a screenshot from your photo gallery.
- **Dynamic Sorting & Multi-Delete:** Sort your accounts by Name, Issuer, or Recency. Long-press to enter multi-select mode and manage your accounts effortlessly.
- **Theme Support:** Beautiful Dark and Light modes that adapt to your system.

## 🛠️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) & Dart
- **State Management:** [Riverpod](https://riverpod.dev/)
- **Local Database:** [Drift](https://drift.simonbinder.eu/) (SQLite) + [SQLCipher](https://www.zetetic.net/sqlcipher/) (Encrypted SQLite)
- **Scanner:** [Mobile Scanner](https://pub.dev/packages/mobile_scanner) + Google ML Kit
- **Routing:** [GoRouter](https://pub.dev/packages/go_router)

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.10+)
- Android SDK & Android Studio

### Installation & Build

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/safekey.git
   cd safekey
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run Code Generation (Drift/Riverpod):**
   ```bash
   dart run build_runner build -d
   ```

4. **Run the App:**
   ```bash
   flutter run
   ```

5. **Build for Production (Android APK):**
   ```bash
   flutter build apk --release
   ```
   The compiled APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.

## 🛡️ Security Note
Because SafeKey relies on SQLCipher to encrypt your local database, running the app on platforms without a pre-compiled native SQLCipher binary (like some Linux Desktop environments) may require additional CMake configuration. It is recommended to build and test SafeKey directly on an Android device or Emulator.

## 🤝 Contributing
Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/yourusername/safekey/issues).

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.
