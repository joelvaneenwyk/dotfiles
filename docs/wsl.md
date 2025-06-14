
# Modern WSL Configuration & Changing the Default User

WSL (Windows Subsystem for Linux) is highly configurable. You can control many aspects of your Linux distributions, including the default user, mount options, networking, and more. This guide covers the most common and modern ways to manage your WSL setup.

## Changing the Default User for a Distribution

You can set the default user for a WSL distribution in two main ways:

### 1. Using the Distribution Executable

Each installed distribution has its own executable (e.g., `ubuntu.exe`, `debian.exe`). To set the default user:

```cmd
<DistributionName> config --default-user <Username>
```
Example for Ubuntu:
```cmd
ubuntu config --default-user myusername
```
If the distribution executable is not in your PATH, you can find it in:
```
C:\Users\<YourUser>\AppData\Local\Microsoft\WindowsApps\
```
Look for files like `Ubuntu.exe`, `Debian.exe`, etc.

### 2. Using wsl.conf (Recommended for Persistent Settings)

You can set the default user in the `/etc/wsl.conf` file inside your Linux distribution:

```ini
[user]
default = myusername
```
After editing `/etc/wsl.conf`, restart your distribution for changes to take effect. You can do this with:
```powershell
wsl --shutdown
```
or to terminate just one distribution:
```powershell
wsl --terminate <DistroName>
```

## Additional Modern WSL Tips

- **Check running distributions:**
  ```powershell
  wsl --list --running
  ```
- **Restart all WSL instances:**
  ```powershell
  wsl --shutdown
  ```
- **Find your installed distributions:**
  ```powershell
  wsl --list --verbose
  ```
- **Edit global WSL settings:**
  Create or edit `%UserProfile%\.wslconfig` for global settings (memory, CPUs, etc.).

## References

- [Microsoft Docs: wsl.conf](https://learn.microsoft.com/en-us/windows/wsl/wsl-config#wslconf)
- [Microsoft Docs: .wslconfig](https://learn.microsoft.com/en-us/windows/wsl/wsl-config#wslconfig)
- [Microsoft Docs: Change the default user](https://learn.microsoft.com/en-us/windows/wsl/wsl-config#change-the-default-user-for-a-distribution)
