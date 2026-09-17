# Sekolah App -- Arsitektur White-Label (Multi-Sekolah)

Satu codebase Flutter, dipakai banyak sekolah, masing-masing dengan
domain, nama app, icon, dan warna sendiri-sendiri. Nambah sekolah baru
= edit 1 file JSON + commit, tidak perlu sentuh kode.

## Cara kerja singkat
```
schools/schools.json  <-- SUMBER KEBENARAN: daftar semua sekolah
        |
        ├──> android/app/build.gradle baca file ini saat build,
        |    otomatis bikin "flavor" Android per sekolah
        |    (applicationId, nama app, masing-masing beda)
        |
        └──> lib/school_config.dart baca file ini saat app jalan,
             cari entri sesuai --dart-define=SCHOOL_ID=<id>,
             dipakai untuk tentukan URL website & warna tema

.github/workflows/build-android-multi.yml
        baca schools.json juga, lalu build APK+AAB untuk SETIAP
        sekolah secara paralel, tiap ada push ke branch main.
```

## ⚠️ Setup pertama kali (belum pernah dilakukan)

File-file di zip ini adalah file KUSTOM, bukan seluruh project Flutter
(gradle wrapper, `MainActivity.kt`, dll dari `flutter create` sengaja
tidak disertakan karena itu boilerplate standar yang sama untuk semua
orang). Urutan setup pertama kali:

1. **Install Flutter SDK** kalau belum ada:
   https://docs.flutter.dev/get-started/install
2. Di root repo PHP kamu, buat project Flutter dasar dengan nama folder
   `android_app` dan namespace yang SAMA dengan yang dipakai di
   `android/app/build.gradle` milik zip ini (`id.co.sekolahapp.base`):
   ```bash
   flutter create --org id.co.sekolahapp --project-name sekolah_app android_app
   ```
   Ini akan generate folder `android_app/` lengkap dengan gradle
   wrapper, `MainActivity.kt`, dll.
3. **Timpa** file-file yang di-generate itu dengan file dari zip ini
   (extract zip ini ke root repo, pilih "replace" kalau ditanya):
   - `android_app/pubspec.yaml`
   - `android_app/lib/main.dart` (hapus `lib/main.dart` bawaan `flutter create`)
   - `android_app/lib/school_config.dart` (file baru)
   - `android_app/android/app/build.gradle`
   - `android_app/android/build.gradle`
   - `android_app/android/app/src/main/AndroidManifest.xml`
   - `android_app/schools/` (folder baru, seluruhnya)
   - `android_app/tool/` (folder baru, seluruhnya)
4. Commit hasil `flutter create` + file kustom ini sekaligus ke repo.

Kalau langkah ini terasa rumit, kirim saja hasil `flutter create`
(atau bilang saja mau saya bantu jelaskan tiap error yang muncul).

## Urutan setup berikutnya

1. `android_app/FIREBASE_SETUP.md` -- buat 1 project Firebase +
   daftarkan sekolah pertama (`itracscholl`)
2. `android_app/KEYSTORE_SETUP.md` -- buat keystore + isi 5 GitHub
   Secrets
3. Push ke `main` -- GitHub Actions build otomatis
4. Untuk sekolah selanjutnya: `android_app/ADD_NEW_SCHOOL.md`

## Sekolah yang sudah dikonfigurasi
- **itracscholl** -- Itrac School, `https://yosi.co.id/sekolah/`,
  package `com.itracscholl.app` (icon sudah dipakaikan dari icon
  website yang sudah ada)
