# install plugins
if not functions -q fundle; eval (curl -sfL https://git.io/fundle-install); end

fundle plugin 'fisherman/getopts'
fundle plugin 'fisherman/fzf'
fundle plugin 'fisherman/z'
fundle plugin 'edc/bass'
fundle plugin 'orefalo/grc'
fundle plugin 'mattgreen/lucid.fish'
fundle plugin 'FabioAntunes/base16-fish-shell'
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

if test -d ./node_modules/bin
   set -gx PATH ./node_modules/.bin $PATH
end

if test -d /usr/local/opt/openssl@1.1/bin
   set -gx PATH /usr/local/opt/openssl@1.1/bin $PATH
end

if test -d /opt/local/bin
   set -gx PATH /opt/local/bin $PATH
end

if test -d $HOME/Library/Android/sdk/platform-tools
   set -gx PATH $HOME/Library/Android/sdk/platform-tools $PATH
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

if test -d /c/ProgramData/chocolatey/bin
    set -gx PATH /c/ProgramData/chocolatey/bin $PATH
end

set brew (brew --prefix)
set -gx LESSOPEN "|$brew/bin/lesspipe.sh %s"

# color stderr in red
if [ (uname) = "Darwin" ]
    set -gx LD_PRELOAD "$HOME/.local/lib/libstderred.so"
end

# use java 1.8 by default
if test -f /usr/libexec/java_home
    set -gx JAVA_HOME (/usr/libexec/java_home -v 1.8)
end

# set path to zk notebook
if test -d /c/Users/jdve/Documents/Notes/Zettelkasten
    set -gx ZK_NOTEBOOK_DIR /c/Users/jdve/Documents/Notes/Zettelkasten
end

if test -d "$HOME/Documents/Notes/Zettelkasten"
    set -gx ZK_NOTEBOOK_DIR "$HOME/Documents/Notes/Zettelkasten"
end

# aliases
alias more="less -r"
alias less="less -r"
alias ll="ls -l"
alias grep="grep --color=always"
alias pr="hub -c core.commentChar='%' pull-request"
alias rg="rg --smart-case"

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
base16-irblack

# configure fzf
if type -q fzf
    source $HOME/.config/base16-fzf/fish/base16-irblack.fish

    set -gx FZF_FIND_FILE_COMMAND "fd --type f . \$dir"
    set -gx FZF_CTRL_T_COMMAND "fd --type f . \$dir"
    set -gx FZF_DEFAULT_OPTS (echo $FZF_DEFAULT_OPTS | tr -d '\n')
else
    echo "Pro Tip: install fzf"
end

# enable activating anaconda environments
if type -q conda
    source (conda info --root)/etc/fish/conf.d/conda.fish
end

# enable asdf for managing runtimes.
if type -q asdf
    source /usr/local/opt/asdf/asdf.fish
end

# enable git commit signing
if type -q gpg
    git config --global commit.gpgsign true
else
    git config --global --unset commit.gpgsign
end

# install google cloud sdk
if test -d ~/Tools/google-cloud-sdk
    bass source ~/Tools/google-cloud-sdk/path.bash.inc
    bass source ~/Tools/google-cloud-sdk/completion.bash.inc
end

