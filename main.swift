import AppKit
import Foundation

struct QuotaModel: Codable {
    let id: String?
    let name: String?
    let provider: String?
    let pct: Double?
    let reset_str: String?
}

struct ProfileQuota: Codable {
    let profile: String
    let authenticated: Bool?
    let tier: String?
    let total_models: Int?
    let models: [QuotaModel]?
    let critical_count: Int?
    let low_count: Int?
    let error: String?
    
    var maxPct: Double {
        return models?.compactMap { $0.pct }.max() ?? 0.0
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var refreshTimer: Timer?
    var profiles: [ProfileQuota] = []
    var isRefreshing = false
    var lastUpdated: Date? = nil
    let mgyQuotaPath: String = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let localBin = "\(home)/.local/bin/mgy-quota"
        return FileManager.default.fileExists(atPath: localBin) ? localBin : "mgy-quota"
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.imagePosition = .imageLeft
            button.image = drawCircleBattery(pct: 0)
            button.title = "--%"
        }
        
        buildLoadingMenu()
        fetchData()
        
        // Auto refresh setiap 5 menit
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.fetchData()
        }
    }

    func drawCircleBattery(pct: Double) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            
            let center = CGPoint(x: 9, y: 8.5)
            let radius: CGFloat = 6.0
            let lineWidth: CGFloat = 1.8
            
            // 1. Background ring track (subtle monochrome)
            ctx.setStrokeColor(NSColor.black.withAlphaComponent(0.25).cgColor)
            ctx.setLineWidth(lineWidth)
            ctx.strokeEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            
            // 2. Battery terminal cap di atas (12 o'clock)
            let capWidth: CGFloat = 3.2
            let capHeight: CGFloat = 1.3
            let capRect = CGRect(x: center.x - capWidth / 2, y: center.y + radius + 0.6, width: capWidth, height: capHeight)
            let capPath = CGPath(roundedRect: capRect, cornerWidth: 0.6, cornerHeight: 0.6, transform: nil)
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.addPath(capPath)
            ctx.fillPath()
            
            // 3. Progress arc (searah jarum jam dari jam 12)
            let clampedPct = max(0.0, min(100.0, pct))
            if clampedPct > 0 {
                let startAngle: CGFloat = CGFloat.pi / 2
                let endAngle: CGFloat = startAngle - (CGFloat.pi * 2 * CGFloat(clampedPct / 100.0))
                
                ctx.setStrokeColor(NSColor.black.cgColor)
                ctx.setLineWidth(lineWidth)
                ctx.setLineCap(.round)
                
                let arcPath = CGMutablePath()
                arcPath.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
                ctx.addPath(arcPath)
                ctx.strokePath()
            }
            
            return true
        }
        image.isTemplate = true
        return image
    }

    func buildLoadingMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Memuat data kuota mgy...", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        let refreshItem = NSMenuItem(title: "Refresh Sekarang", action: #selector(refreshClicked), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Keluar", action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu
    }

    @objc func refreshClicked() {
        fetchData()
    }

    @objc func quitClicked() {
        NSApp.terminate(nil)
    }

    func fetchData() {
        guard !isRefreshing else { return }
        isRefreshing = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let process = Process()
            let pipe = Pipe()
            
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            let cmd = "export PATH=\"$HOME/.local/bin:/opt/homebrew/bin:$PATH\"; \"\(self.mgyQuotaPath)\" --json"
            process.arguments = ["-c", cmd]
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let parsed = try? JSONDecoder().decode([ProfileQuota].self, from: data) {
                    DispatchQueue.main.async {
                        self.profiles = parsed.sorted { $0.maxPct > $1.maxPct }
                        self.lastUpdated = Date()
                        self.updateUI()
                        self.isRefreshing = false
                    }
                    return
                }
            } catch {
                print("Error fetching quota:", error)
            }
            
            DispatchQueue.main.async {
                self.isRefreshing = false
                self.updateUIOnError()
            }
        }
    }

    func updateUIOnError() {
        if let button = statusItem.button {
            button.image = drawCircleBattery(pct: 0)
            button.title = "Error"
        }
        let menu = NSMenu()
        let errItem = NSMenuItem(title: "Gagal mengambil mgy-quota", action: nil, keyEquivalent: "")
        errItem.isEnabled = false
        menu.addItem(errItem)
        menu.addItem(NSMenuItem.separator())
        let refreshItem = NSMenuItem(title: "Coba Lagi (Refresh)", action: #selector(refreshClicked), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Keluar", action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu
    }

    func makeProgressBar(pct: Double, length: Int = 10) -> String {
        let clamped = max(0.0, min(100.0, pct))
        let filled = Int(round((clamped / 100.0) * Double(length)))
        let empty = length - filled
        return String(repeating: "■", count: filled) + String(repeating: "□", count: empty)
    }

    func updateUI() {
        guard let button = statusItem.button else { return }
        
        let validProfiles = profiles.filter { ($0.authenticated ?? true) && $0.error == nil && !($0.models?.isEmpty ?? true) }
        let avgPct = validProfiles.isEmpty ? 0.0 : (validProfiles.map { $0.maxPct }.reduce(0.0, +) / Double(validProfiles.count))
        
        button.image = drawCircleBattery(pct: avgPct)
        button.title = String(format: "%.0f%%", avgPct)
        
        let menu = NSMenu()
        
        // Header item: summary
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timeStr = lastUpdated != nil ? formatter.string(from: lastUpdated!) : "-"
        
        let header = NSMenuItem(title: String(format: "mgy Quota (Rata-rata: %.1f%% | \(timeStr))", avgPct), action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        
        let best = profiles.first(where: { ($0.authenticated ?? true) && $0.error == nil })
        if let best = best {
            let bestItem = NSMenuItem(title: String(format: "Akun Tertinggi: %@ (%.1f%%)", best.profile, best.maxPct), action: #selector(launchBestProfile), keyEquivalent: "")
            bestItem.target = self
            bestItem.toolTip = "Buka terminal: mgy auto"
            menu.addItem(bestItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Section Header
        let listHeader = NSMenuItem(title: String(format: "PROFIL KUOTA (%d Akun Aktif):", validProfiles.count), action: nil, keyEquivalent: "")
        listHeader.isEnabled = false
        menu.addItem(listHeader)
        
        for p in profiles {
            let pName = p.profile
            let pPct = p.maxPct
            let isAuth = p.authenticated ?? true
            let hasErr = p.error != nil || !isAuth
            
            let bar = makeProgressBar(pct: pPct, length: 8)
            let title: String
            if hasErr {
                title = "[-] \(pName) (Tidak terautentikasi)"
            } else {
                let tierStr = p.tier != nil ? " [\(p.tier!)]" : ""
                title = String(format: "[•] %-18@%@ %5.1f%% %@", pName, tierStr, pPct, bar)
            }
            
            let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            let subMenu = NSMenu()
            
            // Submenu details
            let pHeader = NSMenuItem(title: "Profil: \(pName) (Tier: \(p.tier ?? "-"))", action: nil, keyEquivalent: "")
            pHeader.isEnabled = false
            subMenu.addItem(pHeader)
            subMenu.addItem(NSMenuItem.separator())
            
            if let models = p.models, !models.isEmpty {
                for m in models {
                    let mName = m.name ?? m.id ?? "Model"
                    let mPct = m.pct ?? 0.0
                    let mReset = m.reset_str ?? "-"
                    let mTitle = String(format: "• %@: %.1f%% (Reset: %@)", mName, mPct, mReset)
                    let mItem = NSMenuItem(title: mTitle, action: nil, keyEquivalent: "")
                    mItem.isEnabled = false
                    subMenu.addItem(mItem)
                }
            } else {
                let noModel = NSMenuItem(title: "Tidak ada data model aktif", action: nil, keyEquivalent: "")
                noModel.isEnabled = false
                subMenu.addItem(noModel)
            }
            
            subMenu.addItem(NSMenuItem.separator())
            
            let switchItem = NSMenuItem(title: "Jalankan 'mgy \(pName)' di Terminal", action: #selector(launchProfileInTerminal(_:)), keyEquivalent: "")
            switchItem.target = self
            switchItem.representedObject = pName
            subMenu.addItem(switchItem)
            
            let copyItem = NSMenuItem(title: "Salin Nama Profil", action: #selector(copyProfileName(_:)), keyEquivalent: "")
            copyItem.target = self
            copyItem.representedObject = pName
            subMenu.addItem(copyItem)
            
            item.submenu = subMenu
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Actions
        let tuiItem = NSMenuItem(title: "Buka TUI Dashboard (mgy-quota)", action: #selector(openTUIInTerminal), keyEquivalent: "t")
        tuiItem.target = self
        menu.addItem(tuiItem)
        
        let refreshItem = NSMenuItem(title: "Refresh Sekarang", action: #selector(refreshClicked), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Keluar", action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }

    @objc func launchBestProfile() {
        runTerminalCommand("mgy auto")
    }

    @objc func openTUIInTerminal() {
        runTerminalCommand("mgy-quota")
    }

    @objc func launchProfileInTerminal(_ sender: NSMenuItem) {
        guard let pName = sender.representedObject as? String else { return }
        runTerminalCommand("mgy \(pName)")
    }

    @objc func copyProfileName(_ sender: NSMenuItem) {
        guard let pName = sender.representedObject as? String else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(pName, forType: .string)
    }

    func runTerminalCommand(_ cmd: String) {
        let appleScript = """
        tell application \"Terminal\"
            activate
            do script \"\(cmd)\"
        end tell
        """
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: appleScript) {
            scriptObject.executeAndReturnError(&error)
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
