# Setup Firebase (Multi-Sekolah)

## Kenapa 1 project Firebase untuk semua sekolah?
Firebase mendukung banyak "app" (Android/iOS) di dalam 1 project. Ini
lebih mudah dikelola dibanding bikin project baru per sekolah:
- 1 dashboard untuk pantau semua
- 1 kali setup billing (kalau nanti kena tier berbayar karena banyak
  notifikasi)
- Kirim notifikasi tetap bisa dipisah per sekolah (asal server PHP
  simpan `school_id` bersama tiap FCM token -- lihat komentar `TODO`
  di `lib/main.dart`)

## Setup awal (SEKALI SAJA, untuk sekolah pertama)

1. Buka https://console.firebase.google.com → **Add project**
2. Beri nama, misal "Sekolah App Network" (nama project, bukan nama
   sekolah tertentu, karena akan dipakai bersama semua sekolah)
3. Google Analytics boleh dimatikan

## Setiap ada sekolah baru

Lihat `ADD_NEW_SCHOOL.md` bagian "Daftarkan sekolah ini di Firebase" --
intinya: di project Firebase yang SAMA, klik **Add app** → Android,
isi `applicationId` sekolah itu, download `google-services.json`,
enkripsi, commit.

## Pastikan Cloud Messaging API aktif
Project settings (ikon gear) → tab **Cloud Messaging** → pastikan
**Firebase Cloud Messaging API (V1)** statusnya **Enabled**.

## Setup passphrase enkripsi (SEKALI SAJA, di awal)

Semua file `google-services.json` dienkripsi pakai 1 passphrase yang
sama, disimpan sebagai GitHub Secret. Ini yang membuat "tambah sekolah
baru" tidak perlu buka Settings GitHub tiap kali.

1. Buat passphrase yang kuat & acak, simpan di password manager, misal:
   `openssl rand -base64 32`
2. Di GitHub repo: **Settings → Secrets and variables → Actions →
   New repository secret**
   - Nama: `SECRETS_PASSPHRASE`
   - Value: passphrase yang kamu buat

Passphrase ini HANYA diinput sekali di GitHub Secrets. Setelahnya,
setiap sekolah baru cukup pakai passphrase yang sama saat enkripsi
lokal (lihat `ADD_NEW_SCHOOL.md`) -- tidak perlu balik ke Settings
GitHub lagi.

## Mengirim push notification dari server PHP tiap sekolah

Server tiap sekolah (bisa beda-beda hosting) perlu:
1. Tabel `fcm_tokens (user_id, school_id, token, updated_at)` --
   kolom `school_id` PENTING supaya notifikasi tidak salah kirim
   antar sekolah kalau nanti ada 1 server pusat yang kirim untuk semua.
2. Endpoint simpan token, dipanggil app setelah login.
3. Kirim notifikasi lewat **Firebase Admin SDK** atau **FCM HTTP v1
   API**, pakai Service Account key dari project Firebase yang sama
   (**Project settings → Service accounts → Generate new private key**).
   Simpan key ini di luar folder yang bisa diakses publik lewat URL.
