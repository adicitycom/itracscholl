# Setup Keystore Signing (Dipakai Bersama Semua Sekolah)

Semua app sekolah ditandatangani dengan **1 keystore yang sama**. Ini
sengaja dipilih supaya maintenance simpel -- 4 GitHub Secrets ini cukup
untuk BERAPA PUN jumlah sekolah, tidak nambah secret tiap ada sekolah
baru. (Play Store tidak mewajibkan tiap app punya keystore beda-beda;
yang wajib adalah konsisten -- 1 app yang sama harus terus dipakai
keystore yang sama sepanjang umur app itu.)

**PENTING**: simpan file keystore ini baik-baik (password manager /
backup terenkripsi, di luar folder project). Kalau hilang, SEMUA app
sekolah yang sudah publish tidak akan bisa di-update lagi lewat Play
Console (harus buat listing baru dari nol, kehilangan rating & install
history).

## 1. Buat keystore (SEKALI SAJA, untuk seluruh jaringan sekolah)

```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias sekolahapp-network
```

Catat password (2x) dan alias yang dipakai.

## 2. Encode ke base64

```bash
base64 -i upload-keystore.jks | tr -d '\n' > upload-keystore.jks.b64
```

## 3. Tambahkan 4 GitHub Secrets (SEKALI SAJA)

**Settings → Secrets and variables → Actions → New repository secret**

| Nama Secret                | Isi                                      |
|------------------------------|--------------------------------------------|
| `ANDROID_KEYSTORE_BASE64`   | isi file `upload-keystore.jks.b64`        |
| `ANDROID_KEYSTORE_PASSWORD` | password keystore                         |
| `ANDROID_KEY_PASSWORD`      | password key                              |
| `ANDROID_KEY_ALIAS`         | `sekolahapp-network` (atau alias kamu)    |

Plus `SECRETS_PASSPHRASE` dari `FIREBASE_SETUP.md` -- total **5 secrets**,
selamanya, berapa pun jumlah sekolahnya.

## Build otomatis

Setelah 5 secrets di atas terisi, tiap push ke `main` yang mengubah
folder `android_app/`, GitHub Actions otomatis build APK+AAB untuk
**SETIAP sekolah** yang ada di `schools.json`, paralel. Hasil per
sekolah muncul di tab **Actions** → run terakhir → **Artifacts**,
dengan nama `apk-<id_sekolah>` dan `aab-<id_sekolah>`.
