set -x PATH /home/gws/.local/bin $PATH
set -x PATH /home/gws/.cargo/bin $PATH
set -x PATH /home/gws/.npm-global/bin $PATH

function fish_greeting
end

function a
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end

zoxide init fish | source
