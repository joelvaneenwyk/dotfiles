import logging
import subprocess
import sys
import threading
import time
from pathlib import Path

import win32con
import win32gui
import win32process
from watchdog.events import FileSystemEvent, FileSystemEventHandler
from watchdog.observers import Observer

# Setup logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

# ── config ─────────────────────────────────────────────
# ── config ─────────────────────────────────────────────
ROOT: Path = Path(__file__).resolve().parent.parent
SCRIPT: Path = (ROOT / "windows" / "bin" / "profile.bat").resolve()
WINDOW_TITLE: str = "DEV-LOOP"  # unique window title
CMD_ARGS: list[str] = ["cmd.exe", "/d", "/k", f"echo hi & call {SCRIPT} & echo done"]
DEBOUNCE_MS: int = 300  # close‑delay to reduce flicker
# ───────────────────────────────────────────────────────


import psutil


def find_window_handle(process_id: int) -> int:
    """Find the window handle (HWND) for the given process ID, window title, and process name.
    If not all criteria are met, try to find the best match and warn. Raise if no reasonable match is found.
    """
    found_info = []
    best_match = None
    best_score = 0

    def enum_callback(handle: int, _: int) -> None:
        if not win32gui.IsWindowVisible(handle):
            return

        _, pid = win32process.GetWindowThreadProcessId(handle)
        title = win32gui.GetWindowText(handle)
        try:
            proc = psutil.Process(pid)
            proc_name = proc.name()
        except Exception:
            proc_name = None
        score = 0
        if pid == process_id:
            score += 1
        if WINDOW_TITLE in title:
            score += 1
        if proc_name and proc_name.lower() == "cmd.exe":
            score += 1
        found_info.append((handle, pid, title, proc_name, score))
        logging.debug(
            f"Window: hwnd={handle}, pid={pid}, title='{title}', proc_name={proc_name}, score={score}"
        )
        nonlocal best_match, best_score
        if score > best_score:
            best_match = (handle, pid, title, proc_name, score)
            best_score = score

    win32gui.EnumWindows(enum_callback, 0)

    if best_match and best_score == 3:
        hwnd = best_match[0]
        left, top, width, height = get_window_rect(hwnd)
        logging.info(
            f"Selected window: hwnd={hwnd}, pid={process_id}, title='{best_match[2]}', proc_name={best_match[3]}, rect=({left},{top},{width},{height})"
        )
        return hwnd
    elif best_match and best_score >= 2:
        hwnd, pid, title, proc_name, score = best_match
        left, top, width, height = get_window_rect(hwnd)
        missing = []
        if pid != process_id:
            missing.append(f"pid (expected {process_id}, got {pid})")
        if WINDOW_TITLE not in title:
            missing.append(
                f"title (expected to contain '{WINDOW_TITLE}', got '{title}')"
            )
        if not (proc_name and proc_name.lower() == "cmd.exe"):
            missing.append(f"proc_name (expected 'cmd.exe', got '{proc_name}')")
        logging.warning(
            f"Selected window with partial match (score={score}/3, missing: {', '.join(missing)}): hwnd={hwnd}, pid={pid}, title='{title}', proc_name={proc_name}, rect=({left},{top},{width},{height})"
        )
        return hwnd
    # If not found, raise with details
    error_lines = [
        f"Could not find window for pid={process_id} with title containing '{WINDOW_TITLE}' and process name 'cmd.exe'. Windows found:",
    ]
    for handle, pid, title, proc_name, score in found_info:
        error_lines.append(
            f"  hwnd={handle}, pid={pid}, title='{title}', proc_name={proc_name}, score={score}"
        )
    if len(error_lines) == 1:
        error_lines.append("  (No windows found)")
    raise RuntimeError("\n".join(error_lines))


def get_window_rect(hwnd: int) -> tuple[int, int, int, int]:
    """Get the (left, top, width, height) of the window given its handle."""
    left, top, right, bottom = win32gui.GetWindowRect(hwnd)
    return left, top, right - left, bottom - top


def move_window(hwnd: int, x: int, y: int, width: int, height: int) -> None:
    """Move and resize the window to the specified position and size."""
    win32gui.MoveWindow(hwnd, x, y, width, height, True)


def close_window(hwnd: int) -> None:
    """Send a close message to the window with the given handle."""
    win32gui.PostMessage(hwnd, win32con.WM_CLOSE, 0, 0)


# --- launch & manage terminal -------------------------


