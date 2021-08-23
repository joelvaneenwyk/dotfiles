#!/usr/bin/env sh

if _tty="$(tty)"; then
    export GPG_TTY="$_tty"
fi

pkill -9 gpg-agent
gpg-connect-agent updatestartuptty /bye
echo "test" | gpg --clearsign
