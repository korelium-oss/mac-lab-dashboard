# mac-lab-dashboard

A desktop app for managing a Mac lab. It's the GUI version of [labctl](https://github.com/korelium-oss/labctl) — same functionality, but point-and-click instead of terminal commands.

Built with Flutter (for the macOS app) and FastAPI (for the backend that talks to labctl).

---

## Why I made this

I was already deep into Flutter and Dart, and they were the perfect fit for this. I needed to build a native macOS desktop app, and I wanted one clean codebase that compiles to a fast, native binary. Flutter allowed me to do that without having to write separate native Swift code or package a heavy Electron app.

When labctl was working well in the terminal, I kept thinking — there are people in labs who will never use a terminal. Lab assistants, non-technical staff, people who just need to reboot 33 machines and go home. They shouldn't need to learn Fish shell to do that.

So I started building a proper UI for it. The backend uses FastAPI to interface with the Fish commands, and the Flutter app wraps it all in a desktop UI.

It's working. The dashboard works, power controls work, user management works. But there's still a lot to finish — some bindings are incomplete, some pages need polish. I haven't had the time to get it all the way there.

If you're a Flutter developer and you want to contribute, honestly that would mean a lot. Someone somewhere is managing a lab and needs this as a finished app, not a half-done side project. If you help finish it, that person gets a tool they actually need.

---

## How it works

```
Flutter App  -->  FastAPI Backend  -->  labctl (Fish shell)  -->  Lab Macs via SSH
```

The Flutter app sends requests to a local FastAPI server. The server translates them into Fish shell commands. labctl then SSHs into the lab Macs and runs the actual commands.

---

## What you can do

- See live online/offline status of all machines
- Reboot, shutdown, or sleep individual machines or all at once
- Create and delete user accounts (with secure home wipe)
- Install apps via Homebrew — watch the install progress live
- Enable or disable auto-login across the lab
- View any student's screen or push your screen to all students for a presentation

---

## Requirements

1. [labctl](https://github.com/korelium-oss/labctl) installed and configured on your Mac
2. Fish Shell (`brew install fish`)
3. Python 3.9 or newer
4. Flutter 3.x (only needed if you're building from source)
5. All lab Macs reachable over SSH (see labctl setup)

---

## Quick start

### 1. Clone the repo

```bash
git clone https://github.com/korelium-oss/mac-lab-dashboard.git
cd mac-lab-dashboard
```

### 2. Start the backend

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```

### 3. Run the Flutter app

```bash
cd app
flutter pub get
cd macos && pod install && cd ..
flutter run -d macos
```

---

## Project structure

```
mac-lab-dashboard/
├── backend/
│   ├── main.py             # FastAPI server
│   └── requirements.txt
└── app/
    └── lib/
        ├── main.dart
        ├── screens/
        │   ├── dashboard_page.dart
        │   ├── multi_install_page.dart
        │   └── settings_page.dart
        └── services/
            ├── api_service.dart
            └── config_service.dart
```

---

## Common questions

**Do I need a static IP for the lab Macs?**
No. It uses mDNS (`.local` hostnames) so any network setup works.

**Can someone who doesn't know terminals use this?**
Yes, that's the whole point. The dashboard is click-based.

**How many machines can it handle?**
Tested with 33 Macs. The SSH commands run in parallel so 100+ should be fine.

**Does it need internet?**
No. Everything runs on your local network.

---

## License

MIT License. See [LICENSE](LICENSE) for details.
