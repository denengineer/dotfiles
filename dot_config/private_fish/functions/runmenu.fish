function runmenu
    foot --app-id=tmodal_s fish -c "set -U runmenuCmd (pacman -Qtel | rg --pcre2 'bin/(?!(?i)hypr|grub|btrfs|fsck|mkfs|cliphist|chezmoi|foot|hwsim)(.*)' -or '\$1' | sed '/^\$/d' | fzf)"
    echo $runmenuCmd
    if test -n "$runmenuCmd"
        $runmenuCmd
    end
end
