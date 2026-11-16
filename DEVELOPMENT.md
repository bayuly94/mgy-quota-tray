# DEVELOPMENT.md

Panduan development, build, dan debugging untuk `mgy-quota-tray`.

---

## 1. Environment Setup

### Prasyarat Sistem
- **Sistem Operasi**: macOS Big Sur (11.0) ke atas.
- **Swift Toolchain**: Pastikan `swiftc` terpasang (bawaan dari Command Line Tools / Xcode):
  ```bash
  swiftc --version
  ```
- **multigravity-cli**: Pastikan `mgy` dan `mgy-quota` sudah terpasang dan dapat dijalankan:
  ```bash
  mgy-quota --version
  which mgy-quota
  ```
  *(Secara default script akan memeriksa `$HOME/.local/bin/mgy-quota` atau fallback ke `$PATH`)*.

---

## 2. Cara Menjalankan Project

### A. Instalasi Otomatis (Direkomendasikan)
Jalankan skrip `install.sh` untuk kompilasi dan registrasi service background LaunchAgent:
```bash
cd /Users/macbookpro/projects/multigravity/mgy-quota-tray
chmod +x install.sh
./install.sh
```

### B. Menjalankan Manual (Foreground Testing / Debugging)
Untuk menguji output terminal atau mencetak log langsung ke console tanpa LaunchAgent:
```bash
# 1. Hentikan service LaunchAgent terlebih dahulu (jika aktif)
launchctl unload ~/Library/LaunchAgents/dev.mgy.tray.plist 2>/dev/null || true
killall mgy-tray 2>/dev/null || true

# 2. Kompilasi binary
swiftc -g main.swift -o /tmp/mgy-tray-debug

# 3. Jalankan langsung
/tmp/mgy-tray-debug
```

---

## 3. Build & Test Commands

### Kompilasi Release (Optimasi `-O`)
```bash
swiftc -O main.swift -o ~/.local/bin/mgy-tray
```

### Restart Background Service
```bash
launchctl unload ~/Library/LaunchAgents/dev.mgy.tray.plist 2>/dev/null || true
launchctl load ~/Library/LaunchAgents/dev.mgy.tray.plist
```

### Validasi JSON Output mgy-quota
Pastikan payload JSON yang diterima tray valid:
```bash
mgy-quota --json | jq .
```

---

## 4. Dependencies

- **Zero External Packages**: Proyek ini tidak memiliki file `Package.swift`, `Podfile`, `Cartfile`, atau `node_modules`.
- **Native Frameworks**: Menggunakan framework bawaan macOS:
  - `AppKit` (`NSApplication`, `NSStatusBar`, `NSStatusItem`, `NSMenu`, `NSFont`)
  - `Foundation` (`Process`, `Pipe`, `JSONDecoder`, `Timer`, `DateFormatter`)

---

## 5. Database & Migrations

- **Stateless**: Aplikasi ini tidak menggunakan database lokal (seperti SQLite atau CoreData). Data kuota disimpan dan dikelola sepenuhnya oleh `multigravity-cli`.
- Setiap kali refresh (atau per 5 menit), data dimuat segar dari output CLI ke memori (`AppDelegate.profiles`).

---

## 6. Debugging & Troubleshooting

### Memeriksa Status Service
```bash
# Cek apakah proses aktif
pgrep -fl mgy-tray

# Cek status launchctl
launchctl list | grep dev.mgy.tray
```

### Membaca Log Runtime
Log stdout dan stderr diarahkan ke direktori `$HOME/.local/share/mgy-tray/`:
```bash
# Realtime error log
tail -f ~/.local/share/mgy-tray/mgy-tray.err.log

# Realtime standard log
tail -f ~/.local/share/mgy-tray/mgy-tray.log
```

### Masalah Umum
1. **Ikon Menampilkan Error / Menu Gagal Mengambil Data**:
   - Periksa path `mgy-quota` dengan menjalankan: `which mgy-quota`.
   - Jika berada di luar `$HOME/.local/bin` atau `/opt/homebrew/bin`, sesuaikan property `mgyQuotaPath` atau perintah `export PATH=...` di `fetchData()`.
2. **Ikon Tray Tidak Muncul**:
   - Menu bar macOS mungkin terlalu penuh oleh aplikasi lain. Tutup beberapa aplikasi menu bar atau gunakan resolusi layar yang lebih tinggi.
   - Pastikan proses tidak crash saat startup dengan memeriksa `mgy-tray.err.log`.
