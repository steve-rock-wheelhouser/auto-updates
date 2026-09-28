# Bash completion for auto-updates

_auto_updates() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    commands="status set-mode mode enable disable run check set-time set-day set-reboot logs help version"
    options="-s --status --security --all --weekly-all --all-weekly --reboot -e --enable -d --disable -r --run -c --check -l --logs -h --help -v --version"

    case "$prev" in
        set-mode|mode)
            COMPREPLY=( $(compgen -W "security all weekly-all all-weekly daily-all" -- "$cur") )
            return 0
            ;;
        set-reboot|reboot|--reboot)
            COMPREPLY=( $(compgen -W "never when-needed when-changed" -- "$cur") )
            return 0
            ;;
        run|-r|--run)
            COMPREPLY=( $(compgen -W "--security --all --no-sleep" -- "$cur") )
            return 0
            ;;
        set-day|day)
            COMPREPLY=( $(compgen -W "Sun Mon Tue Wed Thu Fri Sat" -- "$cur") )
            return 0
            ;;
        logs|log|-l|--logs)
            COMPREPLY=( $(compgen -W "10 20 50 100" -- "$cur") )
            return 0
            ;;
        *)
            ;;
    esac

    if [[ "$cur" == -* ]]; then
        COMPREPLY=( $(compgen -W "$options" -- "$cur") )
    else
        COMPREPLY=( $(compgen -W "$commands $options" -- "$cur") )
    fi
}

complete -F _auto_updates auto-updates
