#!/usr/bin/env bash
# ==============================================================================
# Script: git-opencode-commit.sh
# Descripción: Genera un mensaje de commit con AI (opencode) y lo presenta en un
#              editor interactivo para aceptar, editar o cancelar.
#
# Flujo:  Enter = aceptar  |  Esc = cancelar  |  Ctrl+J = nueva línea  |  Ctrl+E = editor
# ==============================================================================

set -euo pipefail

# --- Forzar UTF-8 para que los acentos se muestren bien en editores externos ---
if locale -a 2>/dev/null | grep -qi 'en_US.utf.*8'; then
    export LANG="en_US.UTF-8"
    export LC_ALL="en_US.UTF-8"
else
    export LANG="${LANG:-C.UTF-8}"
    export LC_ALL="${LC_ALL:-C.UTF-8}"
fi

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

# --- 2. Validar autenticación de opencode (Pre-flight check) ---
styled_info "Verificando autenticación de OpenCode..."
set +e
OPENCODE_AUTH_OUT=$(opencode auth list 2>&1)
OPENCODE_AUTH_STATUS=$?
set -e

# Limpiar códigos de color ANSI para evitar falsos negativos
CLEAN_AUTH_OUT=$(echo "$OPENCODE_AUTH_OUT" | sed 's/\x1b\[[0-9;]*m//g')

# Comprobar si el código es error o si el reporte limpio contiene exactamente '0 credentials'
if [[ $OPENCODE_AUTH_STATUS -ne 0 ]] || [[ "$CLEAN_AUTH_OUT" =~ [[:space:]]0[[:space:]]+credentials ]]; then
    echo ""
    styled_err "ERROR DE AUTENTICACIÓN: No has iniciado sesión o no tienes credenciales en OpenCode."
    styled_info "Por favor, ejecuta 'opencode auth login' en tu terminal para iniciar sesión."
    exit 1
fi

# --- 3. Generar el mensaje con opencode ---
styled_header "⚡ Generando commit con OpenCode (AI)..."

set +e
DIFF=$(git diff --staged)
OUT_FILE=$(mktemp /tmp/opencode_out_XXXXXX)
ERR_FILE=$(mktemp /tmp/opencode_err_XXXXXX)

opencode run "Genera un mensaje de commit Conventional Commit en español para el siguiente diff. Devuelve ÚNICAMENTE el mensaje de commit crudo en una sola línea, sin formato markdown, sin bloques de código, sin comillas y sin explicaciones adicionales:

$DIFF" >"$OUT_FILE" 2>"$ERR_FILE"
OPENCODE_STATUS=$?

AI_MSG=$(cat "$OUT_FILE")
ERR_MSG=$(cat "$ERR_FILE")

rm -f "$OUT_FILE" "$ERR_FILE"
set -e

# Detectar si el texto contiene patrones de solicitud de inicio de sesión (cuando el status es 0 pero igual falló)
is_login_prompt() {
    local text="${1}"
    if [[ "$text" =~ "Authentication required" ]] || \
       [[ "$text" =~ "Please visit the URL" ]] || \
       [[ "$text" =~ "accounts.google.com" ]] || \
       [[ "$text" =~ "oauth2/auth" ]] || \
       [[ "$text" =~ "Enter authorization code" ]] || \
       [[ "$text" =~ "Please log in" ]] || \
       [[ "$text" =~ "Please sign in" ]]; then
        return 0
    fi
    return 1
}

# Detectar errores de autenticación genéricos cuando el comando falló (status != 0)
is_auth_error() {
    local text="${1,,}"
    if [[ "$text" =~ "auth" ]] || [[ "$text" =~ "login" ]] || [[ "$text" =~ "credential" ]] || \
       [[ "$text" =~ "token" ]] || [[ "$text" =~ "unauthorized" ]] || [[ "$text" =~ "permission" ]] || \
       [[ "$text" =~ "api-key" ]] || [[ "$text" =~ "api key" ]] || [[ "$text" =~ "sign in" ]] || \
       [[ "$text" =~ "signin" ]] || [[ "$text" =~ "sesión" ]] || [[ "$text" =~ "sesion" ]]; then
        return 0
    fi
    return 1
}

# Primero evaluar si la salida (aún con status 0) contiene un prompt de autenticación claro
if is_login_prompt "$AI_MSG"; then
    echo ""
    styled_err "ERROR DE AUTENTICACIÓN: No has iniciado sesión o no tienes credenciales válidas en OpenCode."
    styled_info "Por favor, inicia sesión en OpenCode o verifica tu configuración de autenticación."
    exit 1
fi

if [[ $OPENCODE_STATUS -ne 0 ]]; then
    echo ""
    if is_auth_error "$ERR_MSG" || is_auth_error "$AI_MSG"; then
        styled_err "ERROR DE AUTENTICACIÓN: No has iniciado sesión o no tienes credenciales válidas en OpenCode."
        styled_info "Por favor, inicia sesión en OpenCode o verifica tu configuración de autenticación."
    else
        styled_err "Fallo al generar el mensaje con opencode (Código de salida: $OPENCODE_STATUS)."
        if [[ -n "${ERR_MSG// /}" ]]; then
            styled_info "Detalle del error:\n$ERR_MSG"
        fi
    fi
    exit 1
fi

if [[ -z "${AI_MSG// /}" ]]; then
    styled_err "El mensaje generado por OpenCode está vacío."
    exit 1
fi

# --- 3. Presentar el editor interactivo ---
if $HAS_GUM; then
    # ── Flujo con gum: un solo paso ──
    styled_header "✏️  Revisa el mensaje — edítalo si quieres"
    styled_info "Enter → aceptar  •  Esc → cancelar  •  Ctrl+J → nueva línea  •  Ctrl+E → editor"
    echo ""

    set +e
    FINAL_MSG=$(gum write \
        --value "$AI_MSG" \
        --width 80 \
        --height 10 \
        --show-help \
        --show-line-numbers \
        --show-cursor-line \
        --header "  ✨ COMMIT MESSAGE" \
        --header.foreground "#a78bfa" \
        --placeholder "Escribe tu mensaje de commit..." \
        --placeholder.foreground "#6b7280" \
        --prompt.foreground "#7c3aed" \
        --cursor.foreground "#7c3aed" \
        --cursor-line.foreground "#e0e7ff" \
        --cursor-line-number.foreground "#a78bfa" \
        --line-number.foreground "#4b5563" \
        --base.foreground "#d1d5db" \
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
            MSG_FILE=$(mktemp /tmp/opencode_commit_XXXXXX)
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
