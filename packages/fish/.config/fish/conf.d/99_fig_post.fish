if test -e $~/.local/bin/fig
    eval (~/.local/bin/fig init fish post --rcfile 99_fig_post | string split0)
end
