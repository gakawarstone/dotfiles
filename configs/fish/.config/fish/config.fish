set -x PATH /home/gws/.local/bin $PATH
set -x PATH /home/gws/.cargo/bin $PATH
set -x PATH /home/gws/.npm-global/bin $PATH
set -x PATH /home/gws/.bun/bin $PATH

set fish_greeting

export EDITOR=nvim

alias c clear
alias n nvim
alias py python3
alias xo xdg-open
alias lg lazygit
alias wgu "sudo wg-quick up wg0"
alias wgd "sudo wg-quick down wg0"
alias clip "xclip -selection clipboard"

function a
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end

source $HOME/.env.fish
zoxide init fish | source

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# starship
starship init fish | source
