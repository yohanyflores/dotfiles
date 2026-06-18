#!/usr/bin/env bash
# ==============================================================================
# Script: git-agy-commit.sh
# Descripción: Genera un mensaje de commit con AI (agy) y lo presenta en un
#              editor interactivo para aceptar, editar o cancelar.
#
# Flujo:  Enter = aceptar  |  Ctrl+C = cancelar  |  Edita libremente
# ==============================================================================

set -euo pipefail

# --- Helpers ---
HAS_GUM=false
command -v gum >/dev/null 2>&1 && HAS_GUM=true

styled_header() {
    if $HAS_GUM; then
        gum style \
            --foreground="#a78bfa" \
            --border="rounded" \
            --border-foreground="#7c3aed" \
            --padding="0 2" \
            --margin="1 0 0 0" \
            --bold \
            "$@"
    else
        echo -e "\n\e[35;1m  $*  \e[0m"
    fi
}

styled_info() {
    if $HAS_GUM; then
        gum style --foreground="#38bdf8" --italic " $*"
    else
        echo -e "\e[34m $*\e[0m"
    fi
}

styled_ok() {
    if $HAS_GUM; then
        gum style --foreground="#4ade80" --bold " ✔ $*"
    else
        echo -e "\e[32m ✔ $*\e[0m"
    fi
}

styled_warn() {
    if $HAS_GUM; then
        gum style --foreground="#fbbf24" --bold " ✖ $*"
    else
        echo -e "\e[33m ✖ $*\e[0m"
    fi
}

styled_err() {
    if $HAS_GUM; then
        gum style --foreground="#f87171" --bold " ✖ $*" >&2
    else
        echo -e "\e[31m ✖ $*\e[0m" >&2
    fi
}

# --- 1. Validar que existan cambios staged ---
if git diff --quiet --cached; then
    styled_err "No hay cambios en stage para hacer commit."
    exit 1
fi

# --- 2. Generar el mensaje con agy ---
styled_header "⚡ Generando commit con AI..."

set +e
AI_MSG=$(git diff --staged | agy --print "Genera un mensaje de commit conciso para estos cambios. Devuelve ÚNICAMENTE el mensaje de commit crudo, sin formato markdown, sin bloques de código, sin comillas y sin explicaciones adicionales. Sigue el formato de Conventional Commits en español." 2>/dev/null)
AGY_STATUS=$?
set -e

if [[ $AGY_STATUS -ne 0 ]] || [[ -z "${AI_MSG// /}" ]]; then
    styled_err "Fallo al generar el mensaje con agy."
    exit 1
fi

# --- 3. Presentar el editor interactivo ---
if $HAS_GUM; then
    # ── Flujo con gum: un solo paso ──
    styled_header "✏️  Revisa el mensaje — edítalo si quieres"
    styled_info "Enter → aceptar y hacer commit  •  Ctrl+C → cancelar"
    echo ""

    set +e
    FINAL_MSG=$(gum write \
        --value "$AI_MSG" \
        --width 80 \
        --height 10 \
        --placeholder "Escribe tu mensaje de commit..." \
        --char-limit 500 \
        --show-line-numbers \
        --header "  COMMIT MESSAGE" \
        --header.foreground="#a78bfa" \
        --header.bold \
        --cursor.foreground="#7c3aed" \
        --prompt.foreground="#7c3aed" \
    )
    GUM_EXIT=$?
    set -e

    if [[ $GUM_EXIT -ne 0 ]]; then
        echo ""
        styled_warn "Commit cancelado."
        exit 0
    fi
else
    # ── Flujo sin gum: mostrar + preguntar ──
    echo ""
    echo -e "\e[35;1m┌─ MENSAJE PROPUESTO ─────────────────────────────┐\e[0m"
    echo "$AI_MSG" | sed 's/^/\x1b[0m  │ /'
    echo -e "\e[35;1m└─────────────────────────────────────────────────┘\e[0m"
    echo ""
    echo -e "  \e[36m[a]\e[0m Aceptar   \e[36m[e]\e[0m Editar   \e[36m[c]\e[0m Cancelar"
    echo -n "  > "
    read -r OPT < /dev/tty

    case "${OPT,,}" in
        a|y|"")
            FINAL_MSG="$AI_MSG"
            ;;
        e)
            MSG_FILE=$(mktemp /tmp/agy_commit_XXXXXX)
            echo "$AI_MSG" > "$MSG_FILE"
            EDITOR_TO_USE="${VISUAL:-${EDITOR:-vim}}"
            "$EDITOR_TO_USE" "$MSG_FILE" < /dev/tty > /dev/tty
            FINAL_MSG=$(cat "$MSG_FILE")
            rm -f "$MSG_FILE"
            ;;
        *)
            styled_warn "Commit cancelado."
            exit 0
            ;;
    esac
fi

# --- 4. Validar y ejecutar el commit ---
FINAL_MSG=$(echo "$FINAL_MSG" | sed '/^[[:space:]]*$/d')

if [[ -z "${FINAL_MSG// /}" ]]; then
    styled_warn "Mensaje vacío. Commit abortado."
    exit 0
fi

git commit -m "$FINAL_MSG"

echo ""
styled_ok "Commit realizado con éxito"
