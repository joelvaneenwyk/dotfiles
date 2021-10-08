#!/usr/bin/env fish

# Suppress fish greeting
set -x fish_greeting ""

#
# Update paths
#

if test -d $HOME/.local/bin
    set -gx PATH $HOME/.local/bin $PATH
end

if test -d $HOME/anaconda3/bin
    set -gx PATH $HOME/anaconda3/bin $PATH
end

if test -d $HOME/.config/git-fuzzy
    set -gx PATH $HOME/.config/git-fuzzy/bin $PATH
end

set -gx PATH ./node_modules/.bin $PATH

# Color STDERR in red
set -e LD_PRELOAD

# Use java 1.8 by default if it exists
if test -d /usr/libexec/java_home
    set -gx JAVA_HOME (/usr/libexec/java_home -v 1.8)
end

# It should already be installed by './init.sh' but just in case we do it here
# as well.
if not functions -q fundle
    eval (curl -sfL https://git.io/fundle-install)
end

fundle plugin fisherman/getopts
fundle plugin fisherman/fzf
fundle plugin fisherman/z
fundle init

# aliases
alias more="less -r"
alias less="less -r"
alias ll="ls -l"
alias grep="grep --color=always"
alias pr="hub -c core.commentChar='%' pull-request"
alias rg="rg --smart-case"

# configure fzf
set -gx FZF_FIND_FILE_COMMAND "fd --type f . \$dir"
set -gx FZF_CTRL_T_COMMAND "fd --type f . \$dir"

# use exa if available
if type -q exa
    alias ls="exa --git --time-style=iso"
    alias lt="ll --tree"
else
    switch (uname)
    case Darwin
        echo "Pro tip: brew install exa"
    case '*'
        ;
    end
end

# use hub if available
if type -q hub
    alias git="hub"
else
    switch (uname)
    case Darwin
        echo "Pro tip: brew install hub"
    case '*'
        ;
    end
end

# set editor
if type -q nvim
    alias vi="nvim"
    alias vim="nvim"

    set -gx EDITOR /usr/local/bin/nvim
else
    set -gx EDITOR /usr/bin/vim

    switch (uname)
    case Darwin
        echo "Pro tip: brew install neovim"
    case '*'
        ;
    end
end

# set color scheme
set profile_helper $HOME/.config/base16-shell/profile_helper.fish
if status --is-interactive && test -e $profile_helper
    source $profile_helper
end

if test -e "$HOME/.base16_theme"
    set theme_shell (readlink -f "$HOME/.base16_theme")
    if test -e "$theme_shell"
        set theme (echo $HOME/.config/base16-fzf/fish/(basename "$theme_shell" .sh).fish)
    else
        echo "❌ Theme target does not exist: '$theme_shell'"
    end
else
    echo "❌ Missing base theme link: '.base16_theme'"
end

if test -e $theme
    source $theme
    echo "✔ Theme: '$theme'"
else
    echo "❌ Theme not found: '$theme'"
end

if test -d $HOME/anaconda3/bin
    set -gx PATH $HOME/anaconda3/bin $PATH
end

set -x FZF_DEFAULT_OPTS (echo $FZF_DEFAULT_OPTS | tr -d '\n')

# enable activating anaconda environments
if type -q conda
    source (conda info --root)/etc/fish/conf.d/conda.fish
end

if test -d $HOME/.asdf/bin
    set -gx PATH $HOME/.asdf/bin $PATH
end

# Enable asdf for managing runtimes.
if type -q asdf
    if test -e $HOME/.asdf/asdf.fish
        source $HOME/.asdf/asdf.fish
    else
        if test -e /usr/local/opt/asdf/asdf.fish
            source /usr/local/opt/asdf/asdf.fish
        end
    end
end
