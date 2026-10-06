<p align="center">
  <img src="assets/app_icon.png" alt="Debrify" width="120" height="120">
</p>

<h1 align="center">Debrify</h1>

<p align="center">
  <strong>Your personal media hub</strong><br>
  One app to browse, stream, and organize media from your own services — with a cinematic player built in
</p>

<p align="center">
  <a href="https://github.com/zongai/debrify/releases"><img src="https://img.shields.io/github/v/release/zongai/debrify?style=flat-square&color=6366f1" alt="Release"></a>
  <a href="https://github.com/zongai/debrify/stargazers"><img src="https://img.shields.io/github/stars/zongai/debrify?style=flat-square&color=f59e0b" alt="Stars"></a>
  <a href="https://github.com/zongai/debrify/releases"><img src="https://img.shields.io/github/downloads/zongai/debrify/total?style=flat-square&color=22c55e" alt="Downloads"></a>
  <img src="https://img.shields.io/badge/Flutter-3.44+-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-AGPL--3.0-blue?style=flat-square" alt="GNU AGPL v3"></a>
</p>

<p align="center">
  <a href="https://debrify.tv/"><strong>Website</strong></a> &bull;
  <a href="https://github.com/zongai/debrify/releases"><strong>Download</strong></a> &bull;
  <a href="#-features">Features</a> &bull;
  <a href="#-supported-platforms">Platforms</a> &bull;
  <a href="https://www.reddit.com/r/debrify/">Reddit</a> &bull;
  <a href="https://discord.gg/xuAc4Q2c9G">Discord</a>
</p>

---

## What is Debrify?

Debrify is an open-source, cross-platform **media hub**. It brings the services you already use — **Plex**, cloud storage (Real-Debrid, TorBox, Premiumize, PikPak, …), personal WebDAV servers, IPTV playlists, Stremio addon catalogs, YouTube — into one place, with a **built-in player** tuned for movies and TV, a **download manager**, **Trakt/Simkl/MDBList tracking**, and a **cinematic UI** that works on phone, desktop, or TV with a remote.

You connect your own accounts and sources. Debrify gives them one library, one player, and one interface everywhere.

