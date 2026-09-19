# Fix: Face Attendance Camera Permission Issue

## Masalah
Ketika siswa login dan mencoba melakukan absensi wajah (face attendance), sistem menampilkan error:
- "Gagal mengakses kamera" (Failed to access camera)
- "Memuat model permission denied" (Loading model permission denied)

## Penyebab Root
WebView tidak dikonfigurasi untuk menangani permission request dari konten web (JavaScript). Meskipun Flutter meminta izin kamera di startup, WebView tidak bisa menggunakannya tanpa:
1. Handler `onPermissionRequest` di NavigationDelegate
2. Explicit permission granting dari native code
3. Proper microphone permission (untuk beberapa model face detection)

## Solusi yang Diimplementasikan

### 1. **CameraPermissionManager Service** (`lib/services/camera_permission_manager.dart`)
Layanan terpusat untuk mengelola camera dan microphone permissions:
- `checkCameraPermission()` - Cek status izin kamera
- `checkMicrophonePermission()` - Cek status izin mikrofon
- `requestCameraPermission()` - Minta izin kamera dengan retry logic
- `requestMicrophonePermission()` - Minta izin mikrofon
- `ensureCameraPermission()` - Pastikan izin diberikan, buka settings jika ditolak
- `ensureMicrophonePermission()` - Pastikan izin mikrofon diberikan
- `ensureAllMediaPermissions()` - Pastikan semua media permissions diberikan

### 2. **WebView Permission Handler** (`lib/main.dart`)
Ditambahkan `onPermissionRequest` di NavigationDelegate:
```dart
onPermissionRequest: (request) async {
  // Cek tipe permission yang diminta (video/audio)
  // Request permission dari OS jika belum diberikan
  // Grant permission jika berhasil
  // Deny jika user menolak
  // Tampilkan error message jika permanently denied
}
```

### 3. **Android Manifest Updates** (`android/app/src/main/AndroidManifest.xml`)
Tambahan permissions:
- `android.permission.RECORD_AUDIO` - Untuk microphone access
- `<uses-feature android:hardware.microphone>` - Declare microphone feature

### 4. **Enhanced Permission Request** (`lib/main.dart` - `_requestPermissions`)
- Request camera + microphone di startup
- Retry mechanism jika camera permission gagal pada percobaan pertama
- Logging untuk debug

### 5. **WebViewConfig Class** (`android/app/src/main/kotlin/.../WebViewConfig.kt`)
Custom WebChromeClient untuk Android-specific permission handling (optional, untuk Android 6.0+)

## Alur Kerja Setelah Fix

1. **App Startup**
   - Flutter requests camera + microphone permissions
   - Jika user grant: permissions tersimpan di OS
   - Jika user deny: retry logic akan aktif saat face attendance diakses

2. **Student Face Attendance**
   - Web portal requests camera permission via JavaScript
   - `onPermissionRequest` handler tertrigger
   - Cek apakah permission sudah diberikan:
     - ✅ Jika ya: grant permission ke WebView
     - ❌ Jika tidak: request ke user (akan muncul native dialog)
     - 🔒 Jika permanently denied: tampilkan error message & suggest settings

3. **Permission Result**
   - WebView granted: Face detection model dapat akses kamera
   - User dapat melakukan face attendance normalement

## Testing Checklist

- [ ] Clean build: `flutter clean && rm pubspec.lock && flutter pub get`
- [ ] Build APK: `flutter build apk --release --flavor itracscholl`
- [ ] Test on Android 6.0+ device:
  1. Grant camera permission at startup ✓
  2. Go to face attendance section
  3. Camera should open without "permission denied" error
  4. Face detection model should load properly
  5. If permission was denied: system should request it again
  6. If permission permanently denied: helpful error message should show

## Files Modified
- `android_app/lib/main.dart` - Added import & permission handling
- `android_app/lib/services/camera_permission_manager.dart` - NEW
- `android_app/android/app/src/main/AndroidManifest.xml` - Added RECORD_AUDIO
- `android_app/android/app/src/main/kotlin/.../WebViewConfig.kt` - NEW (optional)

## Troubleshooting

**Masalah: Masih error "permission denied" setelah fix**

Kemungkinan:
1. User belum grant permission di OS → Buka Settings > Apps > Sekolah App > Permissions > Grant Camera
2. Device tidak support camera → Gunakan device lain dengan camera
3. Android version < 6.0 → Device perlu Android 6.0 atau lebih tinggi
4. WebView cache → Clear cache: Menu > Clear Cache

**Masalah: Camera permission request tidak muncul**

Kemungkinan:
1. Permission sudah ditolak sebelumnya → Perlu buka Settings > Apps > Permission Manager > Camera > Reset
2. App needs rebuild → Run `flutter clean && flutter pub get && flutter run`

## Technical Details

### WebView Permission Request Types (Android)
- `PermissionRequest.RESOURCE_VIDEO_CAPTURE` - Camera access
- `PermissionRequest.RESOURCE_AUDIO_CAPTURE` - Microphone access

### Permission Handling Flow
```
User clicks "Absensi Wajah"
    ↓
JavaScript requests camera via getUserMedia()
    ↓
Android WebView triggers onPermissionRequest()
    ↓
Flutter onPermissionRequest handler checks:
  - Is camera permission granted in Android?
  - If NO: Request from user via native dialog
  - If YES: Grant to WebView
    ↓
JavaScript gets camera stream
    ↓
Face detection model loads and runs
```

## References
- Flutter WebView: https://pub.dev/packages/webview_flutter
- Android WebView Permissions: https://developer.android.com/guide/webapps/managing-permissions
- Permission Handler: https://pub.dev/packages/permission_handler
