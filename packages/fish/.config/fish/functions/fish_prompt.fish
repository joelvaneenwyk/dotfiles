#!/usr/bin/env fish

function fish_prompt --description 'Write out the prompt'
    set -l last_status $status

    # Just calculate these once, to save a few cycles when displaying the prompt
    if not set -q __fish_prompt_host
        if test -n "$SSH_CONNECTION"
            set -g __fish_prompt_host (set_color $fish_color_user) "$USER" (set_color normal) @ (set_color $fish_color_host) (hostname|cut -d . -f 1) (set_color normal) ' '
        else
            set -g __fish_prompt_host ""
        end
    end

    if not set -q __fish_prompt_normal
        set -g __fish_prompt_normal (set_color normal)
    end

    if not set -q -g __fish_classic_git_functions_defined
        set -g __fish_classic_git_functions_defined

        function __fish_repaint_user --on-variable fish_color_user --description "Event handler, repaint when fish_color_user changes"
            if status --is-interactive
                set -e __fish_prompt_user
                commandline -f repaint ^/dev/null
            end
        end

        function __fish_repaint_host --on-variable fish_color_host --description "Event handler, repaint when fish_color_host changes"
            if status --is-interactive
                set -e __fish_prompt_host
                commandline -f repaint ^/dev/null
            end
        end

        function __fish_repaint_status --on-variable fish_color_status --description "Event handler; repaint when fish_color_status changes"
            if status --is-interactive
                set -e __fish_prompt_status
                commandline -f repaint ^/dev/null
            end
        end
    end

    set -l delim '>'

    switch $USER

        case root

            if not set -q __fish_prompt_cwd
                if set -q fish_color_cwd_root
                    set -g __fish_prompt_cwd (set_color $fish_color_cwd_root)
                else
                    set -g __fish_prompt_cwd (set_color $fish_color_cwd)
                end
            end

        case '*'

            if not set -q __fish_prompt_cwd
                set -g __fish_prompt_cwd (set_color $fish_color_cwd)
            end

    end

    set -l prompt_status
    if test $last_status -ne 0
        if not set -q __fish_prompt_status
            set -g __fish_prompt_status (set_color $fish_color_status)
        end
        set prompt_status "$__fish_prompt_status [$last_status]$__fish_prompt_normal"
    end

    echo -n -s "$__fish_prompt_host" "$__fish_prompt_cwd" (prompt_pwd) (__fish_git_prompt) "$__fish_prompt_normal" "$prompt_status" "$delim" ' '
end

if not set -q __prompt_initialized_2
    set -U fish_color_user -o green
    set -U fish_color_host -o cyan
    set -U fish_color_status red
    set -U __prompt_initialized_2
end
