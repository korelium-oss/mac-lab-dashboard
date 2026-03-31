from fastapi import FastAPI, HTTPException
import subprocess, re, time, os, shlex, threading
from pydantic import BaseModel
from fastapi.responses import StreamingResponse


app = FastAPI()
FISH = "/opt/homebrew/bin/fish"


def _run_bg(cmd: list, timeout: int = 40):
    """Run a shell command in a background daemon thread with a hard timeout.
    Prevents zombie processes from stacking up when machines are offline."""
    def _run():
        try:
            subprocess.run(cmd, timeout=timeout, capture_output=True)
        except subprocess.TimeoutExpired:
            pass  # process killed automatically after timeout
        except Exception:
            pass
    threading.Thread(target=_run, daemon=True).start()

@app.get("/status")
def get_status():
    try:
        result = subprocess.run(
            [FISH, "-l", "-c", "mac-all status"],
            capture_output=True,
            text=True,
            timeout=55
        )
        out = result.stdout
    except subprocess.TimeoutExpired as e:
        out = e.stdout.decode("utf-8") if isinstance(e.stdout, bytes) else (e.stdout or "")
    except Exception:
        out = ""

    machines = {}
    for line in out.splitlines():
        clean = re.sub(r'\x1B\[[0-9;]*m', '', line).strip()
        if clean.startswith("mac-"):
            try:
                name, rest = clean.split(":", 1)
                machines[name.strip()] = "ONLINE" in rest
            except ValueError:
                pass
                
    # Admin PC is the host machine, always online
    machines["mac-022"] = True

    return {
        "machines": machines,
        "ts": time.time()
    }


@app.post("/reboot/{host}")
def reboot_host(host: str):
    mac_id = host.split("-")[-1] if "-" in host else host
    subprocess.run([FISH, "-l", "-c", f"mac {mac_id} reboot"])
    return {"ok": True}


@app.post("/shutdown/{host}")
def shutdown_host(host: str):
    mac_id = host.split("-")[-1] if "-" in host else host
    subprocess.run([FISH, "-l", "-c", f"mac {mac_id} down"])
    return {"ok": True}


@app.post("/reboot-all")
def reboot_all():
    subprocess.run([FISH, "-l", "-c", "mac-all reboot"])
    return {"ok": True}


@app.post("/shutdown-all")
def shutdown_all():
    subprocess.run([FISH, "-l", "-c", "mac-all down"])
    return {"ok": True}


@app.post("/sleep/{host}")
def sleep_host(host: str):
    mac_id = host.split("-")[-1] if "-" in host else host
    subprocess.run([FISH, "-l", "-c", f"mac {mac_id} sleep"])
    return {"ok": True}


@app.post("/sleep-all")
def sleep_all():
    subprocess.run([FISH, "-l", "-c", "mac-all sleep"])
    return {"ok": True}


@app.post("/wake/{host}")
def wake_host(host: str):
    mac_id = host.split("-")[-1] if "-" in host else host
    _run_bg([FISH, "-l", "-c", f"mac-wake {mac_id}"])
    return {"ok": True}


@app.post("/wake-all")
def wake_all():
    _run_bg([FISH, "-l", "-c", "mac-all-wake"])
    return {"ok": True}


class PkgRequest(BaseModel):
    type: str   # "cask" or "formula"
    name: str


