# install plugins
if not functions -q fundle; eval (curl -sfL https://git.io/fundle-install); end

fundle plugin 'fisherman/getopts'
fundle plugin 'fisherman/fzf'
fundle plugin 'fisherman/z'
fundle plugin 'edc/bass'
fundle plugin 'orefalo/grc'
fundle plugin 'mattgreen/lucid.fish'
fundle init

# suppress fish greeting
set -x fish_greeting ""

# update path
if test -d $HOME/.local/bin
    set -gx PATH $HOME/.local/bin $PATH
end

if test -d $HOME/anaconda3/bin
    set -gx PATH $HOME/anaconda3/bin $PATH
end

if test -d $HOME/.config/git-fuzzy
    set -gx PATH $HOME/.config/git-fuzzy/bin $PATH
end

if test -d ./node_modules/.bin
    set -gx PATH ./node_modules/.bin $PATH
end

if test -d /usr/local/opt/openssl@1.1/bin
    set -gx PATH /usr/local/opt/openssl@1.1/bin $PATH
end

if test -d /c/tools/nvim-win64/bin
    set -gx PATH /c/tools/nvim-win64/bin $PATH
end

if test -d /c/Users/jdve/AppData/Local/Android/Sdk/platform-tools
    set -gx PATH /c/Users/jdve/AppData/Local/Android/Sdk/platform-tools $PATH
end

# color stderr in red
if [ (uname) = "Darwin" ]
    set -gx LD_PRELOAD "$HOME/.local/lib/libstderred.so"
end

# use java 1.8 by default
if test -f /usr/libexec/java_home
    set -gx JAVA_HOME (/usr/libexec/java_home -v 1.8)
end

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
    echo "Pro Tip: install exa"
end

# use hub if available
if type -q hub
    alias git="hub"
else
    echo "Pro Tip: install hub"
end

# set editor
if type -q nvim
    alias vi="nvim"
    alias vim="nvim"

    set -gx EDITOR (which nvim)
else
    set -gx EDITOR (which vim)

    echo "Pro Tip: install neovim"
end

# set color scheme
if status --is-interactive
    source $HOME/.config/base16-shell/profile_helper.fish
end

# configure fzf
if type -q fzf
    source $HOME/.config/base16-fzf/fish/(basename (readlink $HOME/(readlink $HOME/.base16_theme)) .sh).fish
    set -x FZF_DEFAULT_OPTS (echo $FZF_DEFAULT_OPTS | tr -d '\n')
else
    echo "Pro Tip: install fzf"
end

# enable activating anaconda environments
if type -q conda
    source (conda info --root)/etc/fish/conf.d/conda.fish
end

# Enable asdf for managing runtimes.
if type -q asdf
    source /usr/local/opt/asdf/asdf.fish
end

# install google cloud sdk
if test -d ~/Tools/google-cloud-sdk
    bass source ~/Tools/google-cloud-sdk/path.bash.inc
    bass source ~/Tools/google-cloud-sdk/completion.bash.inc
end

