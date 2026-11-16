# PROJECT_CONTEXT.md

Konteks dan pengetahuan proyek `mgy-quota-tray` untuk mencegah salah memahami kebutuhan bisnis dan batasan teknis.

---

## 1. Tujuan Aplikasi

`mgy-quota-tray` adalah aplikasi menu bar (tray) native macOS yang sangat ringan untuk memantau status kuota multi-akun Antigravity (Google / Gemini CLI / multigravity) secara berkala tanpa mengharuskan pengguna membuka terminal secara manual.

Aplikasi ini menjadi jembatan visual antara backend CLI `multigravity-cli` (`mgy-quota`) dan pengguna di macOS.

---

## 2. Business Logic

1. **Data Ingestion**:
   - Mengambil data dengan mengeksekusi perintah CLI: `mgy-quota --json`.
   - Data yang dihasilkan berbentuk array JSON objek `ProfileQuota`.
2. **Aggregasi & Status Bar Icon**:
   - Menghitung nilai kuota maksimal per profil (`maxPct`), yaitu nilai persentase tertinggi di antara model yang aktif pada profil tersebut.
   - Menghitung rata-rata kuota (`avgPct`) dari semua profil yang valid (terautentikasi dan tidak memiliki error).
   - Menggambar lingkaran indikator baterai (`drawCircleBattery(pct:)`) berdasarkan nilai `avgPct`.
   - Sesuai spesifikasi UI terbaru: **status bar tidak menampilkan angka persentase**, hanya menampilkan ikon lingkaran baterai agar menu bar tetap rapi dan minimalis.
3. **Sorting & Rekomendasi Akun**:
   - Menyortir daftar akun secara descending berdasarkan kuota tertinggi (`$0.maxPct > $1.maxPct`).
   - Menampilkan "Akun Rekomendasi" di bagian teratas menu dropdown dengan tombol pintasan untuk menjalankan perintah `mgy auto` di Terminal.
4. **Detail Breakdown Per Akun**:
   - Setiap profil memiliki submenu yang menampilkan nama model AI, progress bar visual (`makeProgressBar`), sisa kuota dalam persen, serta waktu reset kuota.
   - Menyediakan aksi interaktif untuk meluncurkan terminal dengan profil terkait (`mgy <profile>`) dan menyalin nama profil ke clipboard.

---
## 3. Role & Permission

- **User Role**: Dijalankan dalam konteks user macOS reguler (`Interactive` user LaunchAgent).
- **File & Path Access**:
  - Akses baca/tulis ke direktori log `$HOME/.local/share/mgy-tray/`.
  - Akses eksekusi ke binary `mgy-quota` di `$HOME/.local/bin/mgy-quota` atau di dalam `$PATH`.
- **AppleScript Permission**:
  - Menjalankan `NSAppleScript` untuk mengirim perintah ke `Terminal.app` (`tell application "Terminal" do script ...`).
  - Tidak membutuhkan hak akses root atau `sudo`.

---
## 4. Alur Bisnis (Workflow Lifecycle)

```
+-------------------------------------------------------------+
| Application Launch (NSApp.setActivationPolicy(.accessory))  |
+-------------------------------------------------------------+
                               |
                               v
+-------------------------------------------------------------+
| Init Status Item (button.imagePosition = .imageOnly, pct=0) |
+-------------------------------------------------------------+
                               |
                               v
+-------------------------------------------------------------+
| Set Refresh Timer (300 detik) + Call fetchData()            |
+-------------------------------------------------------------+
                               |
                 (Dispatch to Global Queue)
                               v
+-------------------------------------------------------------+
| Exec: export PATH=...; mgy-quota --json                     |
+-------------------------------------------------------------+
                               |
                 (Dispatch to Main Queue)
                               v
+-------------------------------------------------------------+
| Parse JSON -> Sort Profiles -> updateUI()                   |
| - Render CoreGraphics circle battery gauge                   |
| - Build dynamic NSMenu with recommendations & submenus      |
+-------------------------------------------------------------+
                               |
                     (User Interacts)
                               v
+-------------------------------------------------------------+
| User Click:                                                 |
| - Refresh Sekarang: panggil fetchData() langsung            |
| - Launch Terminal: jalankan mgy via AppleScript             |
| - Copy Profil: simpan nama ke NSPasteboard.general          |
| - Keluar: terminate app                                     |
+-------------------------------------------------------------+
```

---
## 5. Keputusan Teknis Penting

- **Swift Murni & AppKit**: Dipilih agar startup seketika (< 50ms), penggunaan RAM sangat kecil (< 15MB), dan bebas overhead runtime seperti Node.js/Electron atau Python.
- **Single-File Executable (`main.swift`)**: Mempermudah distribusi dan kompilasi tanpa perlu setup Xcode project (.xcodeproj) atau Package.swift yang berat.
- **LaunchAgent daemon (`dev.mgy.tray.plist`)**: Memastikan tray otomatis berjalan saat boot/login dan otomatis restart jika crash (`KeepAlive = true`).
- **CoreGraphics Dynamic Drawing**: Ikon tidak menggunakan file gambar statis PNG/asset catalog, melainkan di-render langsung secara vektor sehingga tajam pada layar Retina dan fleksibel terhadap persentase dinamis.

---
## 6. Batasan Sistem (Constraints)

- **Hanya macOS**: Menggunakan API native AppKit (`NSStatusBar`, `NSStatusItem`, `NSImage.isTemplate`, `NSAppleScript`). Tidak kompatibel dengan Linux atau Windows.
- **Ketergantungan pada CLI `mgy-quota`**: Jika `mgy-quota` belum terpasang atau terjadi error internal pada CLI, tray akan menampilkan fallback icon dan menu coba lagi.
- **Read-Only Reporting**: Tray ini tidak mengubah konfigurasi kuota atau otentikasi akun secara langsung; semua mutasi dilakukan melalui terminal `mgy`.
