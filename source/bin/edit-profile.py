import subprocess
import sys
import threading
import time
from pathlib import Path

import win32con
import win32gui
import win32process
from watchdog.events import FileSystemEventHandler
from watchdog.observers import Observer

# ── config ─────────────────────────────────────────────
ROOT = Path(__file__).resolve().parent.parent
SCRIPT = (ROOT / "windows" / "bin" / "profile.bat").resolve()
TITLE = "DEV-LOOP"  # unique window title
CMD = ["cmd.exe", "/d", "/k", f'echo hi & call {SCRIPT} & echo done']
DEBOUNCE_MS = 300  # close‑delay to reduce flicker
# ───────────────────────────────────────────────────────


def _find_hwnd(pid):
    hwnd = None

    def cb(h, _):
        nonlocal hwnd
        if win32gui.IsWindowVisible(h):
            _, p = win32process.GetWindowThreadProcessId(h)
            if p == pid and TITLE in win32gui.GetWindowText(h):
                hwnd = h

    win32gui.EnumWindows(cb, None)
    return hwnd


def _get_rect(hwnd):
    l, t, r, b = win32gui.GetWindowRect(hwnd)
    return l, t, r - l, b - t


def _move(hwnd, x, y, w, h):
    win32gui.MoveWindow(hwnd, x, y, w, h, True)


def _close(hwnd):
    win32gui.PostMessage(hwnd, win32con.WM_CLOSE, 0, 0)


# --- launch & manage terminal -------------------------
class TerminalSession:
    def __init__(self):
        self.proc = None
        self.hwnd = None
        self.rect = None

    def launch(self):
        # Spawn CMD in a **new console window** even if this script was launched from one
        self.proc = subprocess.Popen(
            CMD,
            creationflags=subprocess.CREATE_NEW_CONSOLE,
        )
        # Discover the new window handle
        for _ in range(50):  # ~1 s
            time.sleep(0.02)
            self.hwnd = _find_hwnd(self.proc.pid)
            if self.hwnd:
                break
        # Restore previous placement
        if self.hwnd and self.rect:
            _move(self.hwnd, *self.rect)

    def close(self):
        if self.hwnd:
            _close(self.hwnd)

    def store_rect(self):
        if self.hwnd:
            self.rect = _get_rect(self.hwnd)


# --- file‑watcher -------------------------------------
class Handler(FileSystemEventHandler):
    def __init__(self, session):
        super().__init__()
        self.session = session

    def on_modified(self, event):
        if event.src_path != str(SCRIPT):
            return
        old = self.session
        self.session = TerminalSession()
        self.session.rect = old.rect  # restore placement
        self.session.launch()
        threading.Timer(DEBOUNCE_MS / 1000, old.close).start()
        threading.Timer(DEBOUNCE_MS / 1000, self.session.store_rect).start()


if __name__ == "__main__":
    if not SCRIPT.exists():
        sys.exit(f"{SCRIPT} not found")
    first = TerminalSession()
    first.launch()
    first.store_rect()

    obs = Observer()
    obs.schedule(Handler(first), SCRIPT.parent, recursive=False)
    obs.start()
    print(f"Watching {SCRIPT} – Ctrl+C to stop")
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        obs.stop()
    obs.join()
    first.close()
