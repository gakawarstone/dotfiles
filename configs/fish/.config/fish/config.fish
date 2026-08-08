set -x PATH /home/gws/.local/bin $PATH
set -x PATH /home/gws/.cargo/bin $PATH
set -x PATH /home/gws/.npm-global/bin $PATH
set -x PATH /home/gws/.bun/bin $PATH
set -x PATH /home/gws/.dotnet/tools $PATH

set fish_greeting

export EDITOR=nvim
set -gx PI_SKIP_VERSION_CHECK 1
set -gx PI_TELEMETRY 0

alias c clear
alias n nvim
alias py python3
alias xo xdg-open
alias lg lazygit
alias oo opencode
alias cluna "codex --model gpt-5.6-luna -c model_reasoning_effort=xhigh"
alias csol "codex --model gpt-5.6-sol -c model_reasoning_effort=medium"
alias wgu "sudo wg-quick up wg0"
alias wgd "sudo wg-quick down wg0"
alias clip "xclip -selection clipboard"
alias cat bat

function a
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end

if test -f $HOME/.env.fish
    source $HOME/.env.fish
end
zoxide init fish | source

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# starship
starship init fish | source
set -gx PATH $HOME/.npm-global/bin $PATH
