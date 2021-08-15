#!/usr/bin/env sh

GPG_TTY=$(tty)
export GPG_TTY
pkill -9 gpg-agent
gpg-connect-agent updatestartuptty /bye
echo "test" | gpg --clearsign