class TerminalSession:
    """Manages a terminal session window for running the profile script, and relaunches if closed."""

    def __init__(self) -> None:
        """Initialize the terminal session."""
        self.process: subprocess.Popen | None = None
        self.window_handle: int | None = None
        self.window_rect: tuple[int, int, int, int] | None = None
        self._monitor_thread: threading.Thread | None = None
        self._rect_thread: threading.Thread | None = None
        self._stop_monitor: threading.Event = threading.Event()
        self._stop_rect: threading.Event = threading.Event()

    def launch(self) -> None:
        """Launch a new terminal window running the profile script and start monitoring it."""
        self._stop_monitor.clear()
        self._stop_rect.clear()
        self._launch_process()
        if self._monitor_thread is None or not self._monitor_thread.is_alive():
            self._monitor_thread = threading.Thread(
                target=self._monitor_process, daemon=True
            )
            self._monitor_thread.start()
        if self._rect_thread is None or not self._rect_thread.is_alive():
            self._rect_thread = threading.Thread(target=self._rect_poller, daemon=True)
            self._rect_thread.start()

    def _launch_process(self) -> None:
        """Internal: Launch the process and restore window position."""
        self.process = subprocess.Popen(
            CMD_ARGS,
            creationflags=subprocess.CREATE_NEW_CONSOLE,
        )
        # Discover the new window handle
        for _ in range(50):  # ~1 s
            time.sleep(0.02)
            self.window_handle = find_window_handle(self.process.pid)
            if self.window_handle:
                break
        # Restore previous placement
        if self.window_handle and self.window_rect:
            move_window(self.window_handle, *self.window_rect)
        logging.info(
            "Launched terminal session (pid=%s, hwnd=%s)",
            getattr(self.process, "pid", None),
            self.window_handle,
        )

    def _rect_poller(self) -> None:
        """Poll the window position frequently and save the latest position, logging on change."""
        prev_rect: tuple[int, int, int, int] | None = None
        while not self._stop_rect.is_set():
            if self.window_handle:
                try:
                    current_rect = get_window_rect(self.window_handle)
                    if prev_rect is None or current_rect != prev_rect:
                        self.window_rect = current_rect
                        logging.info("Window rect updated: %s", self.window_rect)
                        prev_rect = current_rect
                except Exception as e:
                    logging.debug("Could not poll window rect: %s", e)
            time.sleep(0.5)

    def _monitor_process(self) -> None:
        """Monitor the process; if it exits, relaunch in the same place."""
        while not self._stop_monitor.is_set():
            if self.process is not None:
                ret = self.process.poll()
                if ret is not None:
                    logging.info(
                        "Terminal process exited (pid=%s), relaunching...",
                        getattr(self.process, "pid", None),
                    )
                    # window_rect is now always up to date
                    time.sleep(0.5)  # Small delay before relaunch
                    self._launch_process()
            time.sleep(1)

    def close(self) -> None:
        """Close the terminal window if it exists and stop monitoring."""
        self._stop_monitor.set()
        self._stop_rect.set()
        if self.window_handle:
            close_window(self.window_handle)
            logging.info("Closed terminal window (hwnd=%s)", self.window_handle)

    def store_rect(self) -> None:
        """Store the current window rectangle for later restoration."""
        if self.window_handle:
            self.window_rect = get_window_rect(self.window_handle)
            logging.info("Stored window rect: %s", self.window_rect)


# --- file‑watcher -------------------------------------


class ProfileScriptChangeHandler(FileSystemEventHandler):
    """Handles file system events for the profile script, restarting the terminal session on changes."""

    def __init__(self, session: TerminalSession) -> None:
        super().__init__()
        self.session: TerminalSession = session

    def on_modified(self, event: FileSystemEvent) -> None:
        """Restart the terminal session if the profile script is modified."""
        if event.src_path != str(SCRIPT):
            return
        previous_session = self.session
        self.session = TerminalSession()
        self.session.window_rect = previous_session.window_rect  # restore placement
        self.session.launch()
        threading.Timer(DEBOUNCE_MS / 1000, previous_session.close).start()
        threading.Timer(DEBOUNCE_MS / 1000, self.session.store_rect).start()
        logging.info("Profile script modified, restarted terminal session.")


if __name__ == "__main__":
    """Main entry point: launches the terminal session and watches for profile script changes."""
    if not SCRIPT.exists():
        logging.error("Profile script not found: %s", SCRIPT)
        sys.exit(f"{SCRIPT} not found")

    initial_session = TerminalSession()
    initial_session.launch()
    initial_session.store_rect()

    observer = Observer()
    observer.schedule(
        ProfileScriptChangeHandler(initial_session), SCRIPT.parent, recursive=False
    )
    observer.start()
    logging.info("Watching %s – Ctrl+C to stop", SCRIPT)
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
    initial_session.close()
