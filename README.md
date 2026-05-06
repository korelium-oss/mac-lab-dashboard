<div align="center">

# Mac Lab Dashboard

**A Flutter desktop app + FastAPI backend for managing Mac labs over SSH.**

No MDM. No agents. No cloud. No monthly fees.

---

Pownkumar A (Founder of Korelium) · Last updated: May 6, 2026

</div>

---

## What is this?

This is the GUI companion to [labctl](https://github.com/iampownkumar/labctl) — a CLI tool for Mac lab management.

While labctl gives you powerful terminal commands, this project wraps everything into a Flutter desktop app so anyone can manage the lab without touching a terminal.

**What's inside:**

| Directory | Tech | Purpose |
|---|---|---|
| `backend/` | Python + FastAPI | REST API that bridges the Flutter app to labctl |
| `app/` | Flutter (macOS) | Native desktop app — dashboard, software installer, settings |

---

## Features

**Dashboard — Lab at a Glance**
- Live status grid showing all machines with Online/Offline indicators
- One-click power controls — Reboot, Shutdown, Sleep (individual or all)
- Machine selection — click specific machines, then apply actions to the selection

**User Management**
- Create User dialog with username, password (visibility toggle), and admin switch
- Delete User dialog with secure home directory wipe
- Works on single machines or the entire lab

**Software Installation**
- Multi-install page — select apps and deploy to any machine
- Homebrew-powered — install casks (GUI apps) and formulas (CLI tools)
- Real-time streaming — watch installation progress live

**Auto-Login Management**
- Enable/disable automatic login with password prompt
- Lab-wide toggle with one click

**Screen Monitoring**
- View any student's screen instantly via macOS Screen Sharing
- Push your screen to students for presentations

---

## Prerequisites

1. [labctl](https://github.com/iampownkumar/labctl) installed and configured on the Admin Mac
2. Fish Shell installed (`brew install fish`)
3. Python 3.9+
4. Flutter 3.x (for building from source)
5. All lab machines accessible via SSH (see labctl setup guide)

> **Important:** All lab machines must have the same admin username. This is a requirement of labctl — it SSHs into every machine using the same username. Create this common account on every Mac during initial setup.

---

## Quick Start

### 1. Clone the repo

```bash
git clone https://github.com/iampownkumar/mac-os-monitering.git mac-lab-dashboard
cd mac-lab-dashboard
```

### 2. Start the Backend

```bash
cd backend

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
INFO:     Application startup complete.
```

### 3. Build and Run the Flutter App

Open a new terminal:

```bash
cd app

# Get dependencies
flutter pub get

# Install CocoaPods (macOS)
cd macos && LANG=en_US.UTF-8 pod install && cd ..

# Run the app
flutter run -d macos
```

---

## Architecture

```
mac-lab-dashboard/
├── backend/
│   ├── main.py              # FastAPI server with all endpoints
│   ├── requirements.txt     # Python dependencies
│   └── venv/                # Local only, gitignored
│
├── app/
│   └── lib/
│       ├── main.dart                    # Entry point + navigation
│       ├── screens/
│       │   ├── dashboard_page.dart      # Status grid + controls
│       │   ├── multi_install_page.dart  # Software deployment
│       │   └── settings_page.dart       # Configuration
│       └── services/
│           ├── api_service.dart         # HTTP client
│           ├── brew_services.dart       # Homebrew definitions
│           └── config_service.dart      # App config persistence
│
├── LICENSE
├── README.md
└── .gitignore
```

**How it works:**

```
Flutter App  ──HTTP/REST──▶  FastAPI Backend  ──subprocess──▶  Fish Shell (labctl)  ──SSH──▶  Lab Macs
```

1. Flutter app sends REST requests to the backend
2. FastAPI translates requests into Fish shell commands
3. Fish (labctl) executes SSH commands on target machines
4. Results flow back through the same chain

---

## API Endpoints

### Status
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/status` | Online/offline status of all machines |

### Power
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/reboot/{host}` | Reboot a machine |
| `POST` | `/reboot-all` | Reboot all machines |
| `POST` | `/shutdown/{host}` | Shutdown a machine |
| `POST` | `/shutdown-all` | Shutdown all machines |

### User Management
| Method | Endpoint | Body | Description |
|---|---|---|---|
| `POST` | `/user/create/{host}` | `{username, password, admin}` | Create user on one machine |
| `POST` | `/user/create-all` | `{username, password, admin}` | Create user on all machines |
| `POST` | `/user/delete/{host}` | `{username}` | Delete user (secure wipe) |
| `POST` | `/user/delete-all` | `{username}` | Delete from all machines |
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
| `POST` | `/brew/install/{host}` | `{type, name}` | Install package |
| `POST` | `/brew/install-all` | `{type, name}` | Install on all machines |

### Screen
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/screen/monitor/{host}` | Open screen viewer |
| `POST` | `/screen/present` | Push admin screen to students |
| `POST` | `/screen/stop-present` | Stop presentation mode |

---

## FAQ

**Do I need a static IP?**
No. Everything runs on your local network using mDNS (`.local` hostnames).

**Can non-technical staff use this?**
Yes. The Flutter dashboard is point-and-click. No terminal knowledge needed.

**How many machines can it handle?**
Tested with 33 machines. The parallel SSH architecture can handle 100+.

**Does it work without internet?**
Yes. Everything runs on your local network. Internet is only needed for initial setup.

**Is it secure?**
All communication happens over SSH (encrypted). Passwords are base64-encoded during transport. User deletion uses macOS `-secure` flag for complete data wipe. No data leaves your network.

---

## Status: Active Development

This project is under active development. I am testing new features in a live 33-machine Mac lab and adding capabilities as real-world problems arise.

### Roadmap

- [x] Power management (reboot, shutdown, sleep)
- [x] Live status monitoring (online/offline)
- [x] User management (create, delete, list)
- [x] Software deployment via Homebrew
- [x] Auto-login configuration
- [x] Screen monitoring and presentation mode
- [ ] Desktop notifications from dashboard
- [ ] System cleanup (remove exam files, reset machines)
- [ ] Batch software uninstall
- [ ] Machine health reports (disk space, memory)
- [ ] **Ultimate Goal: Single macOS app** — Download one `.app`, enter your username and hostnames, and you're done. No terminal setup. Just enable SSH on your Macs once.

### Screenshots and Demo

Coming soon. I'll be recording a video walkthrough and adding screenshots of the dashboard in action with a live lab.

---

## Contributing

This project is open to contributions:

- **Report bugs** — Found something broken? Open an issue
- **Request features** — Have an idea? I'd love to hear it
- **Submit PRs** — Code contributions are welcome
- **Star the repo** — It helps others discover this project

I'm actively developing and testing, so I'll do my best to review contributions quickly.

---

## Acknowledgments

This project was born out of necessity — managing a 33-machine Mac lab at a college with no budget for expensive MDM tools. Every feature exists because I faced that exact problem in real life.

If you're a Mac lab admin struggling with the same issues, this project is for you.

---

## License

Copyright 2026 Pownkumar A (Founder of Korelium)

Licensed under the GNU Affero General Public License v3.0 (AGPL-3.0). See [LICENSE](LICENSE) for details.

For commercial licensing inquiries, contact Pownkumar A at [Korelium](https://korelium.org).

---

## Related Projects

- [labctl](https://github.com/iampownkumar/labctl) — The CLI engine that powers this dashboard

