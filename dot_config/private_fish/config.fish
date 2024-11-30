if status is-interactive
    zoxide init fish | source
    fzf --fish | source
    # Commands to run in interactive sessions can go here
end

if status --is-login
    if test (tty) = /dev/tty1
        hyprland
    end
end
