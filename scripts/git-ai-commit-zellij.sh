#!/usr/bin/env bash

set -u

SELF="$(readlink -f "${BASH_SOURCE[0]}")"

# Esta rama se ejecuta dentro del panel flotante.
if [[ "${1:-}" == "--inside-pane" ]]; then
    git-ai-commit
    status=$?

    if ((status != 0)); then
        printf '\nEl comando terminó con código %d.\n' "$status"
        printf 'Presiona Enter para cerrar...'
        IFS= read -r _
    fi

    exit "$status"
fi

# Desde Zellij, vuelve a llamar este wrapper dentro de un panel flotante.
if [[ -n "${ZELLIJ:-}" ]]; then
    exec zellij run \
        --floating \
        --close-on-exit \
        --block-until-exit \
        --cwd "$PWD" \
        --name "Commit con IA" \
        --width "90%" \
        --height "85%" \
        -- "$SELF" --inside-pane
fi

# Fuera de Zellij funciona como el comando normal.
exec git-ai-commit
