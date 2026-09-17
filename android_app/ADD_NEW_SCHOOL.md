# Cara Menambah Sekolah Baru

Ini adalah SATU-SATUNYA prosedur yang perlu diulang tiap ada sekolah baru.
Tidak ada file kode (`.dart`, `.gradle`) yang perlu disentuh.

## Syarat "id" sekolah
`id` di `schools.json` dipakai langsung sebagai nama Android flavor, jadi
harus:
- huruf kecil semua, tanpa spasi, tanpa titik/strip (`-`)
- contoh valid: `smpn1contoh`, `sditalhikmah`, `smanegeri5`
- contoh TIDAK valid: `smp-1-contoh`, `SD Al-Hikmah`, `smp.1`

## Langkah-langkah

### 1. Tambah entri di `android_app/schools/schools.json`
```json
{
  "id": "smpn1contoh",
  "appName": "SMPN 1 Contoh",
  "applicationId": "id.sch.smpn1contoh.app",
  "websiteUrl": "https://domain-sekolah-ini.sch.id/",
  "allowedDomain": "domain-sekolah-ini.sch.id",
  "themeColor": "#2E7D32"
}
```
(tambahkan sebagai elemen baru di array, jangan hapus yang sudah ada)

`applicationId` HARUS unik dan tidak akan pernah dipakai ulang -- ini
identitas permanen app itu di Play Store, tidak bisa diganti setelah
publish pertama kali.

### 2. Siapkan icon
Simpan file PNG 1024x1024 (persegi, tanpa banyak transparan) ke:
```
android_app/schools/smpn1contoh/icon.png
```

### 3. Daftarkan sekolah ini di Firebase (untuk push notification)
1. Buka Firebase Console → project yang sudah ada (jangan buat project baru)
2. **Add app** → Android → package name: isi persis `applicationId` di atas
3. Download `google-services.json` yang ditawarkan
4. **Enkripsi file itu** (jangan commit mentahnya ke repo):
   ```bash
   openssl enc -aes-256-cbc -pbkdf2 -salt \
     -in google-services.json \
     -out google-services.json.enc \
     -pass pass:"ISI_DENGAN_PASSPHRASE_YANG_SAMA_SEPERTI_SECRET_SECRETS_PASSPHRASE"
   ```
   (passphrase ini harus SAMA dengan yang tersimpan di GitHub Secret
   `SECRETS_PASSPHRASE` -- tanya admin repo kalau lupa nilainya)
5. Simpan hasilnya ke:
   ```
   android_app/schools/smpn1contoh/google-services.json.enc
   ```

### 4. Commit & push
```bash
git add android_app/schools/smpn1contoh
git add android_app/schools/schools.json
git commit -m "Tambah sekolah: SMPN 1 Contoh"
git push
```

### 5. Selesai
GitHub Actions otomatis mendeteksi sekolah baru di `schools.json` dan
build APK+AAB untuk sekolah ini bersamaan dengan sekolah-sekolah lain.
Cek tab **Actions** di GitHub setelah beberapa menit -- hasil ada di
bagian **Artifacts** dengan nama `apk-smpn1contoh` dan `aab-smpn1contoh`.

## Kalau nanti mau ganti sesuatu untuk 1 sekolah tertentu
- **Ganti domain**: edit `websiteUrl`/`allowedDomain` di `schools.json`, push.
- **Ganti nama app**: edit `appName` di `schools.json`, push.
- **Ganti icon**: timpa file `schools/<id>/icon.png`, push.
- **Ganti warna tema**: edit `themeColor` (format hex, mis. `#RRGGBB`), push.

Semua di atas TIDAK butuh publish ulang app secara manual -- cukup push,
GitHub Actions build AAB baru, kamu upload AAB itu ke Play Console
sebagai update versi (naikkan `versionCode` dulu di `pubspec.yaml` kalau
mau publish ke Play Store, karena Play Store menolak AAB dengan
versionCode yang sama dengan yang sudah pernah di-upload).
