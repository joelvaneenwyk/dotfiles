#!/usr/bin/env python
"""
Remove empty directories.
"""

import os
import time
import sys

DRY_RUN = '--dry' in sys.argv
CLOUD_PAUSE_SECONDS = 10
CLOUD_MAX_FILES = 20


def _breadth_first_path_scanner(root):
    dirs = [root]
    output = []

    if os.path.isdir(root):
        print("Scanning: '%s'" % root)

    # while we has dirs to scan
    while len(dirs):
        nextDirs = []

        for parent in dirs:
            # scan each dir
            try:
                items = os.listdir(parent)
            except OSError:
                items = []

            for path_entry in items:
                try:
                    full_path = os.path.join(parent, path_entry)
                    if os.path.isdir(full_path):
                        nextDirs.append(full_path)
                except OSError:
                    pass

        if not nextDirs and dirs:
            output.extend(dirs)

        for dd in nextDirs:
            output.insert(0, dd)

        # No go over the next set of child directories
        dirs = nextDirs

    for output_entry in output:
        try:
            for filename in os.listdir(output_entry):
                yield os.path.join(output_entry, filename)
        except OSError:
            pass
        yield output_entry


def _get_delete():
    start = [0, 0]

    def _track_delete(path):
        start[1] += 1

        if 'OneDrive' in path:
            start[0] += 1

        if start[0] > CLOUD_MAX_FILES:
            print("Pausing delete for '%d' seconds to let cloud synchronize..." % CLOUD_PAUSE_SECONDS)
            time.sleep(CLOUD_PAUSE_SECONDS)
            start[0] = 0

        if start[1] % 1000 == 0:
            print("Scanned '%d' path entries so far..." % start[1])

    def _delete_inner(item_path, force):
        try:
            remove = ''

            if os.path.isfile(item_path):
                filename, _ = os.path.splitext(item_path)
                if filename.endswith(' - Copy') and 'OneDrive' in item_path:
                    remove = 'duplicate file'
                elif force:
                    remove = 'file'
            elif os.path.isdir(item_path):
                dir_files = os.listdir(item_path)
                if not dir_files:
                    remove = 'empty directory'
                elif force:
                    remove = 'directory'

            if remove:
                _track_delete(item_path)
                if DRY_RUN:
                    print("Scheduled to remove %s: '%s'" % (remove, item_path))
                else:
                    if os.path.isfile(item_path):
                        os.remove(item_path)
                    elif os.path.isdir(item_path):
                        os.rmdir(item_path)

                    if os.path.exists(item_path):
                        print("Failed to remove %s: '%s'" % (remove, item_path))
                    else:
                        print("Removed %s: '%s'" % (remove, item_path))
        except OSError as exception:
            print("Failed to remove item: '%s'" % item_path)
            print(exception)

    return _delete_inner


def _clean_path(root, force=False, parent=None):
    if not os.path.exists(root):
        print("Skipped remove on non-existent path: '%s'" % root)
        return 0

    total = 0
    root = os.path.abspath(os.path.normpath(root))
    _delete = _get_delete()

    if os.path.isdir(root):
        try:
            items = [os.path.join(root, x) for x in os.listdir(root)]
        except OSError:
            items = []

        directories = [os.path.isdir(item) for item in items]
        if items and (len(root) < 10 or len(directories) > 10 or len(directories) < 2):
            for item in items:
                if os.path.basename(item) not in {'$RECYCLE.BIN', 'System Volume Information'}:
                    total += _clean_path(item, force, parent=root)
        else:
            for path_item in _breadth_first_path_scanner(root):
                total += 1
                _delete(path_item, force)
    elif os.path.isfile(root):
        total += 1
        _delete(root, force)

    if total > 1000 or parent is None:
        print("  > Scanned '%d' path entries in path: '%s'" % (total, root))

    return total


def _get_drives():
    drives = []

    try:
        import win32api  # type: ignore
        drives_string = win32api.GetLogicalDriveStrings()
        drives = drives_string.split('\000')[:-1]
    except (ImportError, OSError):
        from ctypes import windll  # type: ignore
        bit_mask = windll.kernel32.GetLogicalDrives()
        for letter in range(0, ord('Z') - ord('A')):
            if bit_mask & 1:
                drives.append(chr(ord('A') + letter))
            bit_mask >>= 1

    windowsDrive = os.environ.get('WinDir', None)
    windowsDriveLetter = '' if not windowsDrive else windowsDrive[0].lower()
    if not windowsDrive:
        drives = []
    else:
        drives = [
            '%s:\\' % drive
            for drive in drives
            if drive[:1].lower() != windowsDriveLetter
        ]

    return drives

def main():
    """
    Entrypoint for removing unused or empty directories.
    """

    home = os.path.expanduser("~")
    drives = _get_drives()

    total = 0
    total += _clean_path(os.path.join(home, "OneDrive - Microsoft", "Archive", "MobaXterm", "slash"), True)
    total += _clean_path(os.path.join(home, "OneDrive - Microsoft"))

    for drive in drives:
        total += _clean_path(drive)

    print("Scanned '%d' path entries." % total)

    return 0


if __name__=='__main__':
    sys.exit(main())
