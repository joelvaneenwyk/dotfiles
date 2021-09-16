# Portable Configuration

```ansi
      ██            ██     ████ ██  ██
     ░██           ░██    ░██░ ░░  ░██
     ░██  ██████  ██████ ██████ ██ ░██  █████   ██████
  ██████ ██░░░░██░░░██░ ░░░██░ ░██ ░██ ██░░░██ ██░░░░
 ██░░░██░██   ░██  ░██    ░██  ░██ ░██░███████░░█████
░██  ░██░██   ░██  ░██    ░██  ░██ ░██░██░░░░  ░░░░░██
░░██████░░██████   ░░██   ░██  ░██ ███░░██████ ██████
 ░░░░░░  ░░░░░░     ░░    ░░   ░░ ░░░  ░░░░░░ ░░░░░░


  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
 ░▓             ▓
 ░▓ about       ▓  custom config files
 ░▓ code        ▓  https://github.com/joelvaneenwyk/dotfiles
 ░▓ attribution ▓  derived from https://github.com/jdve/dotfiles
 ░▓             ▓
 ░▓▓▓▓▓▓▓▓▓▓▓▓▓▓
 ░░░░░░░░░░░░░░

 bash           > basic `bash` setup
 fish           > `fish` setup
 fonts          > favorite fonts
 linux          > shared profile setup
 macos          > special sauce for macOS / OSX
 windows        > helper scripts for Windows
 python         > flake8 config
 ruby           > default gems and `asdf` config
 sup            > sup mail client configs
 vim            > vim configs
 x11            > three-monitor x11 config
 xmonad         > x11 window manager configs
 zsh            > shell config for `zsh`
```

## Table of Contents

