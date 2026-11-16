# AGENTS.md

Panduan dan instruksi kerja bagi AI Agent yang bekerja pada repositori `mgy-quota-tray`.

---

## 1. Coding Standards

- **Language & Framework**: Swift murni (Swift 5+) dengan framework native macOS **AppKit** (`NSStatusBar`, `NSStatusItem`, `NSMenu`, `NSGraphicsContext`).
- **Zero External Dependencies**: Jangan menambahkan dependensi eksternal (SPM, CocoaPods, Carthage, Electron, atau Python wrapper) kecuali diinstruksikan secara eksplisit oleh pengguna.
- **Threading & Concurrency**:
  - Semua operasi I/O dan eksekusi proses eksternal (`mgy-quota --json`) **wajib** dijalankan di background thread (`DispatchQueue.global(qos: .userInitiated).async`).
  - Semua pembaruan UI (`statusItem.button`, `statusItem.menu`) **wajib** dieksekusi di main thread (`DispatchQueue.main.async`).
- **Memory & Resource Management**:
  - Gunakan `[weak self]` di dalam closure timer atau dispatch async untuk mencegah retain cycles.
  - Jaga footprint memori tetap minimal (< 20 MB RAM) karena aplikasi berjalan terus-menerus sebagai background menu bar agent.

---
## 2. UI/UX Guidelines

- **macOS Menu Bar Conventions**:
  - Ikon statusbar menggunakan format template image (`image.isTemplate = true`) agar otomatis menyesuaikan dengan macOS Dark Mode dan Light Mode.
  - Status bar tray harus hemat ruang (ringkas dan bersih).
  - Sesuai arahan pengguna, status bar hanya menampilkan ikon indikator baterai bulat tanpa teks persentase (`imagePosition = .imageOnly`, `button.title = ""`).
- **Dropdown Menu Hierarchy**:
  - Summary & timestamp di bagian atas sebagai header yang dinonaktifkan (`isEnabled = false`).
  - Rekomendasi akun terbaik dengan aksi cepat (`mgy auto`).
  - Daftar akun diurutkan dari kuota tertinggi ke terendah.
  - Tampilan teks tabular menggunakan font monospace (`NSFont.monospacedSystemFont`) agar bar indikator dan nilai persentase rata secara vertikal.
  - Submenu per akun untuk melihat rincian model AI, waktu reset, tombol salin profil, dan aksi buka terminal.

---
## 3. Aturan Membaca File

- **Gunakan File Map**: Selalu baca `PROJECT_MAP.md` sebelum mencari file untuk menghindari scanning direktori secara masif.
- **Gunakan Absolute Path**: Gunakan absolute path atau path relatif langsung ke file target (`/Users/macbookpro/projects/multigravity/mgy-quota-tray/...`).
- **Baca Bagian yang Dibutuhkan**: Hindari membaca log atau file binary secara penuh jika hanya membutuhkan cuplikan error/log terakhir.

---
## 4. Aturan Implementasi

- **Targeted Edits**: Gunakan tool `patch` untuk perubahan kode yang presisi, jangan menimpa seluruh file jika perubahannya hanya beberapa baris.
- **Shell Execution**: Eksekusi perintah CLI eksternal (`mgy-quota`, `Terminal`) harus menangani fallback `PATH` (`$HOME/.local/bin:/opt/homebrew/bin:$PATH`) karena LaunchAgent tidak mewarisi environment interactive shell pengguna secara default.
- **Atomic & Safe**: Setiap perubahan pada kode Swift harus dipastikan lolos kompilasi (`swiftc`) sebelum di-deploy ke LaunchAgent.

---
## 5. Testing Requirements

Sebelum menandai pekerjaan selesai:
1. **Kompilasi Manual**: Jalankan kompilasi Swift dengan optimasi:
   ```bash
   swiftc -O main.swift -o /Users/macbookpro/.local/bin/mgy-tray
   ```
2. **Reload Service**: Pastikan LaunchAgent memuat binary terbaru:
   ```bash
   launchctl unload ~/Library/LaunchAgents/dev.mgy.tray.plist 2>/dev/null || true
   launchctl load ~/Library/LaunchAgents/dev.mgy.tray.plist
   ```
3. **Cek Log**: Periksa file error log untuk memastikan tidak ada runtime crash:
   ```bash
   tail -n 20 ~/.local/share/mgy-tray/mgy-tray.err.log
   ```
4. **Verifikasi Proses**: Pastikan proses `mgy-tray` berjalan aktif (`pgrep -fl mgy-tray`).

---
## 6. Batasan Agar Tidak Overengineering

- **Tetap Ringkas (Single/Few Files)**: Proyek ini dirancang sebagai utility ringan. Jangan membuat arsitektur multi-layer, DI container, atau abstraksi berlebihan yang tidak perlu.
- **Jangan Tambahkan Webview**: Hindari rendering berbasis HTML/CSS untuk tray item native macOS.
- **Stateless Design**: Biarkan `mgy-quota` CLI menjadi sumber kebenaran (source of truth). Tray app hanya bertindak sebagai visualizer dan trigger CLI.
