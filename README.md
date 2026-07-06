<div align="center">

  <h1>🛡️ SafeKey</h1>
  <p><strong>A beautifully designed, secure, and offline-first Authenticator for Android.</strong></p>

  <p>
    <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white&style=for-the-badge" alt="Flutter" />
    <img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white&style=for-the-badge" alt="Platform" />
    <img src="https://img.shields.io/badge/Offline_First-100%25-brightgreen?style=for-the-badge&logo=shield" alt="Offline First" />
    <img src="https://img.shields.io/badge/Privacy-Respected-blueviolet?style=for-the-badge&logo=incognito" alt="Privacy" />
    <img src="https://img.shields.io/badge/Material_3-UI-F35022?style=for-the-badge" alt="Material 3" />
  </p>

  <p>
    <a href="#features">Features</a> •
    <a href="#download">Download</a> •
    <a href="#privacy--security">Security</a> •
    <a href="#wiki">Wiki</a>
  </p>
</div>

---

## 🌟 About SafeKey

SafeKey is a modern, premium alternative to traditional authenticator apps. Built entirely from the ground up to respect your privacy, SafeKey is a **100% offline-first application**. We believe your 2FA codes belong to you, securely stored on your device without being forced into cloud syncing or mandatory third-party accounts.

## ✨ Features

- 🎨 **Premium Material 3 Design**: Enjoy a sleek, modern interface with dynamic colors and smooth animations.
- 🚫 **100% Offline & Private**: Zero network requests. No tracking. No telemetry. Your data stays on your device.
- 🛡️ **Encrypted Recovery Vault**: Securely store your one-time recovery and backup codes directly inside the app.
- 🏷️ **Account Categorization**: Categorize and organize your codes (Work, Personal, Social, etc.).
- 🔒 **Biometric App Lock**: Require fingerprint or face unlock to access your codes.
- 🕵️ **Privacy Mode**: Hide codes by default to prevent shoulder surfing.
- 📦 **Raw Database Backups**: Export and import your encrypted raw SQLite database directly.
- 📤 **QR Export**: Easily migrate your accounts to other devices using standard `otpauth-migration` QR codes.

## 🚀 Download

You can grab the latest stable release of SafeKey from the Releases page.

**[👉 Download the latest APK here](../../releases/latest)**

*Note: SafeKey is currently available exclusively for Android.*

## 🛡️ Privacy & Security

SafeKey is engineered for absolute privacy:
- **No Internet Permission**: The app doesn't even ask for internet access permissions in its Android Manifest. It physically cannot send your data anywhere.
- **Local Storage**: All 2FA secrets and recovery codes are stored locally on your device in a secure SQLite database.
- **Biometric Security**: Uses Android's native secure keystore and biometric APIs to lock the app.

## 📖 Wiki & Documentation

Detailed documentation on how to use SafeKey, understand its security architecture, and best practices for backing up your 2FA codes will be available in our [Wiki](../../wiki) soon!

## Legal

Additional legal documentation can be found here:

- [Copyright](docs/legal/COPYRIGHT.md)
- [Notice](docs/legal/NOTICE.md)
- [Trademarks](docs/legal/TRADEMARKS.md)

---
<div align="center">
  <sub>Built with ❤️ using Flutter.</sub>
</div>
