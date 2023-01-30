if test -e ~/.local/bin/fig
    eval (~/.local/bin/fig init fish pre --rcfile 00_fig_pre | string split0)
end