This repository ([zongai/debrify](https://github.com/zongai/debrify)) is a fork of the upstream project with additional work on **Plex link login**, **IPTV multi-source playback**, and **Chinese / Japanese UI localization**. Upstream project: [varunsalian/debrify](https://github.com/varunsalian/debrify).

## Responsible Use

Debrify does not host, sell, provide, or bundle media content. Search sources, addons, indexers, WebDAV servers, IPTV playlists, and cloud accounts are user-configured integrations. Only use Debrify with content, services, and sources that you own, created, licensed, or are otherwise authorized to access.

Third-party plugins, addons, indexers, playlists, and services are controlled by their respective providers or users. Debrify does not endorse using any integration to infringe copyright or violate a provider's terms. Do not submit or distribute configurations intended to facilitate unauthorized access to copyrighted content.

For more detail, see [Content Responsibility](https://debrify.tv/content-responsibility/).

---

## ✨ Features

### 🎬 Built-in Player
A native player (media_kit/libmpv) designed for long-form viewing:
- Audio and subtitle track switching on the fly
- Subtitle search, autoload, styling, and a real-time sync slider
- Resume playback — picks up where you left off, even across sources and devices
- Episode guides, next-episode navigation, sleep timer, playback speed
- Gesture controls on mobile; fully remote-driven on TV

### ☁️ Your Cloud Services
Connect the storage and streaming-cache accounts you already pay for — Real-Debrid, Torbox, Premiumize, PikPak, and AllDebrid are all supported with full parity:
- Stream or download any file in your account
- Browse and manage your cloud library
- Account dashboard with status, expiration, and usage
- Playlists and episode tracking across every provider

### 🏠 Personal Servers

- **Plex** — sign in with [plex.tv/link](https://www.plex.tv/link/) (4-digit PIN); browse libraries from Discover / media server views
- WebDAV and other self-hosted endpoints you configure
- Watch-progress sync from media servers when available

### 🔎 Discovery & Catalogs
- **Stremio addons** — install addon catalogs, search across them, and play through your connected accounts
- **Catalog browsing** — poster grids, detail pages with ratings and Parents Guide, Watch Next recommendations
- **Quick Play** — long-press any poster to go straight into playback
- **Optional search plugins** — bring your own sources, including self-hosted Jackett and Prowlarr indexers

### 📡 Live & Lean-Back TV

- IPTV playlists (M3U / Xtream-style sources you configure)
- **Multi-source channels** — channels can list several stream URLs; pick a source manually in the player, or let Debrify **auto-failover** if a stream is too slow to start (about 3s, then 6s after a full cycle)
- Stremio TV–style lean-back catalogs and local TV channels

### 📈 Tracking
- **Trakt** — in-player scrobbling, a live Now Playing card, continue-watching rails, and an upcoming-episodes calendar
- **Simkl and MDBList** — sync progress and lists across services; local-only tracking works fully offline

### ⬇️ Download Manager
- Background queue with pause/resume and batch operations
- Save from any connected source — cloud accounts, WebDAV, YouTube
- Works on mobile and desktop, with scoped-folder support on Android

### ▶️ YouTube
- On-device search, no account or proxy required
- Resolution picker, endless scroll, downloads, and proper audio muxing into the built-in player

### 🔌 External Players
- Hand any stream to your preferred player app, including DeoVR for VR playback

### 🌐 Languages
- UI language: **English**, **中文 (Chinese)**, **日本語 (Japanese)** (Settings → Language / 语言)
- Phrase-based localization for settings, player, IPTV, downloads, and common dialogs
- Subtitle / audio track language preferences remain available in the player and related settings

---

## 📺 Android TV & Apple TV

A dedicated lean-back experience for the living room:

- **Cinematic UI** — poster grids, detail screens, and episode guides designed for big screens and low-end hardware
- **Remote-first** — full D-pad navigation everywhere, including an in-app keyboard with voice input
- **Quick Play** — long-press any card to start watching immediately
- **Subtitle tools** — search, offset sync, and full styling from the couch
- **Channel surfing** — IPTV EPG, quick guide, and instant zapping

---

## 📱 Supported Platforms

One codebase, full feature support across all platforms.

| Platform | Download | Notes |
|:---------|:---------|:------|
| **Android** | [APK](https://github.com/zongai/debrify/releases) | Phones and tablets |
| **Android TV** | [APK](https://github.com/zongai/debrify/releases) | Full D-pad navigation and remote support |
| **Windows** | [Installer](https://github.com/zongai/debrify/releases) | Windows 10/11 |
| **macOS** | [DMG](https://github.com/zongai/debrify/releases) | Intel and Apple Silicon |
| **Linux** | [AppImage](https://github.com/zongai/debrify/releases) | x86_64 and ARM64. Requires dependencies ([see install notes](#linux)) |
| **iOS** | [IPA](https://github.com/zongai/debrify/releases) | Unsigned — requires sideloading ([guide](docs/iOS-Installation.md)) |
| **Apple TV** | [IPA](https://github.com/zongai/debrify/releases) | Unsigned tvOS build — requires sideloading; ships with alpha releases |

---

## 🚀 Installation

### Android / Android TV
Download the APK from [Releases](https://github.com/zongai/debrify/releases)(https://github.com/zongai/debrify/releases) and install. On TV, use a file manager app like Downloader or install via ADB.

### Windows
Download the installer, run it, and launch from the Start Menu. First run may trigger SmartScreen — click "More info" → "Run anyway".

### macOS
Download the DMG, drag Debrify to Applications. First launch: right-click → Open (app is not notarized).

### Linux
```bash
# Install dependencies (required)
# Ubuntu 24.04+
sudo apt install libmpv2 libsqlite3-dev libfuse2

# Ubuntu 22.04 / Debian
sudo apt install libmpv1 libsqlite3-dev libfuse2

# Fedora
sudo dnf install mpv-libs sqlite-devel fuse-libs

# Arch
sudo pacman -S mpv sqlite fuse2

# Run the AppImage
chmod +x debrify-*.AppImage
./debrify-*.AppImage
```

### iOS
Download the unsigned IPA and sideload using **AltStore** or **Sideloadly**. See the [iOS Installation Guide](docs/iOS-Installation.md) for step-by-step instructions.

> **Note:** Sideloaded apps require re-signing every 7 days. AltStore can handle this automatically.

---

## ❤️ Support Debrify

Debrify is free, open source, and built by one person. If it has been useful to you, you can help fund development:

- [Sponsor on GitHub](https://github.com/sponsors/varunsalian)

Every bit helps keep the app improving.

---

## Before You Read the Code

A warning: this is not a clean codebase.

Debrify grew rapidly around features rather than a planned architecture. It contains enormous files, god classes, static state, duplicated provider logic, tightly coupled UI and business logic, inconsistent abstractions, legacy implementations, and more special cases than anyone should be proud of.

Some newer subsystems are better structured and heavily tested, but the repository as a whole does not represent Flutter best practices. It represents a product that kept growing while architectural cleanup repeatedly lost to the next feature or platform problem.

The application works and solves difficult problems, but maintaining it can be painful. Refactoring, simplification, and removal of legacy code are welcome.

## 🛠️ Building from Source

```bash
git clone https://github.com/zongai/debrify.git
cd debrify
# Active development for this fork often lives on feature/plex-integration
git checkout feature/plex-integration
flutter pub get
flutter run
```

**Build commands:**
```bash
flutter build apk --release              # Android
flutter build ios --release --no-codesign # iOS (unsigned)
flutter build windows --release          # Windows
flutter build macos --release            # macOS
flutter build linux --release            # Linux
```

### CI / Releases

GitHub Actions workflow **Build Release Artifacts** (`.github/workflows/build.yml`) can build Android, Windows, iOS, macOS, tvOS, and Linux.

- Manual runs: **Actions → Build Release Artifacts → Run workflow**
- Publishing a GitHub Release triggers a full multi-platform build and attaches artifacts to the release
- **Android release signing** needs repository secrets: `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`.  
  If `KEYSTORE_BASE64` is empty, manual (`workflow_dispatch`) builds fall back to **debug signing**; published **release** events still require a valid keystore.

---

## 🤝 Contributing

1. Fork the repo
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit changes: `git commit -am 'Add my feature'`
4. Push: `git push origin feature/my-feature`
5. Open a pull request

---

## 💬 Community

- **Reddit** — [r/debrify](https://www.reddit.com/r/debrify/) for discussion and tips
- **Discord** — [Join the server](https://discord.gg/xuAc4Q2c9G) for help and updates
- **Issues** — [Report bugs](https://github.com/zongai/debrify/issues) or request features

---

## 📄 License

Copyright © 2025–2026 Varun Salian and contributors.

Debrify's original source code is free software licensed under the [GNU Affero General Public License v3.0 only](LICENSE) (`AGPL-3.0-only`). If you distribute a modified or unmodified build, you must comply with the AGPL, including its corresponding-source requirements. Modified network-accessible versions must also offer their corresponding source to users.

Third-party components and assets remain under their respective licenses. The AGPL does not grant permission to use the Debrify name, logo, or other project branding for modified or unofficial distributions; see the [Trademark Policy](TRADEMARKS.md).

---

<p align="center">
  <a href="https://debrify.tv/">
    <img src="https://img.shields.io/badge/Visit_Website-debrify.tv-6366f1?style=for-the-badge" alt="Website">
  </a>
</p>

<p align="center">
  <sub>Made with Flutter. Free and open-source software.</sub>
</p>
