<?php
// Paksa browser/WebView tidak cache halaman ini supaya
// selalu ambil versi terbaru dari server
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Pragma: no-cache');
header('Expires: Thu, 01 Jan 1970 00:00:00 GMT');

require_once __DIR__ . '/../../../includes/functions.php';
requireLogin();
$u = currentUser();
requireIzinMenu($u, 'cbt');
$db = getDB();
$pageTitle = 'Buat Sesi CBT';
$error = '';

$tahunAjaranList = $db->query("SELECT * FROM tahun_ajaran ORDER BY id DESC")->fetchAll();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_verify();
    $nama = trim($_POST['nama'] ?? '');
    $jenis = $_POST['jenis'] ?? 'Lainnya';
    $tahunAjaranId = $_POST['tahun_ajaran_id'] !== '' ? (int) $_POST['tahun_ajaran_id'] : null;
    $tanggalMulai = trim($_POST['tanggal_mulai'] ?? '');
    $tanggalSelesai = trim($_POST['tanggal_selesai'] ?? '');
    $status = $_POST['status'] ?? 'draft';

    if ($nama === '' || $tanggalMulai === '' || $tanggalSelesai === '') {
        $error = 'Nama sesi, waktu mulai, dan waktu selesai wajib diisi.';
    } elseif (!in_array($jenis, ['PTS', 'PAS', 'US', 'Lainnya'], true)) {
        $error = 'Jenis sesi tidak valid.';
    } elseif (!in_array($status, ['draft', 'aktif', 'selesai'], true)) {
        $error = 'Status tidak valid.';
    } elseif (strtotime($tanggalSelesai) <= strtotime($tanggalMulai)) {
        $error = 'Waktu selesai harus setelah waktu mulai.';
    } else {
        $stmt = $db->prepare("
            INSERT INTO cbt_sesi (nama, jenis, tahun_ajaran_id, tanggal_mulai, tanggal_selesai, status, dibuat_oleh)
            VALUES (?,?,?,?,?,?,?)
        ");
        $stmt->execute([$nama, $jenis, $tahunAjaranId, $tanggalMulai, $tanggalSelesai, $status, $u['id']]);
        $sesiId = (int) $db->lastInsertId();
        catatAudit($db, $u, 'cbt', 'create', $u['nama'] . ' membuat sesi CBT "' . $nama . '".');
        setFlash('success', 'Sesi CBT dibuat. Sekarang tambahkan kelas peserta & pengawas.');
        redirect('modules/cbt/sesi/kelas.php?sesi_id=' . $sesiId);
    }
}

// Nilai untuk isi ulang form kalau validasi gagal. Format diubah dari
// "YYYY-MM-DDTHH:mm" (bekas datetime-local) jadi "YYYY-MM-DD HH:mm"
// (format yang dipakai Flatpickr) supaya tetap tampil benar.
$valMulai = str_replace('T', ' ', $_POST['tanggal_mulai'] ?? '');
$valSelesai = str_replace('T', ' ', $_POST['tanggal_selesai'] ?? '');

include __DIR__ . '/../../../includes/header.php';
?>
<!-- Flatpickr: dipakai untuk field jam & tanggal di bawah, MENGGANTI
     input type="datetime-local" bawaan browser. Native picker bawaan
     Android (terutama di skin Transsion/Infinix) punya bug yang bisa
     bikin app WebView force-close saat tombol +/- di jam ditekan
     berkali-kali cepat. Flatpickr adalah picker buatan JS murni, tidak
     memicu komponen native itu sama sekali. -->
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/flatpickr/4.6.13/flatpickr.min.css">
<script src="https://cdnjs.cloudflare.com/ajax/libs/flatpickr/4.6.13/flatpickr.min.js"></script>

<div class="page-header"><h2>+ Buat Sesi CBT</h2></div>
<div class="card" style="max-width:700px;">
  <?php if ($error): ?><div class="alert alert-danger"><?= h($error) ?></div><?php endif; ?>
  <form method="POST">
    <?= csrf_field() ?>
    <div class="form-group">
      <label>Nama Sesi</label>
      <input type="text" name="nama" class="form-control" required placeholder="mis. PAS Ganjil 2026/2027" value="<?= h($_POST['nama'] ?? '') ?>">
    </div>
    <div class="form-row">
      <div class="form-group">
        <label>Jenis</label>
        <select name="jenis" class="form-control">
          <?php foreach (['PTS' => 'PTS (Penilaian Tengah Semester)', 'PAS' => 'PAS (Penilaian Akhir Semester)', 'US' => 'US (Ujian Sekolah)', 'Lainnya' => 'Lainnya'] as $val => $label): ?>
            <option value="<?= $val ?>" <?= ($_POST['jenis'] ?? '') === $val ? 'selected' : '' ?>><?= $label ?></option>
          <?php endforeach; ?>
        </select>
      </div>
      <div class="form-group">
        <label>Tahun Ajaran (opsional)</label>
        <select name="tahun_ajaran_id" class="form-control">
          <option value="">-- Belum ditentukan --</option>
          <?php foreach ($tahunAjaranList as $ta): ?>
            <option value="<?= $ta['id'] ?>"><?= h($ta['nama']) ?> - <?= h($ta['semester']) ?></option>
          <?php endforeach; ?>
        </select>
      </div>
    </div>
    <div class="form-row">
      <div class="form-group">
        <label>Jendela Waktu Mulai</label>
        <input type="text" name="tanggal_mulai" class="form-control datetime-picker" required autocomplete="off" placeholder="Pilih tanggal & jam" value="<?= h($valMulai) ?>">
      </div>
      <div class="form-group">
        <label>Jendela Waktu Selesai</label>
        <input type="text" name="tanggal_selesai" class="form-control datetime-picker" required autocomplete="off" placeholder="Pilih tanggal & jam" value="<?= h($valSelesai) ?>">
      </div>
    </div>
    <p style="font-size:12.5px;color:var(--text-muted);margin:-8px 0 14px;">Siswa hanya bisa memulai ujian dalam rentang waktu ini, terlepas dari deadline masing-masing paket soal per mapel.</p>
    <div class="form-group">
      <label>Status</label>
      <select name="status" class="form-control">
        <option value="draft" <?= ($_POST['status'] ?? 'draft') === 'draft' ? 'selected' : '' ?>>Draft (belum bisa diakses siswa)</option>
        <option value="aktif" <?= ($_POST['status'] ?? '') === 'aktif' ? 'selected' : '' ?>>Aktif</option>
      </select>
    </div>
    <button type="submit" class="btn btn-primary">Simpan & Lanjut Kelola Kelas</button>
    <a href="index.php" class="btn btn-secondary">Batal</a>
  </form>
</div>

<script>
  // Inisialisasi Flatpickr untuk kedua field tanggal+jam.
  // Format "Y-m-d H:i" (mis. "2026-09-17 14:00") tetap bisa dibaca
  // strtotime() di PHP tanpa perlu ubah logic backend sama sekali.
  document.querySelectorAll('.datetime-picker').forEach(function (el) {
    flatpickr(el, {
      enableTime: true,
      dateFormat: 'Y-m-d H:i',
      time_24hr: true,
      minuteIncrement: 5,
    });
  });
</script>

<?php include __DIR__ . '/../../../includes/footer.php'; ?>
