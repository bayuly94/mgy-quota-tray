# mgy-quota-tray

Lightweight native macOS menu bar (tray) app for monitoring Antigravity multi-account quotas from [multigravity-cli](https://github.com/bayuly94/multigravity-cli/tree/master) (`mgy-quota --json`).

Written purely in Swift with AppKit (no heavy electron, webview, or python runtime needed for the tray).

## Features

- **Monochrome Circle Battery Gauge**: Dynamic circular battery indicator in the menu bar with terminal cap, showing average quota across all active accounts.
- **Auto-Refresh**: Background timer refreshes quota status automatically every 5 minutes.
- **Ranked Profiles**: Dropdown menu sorts accounts by remaining quota from highest to lowest.
- **Quick Actions**:
  - Launch auto/best profile directly in Terminal (`mgy auto`)
  - Launch specific profile session in Terminal (`mgy <profile>`)
  - Copy profile name to clipboard
  - Open full TUI interactive dashboard (`mgy-quota`)
- **LaunchAgent Integration**: Runs quietly in the background as an interactive macOS user agent.

## Requirements

- macOS 11.0+ (Apple Silicon or Intel)
- Swift command-line tools (`swiftc`)
- `mgy` / `mgy-quota` installed and available in `$PATH` (e.g. `~/.local/bin/mgy-quota`)

## Installation

Clone this repository and run the install script:

```bash
git clone https://github.com/bayuly94/mgy-quota-tray.git
cd mgy-quota-tray
chmod +x install.sh
./install.sh
```

The script will:
1. Compile `main.swift` into `~/.local/bin/mgy-tray`
2. Register and start the LaunchAgent (`~/Library/LaunchAgents/dev.mgy.tray.plist`)

## Manual Build

```bash
swiftc -O main.swift -o ~/.local/bin/mgy-tray
~/.local/bin/mgy-tray &
```

## License

MIT
