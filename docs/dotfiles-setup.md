# Dotfiles Setup Guide

This guide will help you set up your development environment on a new machine using these dotfiles. Follow the instructions for your platform below.

---

## Windows

1. **Install Git for Windows**
   - Download from [git-scm.com](https://git-scm.com/download/win)
2. **Clone the dotfiles repository**
   - Open Command Prompt or PowerShell:
     ```powershell
     git clone -c core.symlinks=true --recursive https://github.com/joelvaneenwyk/dotfiles.git "%USERPROFILE%\.dotfiles"
     cd $env:USERPROFILE\.dotfiles
     .\init
     ```
3. **(Optional) Set up GPG for commit signing**
   - Download and install [Gpg4win - Kleopatra](https://www.gpg4win.org/index.html)
   - Import your secret key from a secure location (e.g., cloud storage)
4. **(Optional) Windows Terminal**
   - Import the provided Windows Terminal profile for a better shell experience.
5. **Troubleshooting**
   - If PowerShell setup fails due to OneDrive, see [this Stack Overflow answer](https://stackoverflow.com/a/67531193).

---

## macOS

1. **Install Git** (if not already installed)
   - Run `git --version` in Terminal. If missing, install via [Homebrew](https://brew.sh/) or Xcode Command Line Tools.
2. **Clone the dotfiles repository**
   ```bash
   git -C "$HOME" clone --recursive https://github.com/joelvaneenwyk/dotfiles.git
   cd ~/dotfiles
   ./init-osx.sh
   ```
3. **(Optional) Install Homebrew**
   - [Homebrew](https://brew.sh/) is recommended for managing packages on macOS.
4. **(Optional) Set up GPG for commit signing**
   - Use GPG Suite or Homebrew’s `gpg` package.

---

## Linux

1. **Install Git**
   - Use your distro’s package manager, e.g.:
     - `sudo apt-get install git` (Debian/Ubuntu)
     - `sudo pacman -S git` (Arch)
2. **Clone the dotfiles repository**
   ```bash
   git -C "$HOME" clone --recursive https://github.com/joelvaneenwyk/dotfiles.git
   cd ~/dotfiles
   ```
3. **Install bash settings**
   ```bash
   stow --adopt bash
   sudo stow bash -t /root
   ```
4. **(Optional) Install Xmonad configs**
   ```bash
   stow xmonad
   ```
5. **(Optional) Set up GPG for commit signing**
   - Install `gpg` via your package manager and import your key.

---

## Universal Quick Install (Bash platforms)

You can use the following one-liner to bootstrap on any bash-compatible system:

```bash
curl -sL git.io/mycelio | bash
```

---

## Additional Resources

- [https://bit.ly/joelvaneenwyk](https://bit.ly/joelvaneenwyk)
- [https://bit.ly/mycelio](https://bit.ly/mycelio)
