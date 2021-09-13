#!/usr/bin/env fish

function fish_user_key_bindings
    if type -q fzf && type -q fzf_key_bindings
        fzf_key_bindings
    else
        echo "⚠ Failed to initialize 'fzf' key bindings."
    end
end
