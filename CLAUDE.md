# iTrac Sekolah - Project Documentation

White-label Flutter application for multi-school attendance & report system.

## Project Structure

```
.
├── android_app/          # Flutter mobile app
│   ├── lib/              # Dart source code
│   ├── android/          # Android native code & config
│   └── pubspec.yaml      # Flutter dependencies
├── .github/workflows/    # CI/CD pipelines
└── schools/              # School configuration & assets
```

## Build & Development

### Prerequisites

- Flutter 3.29.0+ (stable)
- Android SDK 35+
- Java 17+

### Setup

```bash
cd android_app
flutter pub get
```

### Build Release APK

```bash
flutter build apk --release --flavor SCHOOL_ID
# Example: flutter build apk --release --flavor itracscholl
```

### Build AAB (for Play Store)

```bash
flutter build appbundle --release --flavor SCHOOL_ID
```

## Key Features

### Print/Cetak Button
- Tombol "Cetak" membuka PDF/dokumen di browser eksternal HP
- Implemented via JavaScript injection + url_launcher
- Works for: rapor, surat, attendance documents

### DateTime Picker
- Custom native Flutter date/time picker for web form inputs
- Replaces HTML datetime-local inputs

### Multi-School (White-Label)
- Single codebase, many school flavors
- Each school has unique:
  - Application ID
  - App name & theme colors
  - Firebase config (google-services.json)
  - Website URL

### CI/CD
- Automatic build on push to main
- Multi-school matrix builds (each school built separately)
- APK & AAB artifacts

## Dependencies

### Critical
- `webview_flutter: ^4.9.0` - WebView for loading school portal
- `url_launcher: ^6.3.0` - Open URLs in external apps
- `firebase_messaging: ^15.1.3` - Push notifications

### Build Tools
- `webview_flutter_android: 4.9.0` - Exact version (supports print interception)
- Android compileSdk 35

## Troubleshooting

### Build Fails with "method not found"
- Run: `flutter clean && rm pubspec.lock && flutter pub get`
- Ensure Flutter 3.29.0+: `flutter --version`

### Print Button Not Working
- Check browser can access school website URL
- Verify url_launcher has necessary permissions
- Check JavaScript console (DevTools) for errors

### Firebase Issues
- Verify google-services.json decryption with correct passphrase
- Check Firebase project configuration

## Git Workflow

- Main branch: production ready
- Commits auto-build all school flavors
- Keep pubspec.lock and build/ excluded (.gitignore)

## Notes

- Print functionality uses external browser, not in-app PDF viewer
- For physical printing: use browser on desktop (Windows/Mac/Linux)
- All school configuration centralized in `schools/schools.json`
