# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

# add extra things to the PATH
if [ -d "$HOME/.local/bin" ]; then
   PATH="$HOME/.local/bin:$PATH"
fi

if [ -d "$HOME/.local/sbin" ]; then
   PATH="$HOME/.local/sbin:$PATH"
fi

# set some defaults
export EDITOR="vim"
export PAGER="less -r"

# added by Anaconda3 5.0.1 installer
export PATH="/Users/jvaneenwyk/anaconda3/bin:$PATH"
