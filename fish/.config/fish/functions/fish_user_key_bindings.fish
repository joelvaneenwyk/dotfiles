#!/usr/bin/env fish

function fish_user_key_bindings
    if type -q fzf
        fzf_key_bindings
    end
end