@app.post("/pkg/remove/{id}")
def pkg_remove(id: int, req: PkgRequest):
    num = str(id).zfill(3)
    host = f"mac-{num}"
    cmd = f"mac-pkg-remove {id} {req.type} {req.name}"
    try:
        result = subprocess.run(
            [FISH, "-l", "-c", cmd],
            capture_output=True,
            text=True,
            timeout=300
        )
        return {
            "host": host,
            "ok": result.returncode == 0,
            "stdout": result.stdout,
            "stderr": result.stderr
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


class NotifyRequest(BaseModel):
    message: str


@app.post("/notify/{host}")
def notify_host(host: str, req: NotifyRequest):
    mac_id = host.split("-")[-1] if "-" in host else host
    msg = shlex.quote(req.message)
    _run_bg([FISH, "-l", "-c", f"mac-notify {mac_id} {msg}"])
    return {"ok": True}


@app.post("/notify-all")
def notify_all(req: NotifyRequest):
    msg = shlex.quote(req.message)
    _run_bg([FISH, "-l", "-c", f"mac-all-notify {msg}"])
    return {"ok": True}


@app.post("/alert/{host}")
def alert_host(host: str, req: NotifyRequest):
    mac_id = host.split("-")[-1] if "-" in host else host
    msg = shlex.quote(req.message)
    _run_bg([FISH, "-l", "-c", f"mac-alert {mac_id} {msg}"])
    return {"ok": True}


@app.post("/alert-all")
def alert_all(req: NotifyRequest):
    msg = shlex.quote(req.message)
    _run_bg([FISH, "-l", "-c", f"mac-all-alert {msg}"])
    return {"ok": True}


# ========================
# SCREEN SHARING API
# ========================

@app.post("/screen/setup/{host}")
def screen_setup(host: str):
    mac_id = host.split("-")[-1] if "-" in host else host
    _run_bg([FISH, "-l", "-c", f"mac-screen-setup {mac_id}"])
    return {"ok": True}

@app.post("/screen/setup-all")
def screen_setup_all():
    _run_bg([FISH, "-l", "-c", "mac-all-screen-setup"])
    return {"ok": True}

@app.post("/screen/monitor/{host}")
def screen_monitor(host: str):
    mac_id = host.split("-")[-1] if "-" in host else host
    # Runs natively on the Admin PC where the backend is hosted
    _run_bg([FISH, "-l", "-c", f"mac-monitor {mac_id}"])
    return {"ok": True}

@app.post("/screen/present/{host}")
def screen_present(host: str):
    mac_id = host.split("-")[-1] if "-" in host else host
    _run_bg([FISH, "-l", "-c", f"mac-present-host {mac_id}"])
    return {"ok": True}

@app.post("/screen/present-all")
def screen_present_all():
    _run_bg([FISH, "-l", "-c", "mac-present"])
    return {"ok": True}

@app.post("/screen/stop-present/{host}")
def screen_stop_present(host: str):
    mac_id = host.split("-")[-1] if "-" in host else host
    _run_bg([FISH, "-l", "-c", f"mac-stop-present-host {mac_id}"])
    return {"ok": True}

@app.post("/screen/stop-present-all")
def screen_stop_present_all():
    _run_bg([FISH, "-l", "-c", "mac-stop-present"])
    return {"ok": True}

@app.post("/emergency/kill")
def emergency_kill():
    """Kill all hanging SSH and brew processes across the lab."""
    subprocess.run([FISH, "-l", "-c", "mac-kill-all"], capture_output=True, timeout=10)
    return {"ok": True}


class BrewRequest(BaseModel):
    type: str   # "cask" or "formula"
    name: str   # "firefox", "iterm2", "visual-studio-code", etc.

@app.post("/brew/install/{id}")
def brew_install(id: int, req: BrewRequest):
    num = str(id).zfill(3)
    host = f"mac-{num}"

    cmd = f"mac-pkg {id} {req.type} {req.name}"

    try:
        result = subprocess.run(
            [FISH, "-l", "-c", cmd],
            capture_output=True,
            text=True,
            timeout=600
        )

        return {
            "host": host,
            "ok": result.returncode == 0,
            "stdout": result.stdout,
            "stderr": result.stderr
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))



RUNNING = {}

@app.get("/brew/install/{mac_id}/stream")
def brew_install_stream(mac_id: str, type: str, name: str):
    host = f"mac-{mac_id.zfill(3)}"

    cmd = [
        "ssh",
        "-o", "ConnectTimeout=6",
        "-o", "ConnectionAttempts=1",
        f"ritmaclab@{host}.local",
        f"HOMEBREW_NO_AUTO_UPDATE=1 /opt/homebrew/bin/brew install --{type} {name}"
    ]

    def stream():
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        )

        RUNNING[host] = process

        yield f"[{host}] Starting install: {name} ({type})\n"

        try:
            if process.stdout is not None:
                for line in process.stdout:
                    yield line
            else:
                # No stdout available; wait for process to finish and report
                rc = process.wait()
                RUNNING.pop(host, None)
                yield f"\n[{host}] ❌ No stdout available (rc={rc})\n"
                return
        except GeneratorExit:
            process.kill()
            yield f"\n[{host}] ⛔ Manually stopped\n"
            return

        rc = process.wait()
        RUNNING.pop(host, None)

        if rc == 0:
            yield f"\n[{host}] ✅ Completed\n"
        else:
            yield f"\n[{host}] ❌ Failed or timeout\n"

    return StreamingResponse(stream(), media_type="text/plain")

@app.post("/brew/stop/{mac_id}")
def stop_brew(mac_id: str):
    host = f"mac-{mac_id.zfill(3)}"
    proc = RUNNING.get(host)

    if proc and proc.poll() is None:
        proc.kill()
        return {"ok": True, "msg": f"{host} stopped"}
    return {"ok": False, "msg": "No running job"} 
