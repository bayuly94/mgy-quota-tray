# CHANGELOG_AI.md

Catatan pekerjaan AI Agent pada repositori `mgy-quota-tray`. Digunakan untuk melacak riwayat perubahan, keputusan implementasi, dan pekerjaan lanjutan antar-session.

---

## [2026-11-16] - Penyesuaian UI Status Bar & Dokumentasi Agen

### 1. Fitur yang Selesai
- **Penyederhanaan Status Bar Menu Bar**:
  - Menghapus tampilan teks nilai persentase kuota (seperti `100%`, `50%`, `--%`) dari status bar menu bar.
  - Mengubah mode tombol status bar menjadi icon-only (`button.imagePosition = .imageOnly`).
  - Mempertahankan seluruh rincian pada dropdown menu (rata-rata kuota, akun rekomendasi, progress bar persentase per profil, dan rincian model AI) tanpa perubahan.
- **Inisialisasi Dokumentasi Komprehensif**:
  - Membuat `AGENTS.md` (aturan coding, guidelines, dan batasan).
  - Membuat `PROJECT_MAP.md` (peta struktur proyek dan navigasi kode).
  - Membuat `PROJECT_CONTEXT.md` (konteks bisnis, alur kerja, dan batasan).
  - Membuat `DEVELOPMENT.md` (panduan build, testing, dan debugging).
  - Membuat `CHANGELOG_AI.md` (catatan jejak kerja).

### 2. File yang Diubah
- `main.swift`:
  - Baris inisialisasi status bar button diubah dari `.imageLeft` dengan title `"--%"` menjadi `.imageOnly` dengan title kosong `""`.
  - Pembaruan UI di `updateUI()` mengubah `button.title = String(format: "%.0f%%", avgPct)` menjadi `button.title = ""`.
- Penambahan file baru:
  - `AGENTS.md`
  - `PROJECT_MAP.md`
  - `PROJECT_CONTEXT.md`
  - `DEVELOPMENT.md`
  - `CHANGELOG_AI.md`

### 3. Bug / Masalah yang Ditemukan
- Teks persentase di menu bar macOS memakan ruang horizontal yang cukup lebar pada resolusi layar tertentu, sehingga ikon saja lebih ringkas dan sesuai kaidah HIG macOS untuk status bar gauges.

### 4. Keputusan Implementasi
- Menggunakan `button.imagePosition = .imageOnly` dan `button.title = ""` alih-alih mengubah `variableLength` menjadi fixed width statis, sehingga ukuran status item otomatis menyesuaikan lebar gambar CoreGraphics tanpa memotong tepi ikon.

### 5. Pekerjaan yang Belum Selesai / Rekomendasi Masa Depan
- [ ] Menambahkan opsi interval auto-refresh yang dapat dikonfigurasi melalui preferences/command line (saat ini statis 300 detik).
- [ ] Alert / notifikasi sistem (macOS Notification Center) ketika kuota semua akun di bawah ambang batas kritis (misal < 10%).
- [ ] Opsi klik kanan untuk menu cepat refresh/keluar langsung.
