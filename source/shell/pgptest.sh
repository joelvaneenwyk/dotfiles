#!/usr/bin/env sh

if _tty="$(tty)"; then
    export GPG_TTY="$_tty"
fi

pkill -9 gpg-agent
gpg-connect-agent reloadagent /bye
gpg-connect-agent updatestartuptty /bye
echo "test" | gpg --clearsign

echo "If the above fails, try 'sudo update-binfmts --disable cli' see https://github.com/microsoft/WSL/issues/8531"
