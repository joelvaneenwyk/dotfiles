# Docker for Windows Troubleshooting

I've been successfully using Docker for years and then it just stopped working some days ago. One potential issue was that I ran out of hard-drive space at one point but have recovered since.

- Now have plenty of hard-drive space.
- Uninstalled and removed all files from here:
  - `C:\ProgramData\Docker`
  - `%USERPROFILE%\AppData\Roaming\Docker`
  - `%USERPROFILE%\AppData\Roaming\DockerDesktop`
  - `%USERPROFILE%\AppData\Local\Docker`
  - `%USERPROFILE%\.docker`
- Reinstalled and same issue.

---

## Additional Troubleshooting Steps

### 1. Check Docker Desktop Status
- Is Docker Desktop running? Look for the whale icon in the system tray.
- Right-click the icon and check for errors or restart options.

### 2. Restart Docker and Your Computer
- Try quitting Docker Desktop and restarting it.
- If that fails, reboot your computer.

### 3. Check Windows Features
- Ensure that **Hyper-V** and **Containers** Windows features are enabled (required for Windows containers).
- For WSL 2 backend, ensure **Windows Subsystem for Linux** and **Virtual Machine Platform** are enabled.

### 4. Check WSL 2 Integration (if using WSL 2)
- Run `wsl --list --verbose` to check your distributions and their WSL version.
- Make sure your default WSL version is set to 2: `wsl --set-default-version 2`.
- In Docker Desktop, go to Settings → Resources → WSL Integration and ensure your distro is enabled.

### 5. Free Up Disk Space
- Docker images, containers, and volumes can consume a lot of space. Run:
  - `docker system df` to see usage.
  - `docker system prune -a` to remove unused data (be careful, this deletes stopped containers and unused images).

### 6. Reset Docker to Factory Defaults
- In Docker Desktop, go to Settings → Troubleshoot → Reset to factory defaults.

### 7. Check for Updates
- Make sure you are running the latest version of Docker Desktop.
- Check for Windows updates as well.

### 8. Examine Logs
- Docker Desktop: Settings → Troubleshoot → "Get Support" to access logs.
- Check `%APPDATA%\Docker` and `%APPDATA%\DockerDesktop\log.txt` for errors.

### 9. Check Network and Proxy Settings
- VPNs, firewalls, or proxies can interfere with Docker networking.
- Try disabling VPN/firewall temporarily to test.
- In Docker Desktop, check Settings → Resources → Network.

### 10. Verify Virtualization Support
- Ensure virtualization is enabled in your BIOS/UEFI.
- Run `systeminfo` in Command Prompt and look for "Virtualization Enabled In Firmware: Yes".

### 11. Remove WSL 2 VM (if stuck)
- Sometimes the WSL 2 VM can get corrupted. You can remove it (this deletes all WSL 2 data!):
  - `wsl --shutdown`
  - Delete `%USERPROFILE%\AppData\Local\Docker\wsl` and `%USERPROFILE%\AppData\Local\Packages\Canonical*` (for Ubuntu, adjust for your distro).

### 12. Run Diagnostic Tools
- Docker Desktop: Settings → Troubleshoot → Run Diagnostics.

### 13. Common Error Messages
- **"Docker daemon not running"**: Try restarting Docker Desktop and your PC.
- **"WSL 2 installation is incomplete"**: Reinstall WSL 2 and ensure your kernel is up to date.
- **"Cannot connect to the Docker daemon"**: Check if the service is running and your user is in the `docker-users` group.

---

## Useful Links
- [Docker Desktop Troubleshooting Guide](https://docs.docker.com/desktop/troubleshoot/overview/)
- [Docker for Windows GitHub Issues](https://github.com/docker/for-win/issues)
- [Docker System Prune Docs](https://docs.docker.com/engine/reference/commandline/system_prune/)
