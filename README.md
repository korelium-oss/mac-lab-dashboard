<![CDATA[<div align="center">

# 🖥️ Mac Lab Dashboard

### Visual Control Center for Your Mac Lab

**A Flutter desktop app + FastAPI backend that gives you one-click control over your entire Mac lab.**

Point. Click. Done. No terminal needed.

---

Built by **Pownkumar A** — Founder of [Korelium](https://korelium.org)

*Last updated: May 6, 2026*

</div>

---

## 🤔 What is this?

This is the **GUI companion** to [labctl](https://github.com/iampownkumar/labctl) — the open-source Mac Lab CLI.

While labctl gives you powerful terminal commands, this project wraps everything into a beautiful Flutter desktop app so you (or your non-technical staff) can manage the lab with zero command-line knowledge.

### What's inside?

| Component | Tech | Purpose |
|---|---|---|
| `mac-lab-backend/` | Python + FastAPI | REST API that bridges the Flutter app to labctl Fish commands |
| `project_mac_lab/` | Flutter (macOS) | Native desktop app with dashboard, software installer, and settings |

---

## ✨ Features

### 🎛️ Dashboard — Lab at a Glance
- **Live status grid** — See all 33+ machines with Online/Offline indicators
- **One-click power controls** — Reboot, Shutdown, Sleep for individual or all machines
- **Machine selection** — Click to select specific machines, then apply actions to the selection

### 👤 User Management
- **Create User** dialog — Username, password (with visibility toggle), admin switch
- **Delete User** dialog — With secure home directory wipe warning
- Works on single machines or the entire lab simultaneously

### 📦 Software Installation
- **Multi-install page** — Select apps from a curated list and deploy to any machine
- **Homebrew-powered** — Install casks (GUI apps) and formulas (CLI tools)
- **Real-time streaming** — Watch installation progress live

### 🔐 Auto-Login Management
- Enable/disable automatic login with password prompt
- Lab-wide toggle with one click

### 👀 Screen Monitoring
- View any student's screen instantly via macOS Screen Sharing
- Push your screen to students for presentations

### ⚙️ Settings
- Configure backend URL
- Customize lab parameters

---

## 📋 Prerequisites

1. **[labctl](https://github.com/iampownkumar/labctl)** installed and configured on the Admin Mac
2. **Fish Shell** installed (`brew install fish`)
3. **Python 3.9+** installed
4. **Flutter 3.x** installed (for building the app from source)
5. All lab machines accessible via SSH (see labctl setup guide)

> [!IMPORTANT]
> **All lab machines must have the same admin username.** This is a requirement of labctl — it SSHs into every machine using the same username. Create this common account on every Mac during initial setup.

---

## 🚀 Quick Start

### Step 1: Clone the repo

```bash
git clone https://github.com/iampownkumar/mac-os-monitering.git
cd mac-os-monitering
```

### Step 2: Start the Backend

```bash
cd mac-lab-backend

# Create a Python virtual environment
python3 -m venv venv

# Activate it
source venv/bin/activate        # bash/zsh
source venv/bin/activate.fish   # fish

# Install dependencies
pip install -r requirements.txt

# Start the server
uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```

You should see:
```
INFO:     Uvicorn running on http://127.0.0.1:8000
INFO:     Started reloader process
INFO:     Application startup complete.
```

### Step 3: Build & Run the Flutter App

Open a **new terminal**:

```bash
cd project_mac_lab

# Get dependencies
flutter pub get

# Install CocoaPods dependencies (macOS)
cd macos && LANG=en_US.UTF-8 pod install && cd ..

# Run the app
flutter run -d macos
```

The Mac Lab Dashboard will launch! 🎉

---

## 🏗️ Architecture

```
mac-os-monitering/
├── mac-lab-backend/
│   ├── main.py              # FastAPI server — all API endpoints
│   ├── requirements.txt     # Python dependencies
│   └── venv/                # Virtual environment (local only, gitignored)
│
├── project_mac_lab/
│   └── lib/
│       ├── main.dart                    # App entry point + navigation
│       ├── screens/
│       │   ├── dashboard_page.dart      # Main dashboard — status grid + controls
│       │   ├── multi_install_page.dart  # Software deployment page
│       │   └── settings_page.dart       # Configuration page
│       └── services/
│           ├── api_service.dart         # HTTP client for backend communication
│           ├── brew_services.dart       # Homebrew service definitions
│           └── config_service.dart      # App configuration persistence
│
└── .gitignore
```

### How it works

```
┌─────────────────┐     HTTP/REST      ┌──────────────────┐     subprocess     ┌─────────────┐     SSH      ┌──────────┐
│  Flutter App     │ ───────────────▶  │  FastAPI Backend   │ ──────────────▶  │  Fish Shell   │ ─────────▶ │  Lab Macs  │
│  (macOS Desktop) │ ◀───────────────  │  (Python/Uvicorn)  │ ◀──────────────  │  (labctl)     │ ◀───────── │  (SSH)     │
└─────────────────┘     JSON           └──────────────────┘     stdout         └─────────────┘            └──────────┘
```

1. **Flutter app** sends REST requests to the backend
2. **FastAPI backend** translates requests into Fish shell commands
3. **Fish shell** (labctl) executes SSH commands on the target machines
4. **Results** flow back through the same chain

---

## 📡 API Endpoints

### Status
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/status` | Get online/offline status of all machines |

### Power
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/reboot/{host}` | Reboot a specific machine |
| `POST` | `/reboot-all` | Reboot all machines |
| `POST` | `/shutdown/{host}` | Shutdown a specific machine |
| `POST` | `/shutdown-all` | Shutdown all machines |

### User Management
| Method | Endpoint | Body | Description |
|---|---|---|---|
| `POST` | `/user/create/{host}` | `{username, password, admin}` | Create user on one machine |
| `POST` | `/user/create-all` | `{username, password, admin}` | Create user on all machines |
| `POST` | `/user/delete/{host}` | `{username}` | Delete user (secure wipe) |
| `POST` | `/user/delete-all` | `{username}` | Delete user from all machines |
| `GET` | `/user/list/{host}` | — | List users on a machine |
| `GET` | `/user/list-all` | — | List users on all machines |

### Auto-Login
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/autologin/on/{host}` | Enable auto-login |
| `POST` | `/autologin/off/{host}` | Disable auto-login |
| `POST` | `/autologin/on-all` | Enable lab-wide |
| `POST` | `/autologin/off-all` | Disable lab-wide |

### Software
| Method | Endpoint | Body | Description |
|---|---|---|---|
| `POST` | `/brew/install/{host}` | `{type, name}` | Install package on one machine |
| `POST` | `/brew/install-all` | `{type, name}` | Install on all machines |

### Screen
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/screen/monitor/{host}` | Open screen viewer for a machine |
| `POST` | `/screen/present` | Push admin screen to all students |
| `POST` | `/screen/stop-present` | Stop presentation mode |

---

## 🔧 Configuration

### Backend Port
The backend runs on `http://127.0.0.1:8000` by default. To change:

```bash
uvicorn main:app --host 0.0.0.0 --port 9000 --reload
```

### Flutter App — Backend URL
Go to **Settings** tab in the app and update the backend URL.

Or edit `lib/services/config_service.dart` directly.

---

## ❓ FAQ

### Do I need a static IP?
**No.** Everything runs on your local network using mDNS (`.local` hostnames). Your college/school doesn't need a static IP.

### Can non-technical staff use this?
**Yes.** The Flutter dashboard is designed so anyone can point and click. No terminal knowledge needed.

### How many machines can it handle?
Tested with **33 machines**. The parallel SSH architecture can theoretically handle 100+ machines.

### Does it work without internet?
**Yes.** Everything runs on your local network. Internet is only needed for initial setup (cloning repos, installing dependencies).

### Is it secure?
- All communication happens over SSH (encrypted)
- Passwords are base64-encoded during transport (not stored)
- User deletion uses macOS `-secure` flag for complete data wipe
- No data leaves your local network

---

## 📄 License

Copyright © 2026 **Pownkumar A** (Founder of Korelium)

This project is licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0)**.

You are free to:
- ✅ Use this software for personal and educational purposes
- ✅ Modify and distribute under the same license
- ✅ Use in your institution's Mac lab

You must:
- 📋 Include the original copyright notice
- 📋 Disclose your source code if you modify and distribute
- 📋 License derivatives under AGPL-3.0

You may NOT:
- ❌ Use this in a commercial product without permission
- ❌ Remove the copyright or attribution
- ❌ Offer this as a paid service without contacting the author

For commercial licensing inquiries, contact: **Pownkumar A** at [Korelium](https://korelium.org)

---

## 🚧 Status: Active Development

> [!NOTE]
> This project is under **active development**. I am testing new features in a live 33-machine Mac lab and adding capabilities as real-world problems arise.

### 📅 Roadmap

- [x] Power management (reboot, shutdown, sleep)
- [x] Live status monitoring (online/offline)
- [x] User management (create, delete, list)
- [x] Software deployment via Homebrew
- [x] Auto-login configuration
- [x] Screen monitoring & presentation mode
- [ ] Desktop notifications from dashboard
- [ ] System cleanup (remove exam files, reset machines)
- [ ] Batch software uninstall
- [ ] Machine health reports (disk space, memory)
- [ ] **🎯 Ultimate Goal: Single macOS app** — Download one `.app`, enter your username and hostnames, and manage your entire lab. No terminal setup needed. Just enable SSH on your Macs once, and you're done.

### 📸 Screenshots & Demo

Coming soon! I'll be recording a video walkthrough and adding screenshots of the dashboard in action with a live Mac lab.

---

## 🤝 Contributing

This project is open to contributions! Here's how you can help:

- 🐛 **Report bugs** — Found something broken? Open an issue
- 💡 **Request features** — Have an idea? I'd love to hear it
- 🔧 **Submit PRs** — Code contributions are welcome
- ⭐ **Star the repo** — It helps others discover this project

I'm actively developing and testing, so I'll do my best to review and integrate contributions quickly.

---

## 📝 Acknowledgments

This project was born out of necessity — managing a 33-machine Mac lab at a college with no budget for expensive MDM tools. Every feature exists because I faced that exact problem in real life.

If you're a Mac lab admin struggling with the same issues, this project is for you.

## 🔗 Related Projects

- **[labctl](https://github.com/iampownkumar/labctl)** — The CLI engine that powers this dashboard

---

<div align="center">

**Built with ❤️ for Mac Lab Admins everywhere**

*If this saves you time, give it a ⭐ on GitHub!*

</div>
