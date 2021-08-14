#!/usr/bin/env bash
#
# When bash is invoked as an interactive login shell, or as a non-
# interactive shell with the --login option, it first reads and
# executes commands from the file /etc/profile, if that file exists.
# After reading that file, it looks for ~/.bash_profile, ~/.bash_login,
# and ~/.profile, in that order, and reads and executes commands from
# the first one that exists and is readable.
#

if [ -f "$HOME/.profile" ]; then
    . "$HOME/.profile"
else
    # If running bash
    if [ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi
