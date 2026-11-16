# PROJECT_MAP.md

Peta navigasi repository `mgy-quota-tray` untuk memudahkan AI Agent dan developer menemukan komponen tanpa scanning menyeluruh.

---

## 1. Struktur Folder

```
mgy-quota-tray/
├── main.swift              # Sumber kode utama aplikasi (Single-file native AppKit)
├── install.sh              # Skrip kompilasi, instalasi binary, dan registrasi LaunchAgent
├── dev.mgy.tray.plist      # Template LaunchAgent plist untuk auto-start dan keep-alive
├── README.md               # Dokumentasi umum untuk pengguna
├── AGENTS.md               # Instruksi dan standar kerja AI agent
├── PROJECT_MAP.md          # Peta navigasi struktur proyek ini
├── PROJECT_CONTEXT.md      # Konteks bisnis dan latar belakang teknis
├── DEVELOPMENT.md          # Panduan operasional development & debugging
└── CHANGELOG_AI.md         # Catatan jejak kerja dan riwayat perubahan AI
```

---

## 2. Lokasi Model, Controller, dan Service

Seluruh komponen inti aplikasi terorganisir di dalam `main.swift` secara modular:

| Komponen | Bagian / Baris di `main.swift` | Deskripsi |
|---|---|---|
| **Model** | `struct QuotaModel` (L4-10) | Data model kuota model AI (id, name, pct, reset_str, provider). |
| **Model** | `struct ProfileQuota` (L12-25) | Data model profil akun mgy (profile, tier, models, maxPct, error). |
| **Controller** | `class AppDelegate` (L27-351) | Lifecycle controller, NSApplicationDelegate, event handlers, & state. |
| **Service / Runner** | `fetchData()` (L137-175) | Subprocess service yang memanggil CLI `mgy-quota --json` secara async. |
| **Terminal Service** | `runTerminalCommand()` (L339-350) | AppleScript service untuk menjalankan perintah di Terminal.app. |

---

## 3. Entry Point Aplikasi

- **File**: `main.swift`
- **Baris**: L353 - L356
```swift
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
```
Saat `NSApp.run()` dijalankan, kontrol diserahkan ke `AppDelegate.applicationDidFinishLaunching(_:)` (L39), yang menginisialisasi `statusItem`, menyembunyikan icon dock (`.accessory`), menggambar icon status awal, dan memulai polling timer.

---

## 4. Lokasi Fitur Utama

- **Circle Battery Gauge Renderer** (`drawCircleBattery(pct:)`, L58-101):
  - Menggambar indikator baterai bulat berbasis CoreGraphics (`CGContext`).
  - Dilengkapi terminal cap di jam 12 dan arc persentase searah jarum jam.
  - Di-set sebagai `.isTemplate = true` agar dinamis terhadap dark/light mode.
- **Progress Bar Generator** (`makeProgressBar(pct:length:)`, L103-113):
  - Membuat indikator teks visual (`━` dan `─`) untuk menu dropdown.
- **Polling & Data Sync** (`applicationDidFinishLaunching`, L52-56 & `fetchData`, L137-175):
  - Timer 300 detik (5 menit) yang mengeksekusi `mgy-quota --json`.
- **UI Rendering & Menu Builder** (`updateUI()`, L197-317):
  - Mengupdate ikon status item tanpa teks persentase (`button.title = ""`).
  - Membangun menu dropdown interaktif: header rata-rata, rekomendasi profil terbaik, daftar akun dengan submenu detail model AI, dan quick actions.

---

## 5. File Konfigurasi & Deployment Penting

- **`install.sh`**:
  - Mengompilasi `main.swift` menggunakan `swiftc -O` langsung ke target `$HOME/.local/bin/mgy-tray`.
  - Membuat LaunchAgent plist di `$HOME/Library/LaunchAgents/dev.mgy.tray.plist`.
  - Me-reload LaunchAgent menggunakan `launchctl`.
- **`dev.mgy.tray.plist`**:
  - File template konfig LaunchAgent dengan `RunAtLoad = true`, `KeepAlive = true`, serta redirect output/error log ke `$HOME/.local/share/mgy-tray/`.