- [Portable Configuration](#portable-configuration)
  - [Table of Contents](#table-of-contents)
  - [Setup](#setup)
    - [Windows](#windows)
    - [macOS](#macos)
    - [Linux](#linux)
    - [Synology](#synology)
    - [Raspberry PI](#raspberry-pi)
    - [Secrets](#secrets)
  - [Introduction](#introduction)
  - [Management](#management)
  - [Installation](#installation)
  - [Implementation](#implementation)
  - [Details](#details)
    - [x11](#x11)
  - [Resources](#resources)

## Setup

Instructions are provided below for each platform, but the high level approach for each is to clone the `git` repository and then run the initialization script for that platform.

To install on platforms with `bash` you can do the following:

```bash
curl -sL git.io/mycelio | bash
```

This will clone the repository and run `setup.sh`.

This custom URL was created using the following command:

```bash
curl -i https://git.io -F "url=https://gist.githubusercontent.com/joelvaneenwyk/dfe24a255f77b2e14e67965391a3a8fe/raw/e05066832edc673c2e6d102888ff1f5be63b9a0e/dotclone.sh" -F "code=mycelio"
```

### Windows

1. Clone the repo from your home directory:
   > `git -C "$HOME" clone --recursive https://github.com/joelvaneenwyk/dotfiles.git`
2. Enter the `dotfiles` directory and then run `init`
3. To setup commit signing, download and install [Gpg4win - Kleopatra](https://www.gpg4win.org/index.html)
   - Import Secret Key from secure location e.g. `{cloud}\Documents\Keys`

NOTE: The PowerShell setup steps can fail if you have your PowerShell modules and settings stored in OneDrive or some other cloud provider. Please follow steps to migrate to local path, e.g. [How to prevent Powershell Modules being installed into OneDrive - Stack Overflow](https://stackoverflow.com/a/67531193)

### macOS

Most versions of MacOS will already have Git installed, and you can activate it through the terminal with git version. However, if you don't have Git installed for whatever reason, you can install the latest version of Git using one of [several methods](https://github.com/git-guides/install-git). Once installed, run the following:

1. Clone the repo from your home directory:
   > `git -C "$HOME" clone --recursive https://github.com/joelvaneenwyk/dotfiles.git`
2. `cd dotfiles && ./init-osx.sh`

### Linux

1. Clone the repo from your home directory:
   > `git -C "$HOME" clone --recursive https://github.com/joelvaneenwyk/dotfiles.git`
2. Install the bash settings.
   > `(cd dotfiles && stow --adopt bash)`
3. Install bash settings for the root user
   > `sudo stow bash -t /root`
4. Install [xmonad](https://xmonad.org/) configs
   > `stow xmonad`

### Synology

1. Update Synology to allow TCP port forwarding. Add the following to `/etc/ssh/sshd_config`.
    > `AllowTcpForwarding yes`
2. Restart SSH `sudo synoservicectl --restart sshd`
3. Clone the repo from your home directory:
   > `git -C "$HOME" clone --recursive https://github.com/joelvaneenwyk/dotfiles.git`
4. Initialize environment.
   > `./setup.sh`
5. Install bash settings for the root user
   > `sudo stow bash -t /root`

### Raspberry PI

1. Clone the repo from your home directory:
   > `git -C "$HOME" clone --recursive https://github.com/joelvaneenwyk/dotfiles.git`
2. Navigate to `dotfiles` project.
   > `cd dotfiles`
3. Initialize the environment.
   > `./setup.sh`

### Secrets

These are optional steps to setup SSH to sync to private GitHub repositories.

1. `ssh-keygen -t ed25519 -C "joel.vaneenwyk@gmail.com"`
   - **NOTE:** Some older systems do not support `Ed25519` algorithm. In those cases, use the following instead: `ssh-keygen -t rsa -b 4096 -C "joel.vaneenwyk@gmail.com"`
2. `eval "$(ssh-agent -s)"`
3. `ssh-add ~/.ssh/id_rsa`
4. `xclip -sel clip < ~/.ssh/id_rsa.pub`
   - WSL: `cat ~/.ssh/id_rsa.pub | /mnt/c/Windows/System32/clip.exe`
5. From [GitHub SSH and GPG keys](https://github.com/settings/keys), press **New SSH Key**
6. Paste in the key on the clipboard

If all worked, you should be able to clone one of your private repositories e.g. `git clone git@github.com:joelvaneenwyk/secrets.git`

## Introduction

In the unix world programs are commonly configured in two different ways, via shell arguments or text based configuration files. programs with many options like window managers or text editors are configured on a per-user basis with files in your home directory `~`. in unix like operating systems any file or directory name that starts with a period or full stop character is considered hidden, and in a default view will not be displayed. thus the name dotfiles.

It's been said of every console user:

> _"you are your dotfiles"_.

This is because these files dictate how the system will look, feel, and function. to many users (see [ricers](http://unixporn.net) and [beaners](http://nixers.net)) these files are very important, and need to be backed up and shared. people who create custom themes have the added challenge of managing multiple versions of them. i have tried many organization techniques. and just take my word for it when i say, keeping a git repo in the root of your home directory is a bad idea. i've written custom shell scripts for moving or symlinking files into place. there are even a few dotfile managers, but they all seem to have lots of dependencies. i knew there had to be a simple tool to help me.

## Management

This repository was designed to be used with [gnu stow](http://www.gnu.org/software/stow/), a free, portable, lightweight symlink farm manager. this allows me to keep a versioned directory of all my config files that are virtually linked into place via a single command. this makes sharing these files among many users (root) and computers super simple. and does not clutter your home directory with version control files.

## Installation

[Stow](https://www.gnu.org/software/stow/) is available for all linux and most other unix-like distributions via your favorite package manager.

- `sudo pacman -S --noconfirm --needed stow`
- `sudo apt-get -y install stow`
- `brew install stow`

or clone it [from source](https://savannah.gnu.org/git/?group=stow) and [build it](http://git.savannah.gnu.org/cgit/stow.git/tree/INSTALL) yourself.

## Implementation

By default, the `stow` command will create symlinks for files in the parent directory of where you execute the command. so my dotfiles setup assumes this repo is located in the root of your home directory `~/dotfiles`. and all stow commands should be executed in that directory. otherwise you'll need to use the `-d` flag with the repo directory location.

To install most of my configs you execute the stow command with the folder name as the only argument.

To install **bash** configs use the command:

```bash
stow bash
```

This will symlink files to `~/` and various other places. You can override the default behavior and symlink files to another location with the `-t` (target) argument flag.

**Note:** `stow` can only create a symlink if a config file does not already exist. If a default file was created upon program installation, you can add the `--adopt` flag which will delete the existing configuration settings before you install a new one with stow.

## Details

### x11

to install the **x11** config you need to execute the command:

```bash
stow -t / x11
```

This will symlink the files to `/etc/X11`.

## Resources

- [Stow](https://www.gnu.org/software/stow/manual/stow.html)
- [Inspiration - dotfiles.github.io](https://dotfiles.github.io/inspiration/)
- [dotfiles-windows: dotfiles for Windows, including Developer-minded system defaults. Built in PowerShell](https://github.com/jayharris/dotfiles-windows)
- [Scoop](https://scoop.sh/)
