#!/usr/bin/env bash
# Configura el CLI y el modelo usados por git-ai-commit.

set -euo pipefail

CONFIG_FILE="${GIT_AI_COMMIT_CONFIG:-${XDG_CONFIG_HOME:-${HOME}/.config}/git-ai-commit/config.json}"
HAS_GUM=false
command -v gum >/dev/null 2>&1 && HAS_GUM=true

info() {
    if $HAS_GUM; then
        gum style --foreground="#38bdf8" --italic " $*"
    else
        printf '\033[34m %s\033[0m\n' "$*"
    fi
}

ok() {
    if $HAS_GUM; then
        gum style --foreground="#4ade80" --bold " ✔ $*"
    else
        printf '\033[32m ✔ %s\033[0m\n' "$*"
    fi
}

warn() {
    if $HAS_GUM; then
        gum style --foreground="#fbbf24" --bold " ✖ $*"
    else
        printf '\033[33m ✖ %s\033[0m\n' "$*"
    fi
}

err() {
    if $HAS_GUM; then
        gum style --foreground="#f87171" --bold " ✖ $*" >&2
    else
        printf '\033[31m ✖ %s\033[0m\n' "$*" >&2
    fi
}

header() {
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
        printf '\n\033[35;1m  %s  \033[0m\n' "$*"
    fi
}

choose_value() {
    local prompt="$1"
    local preferred="$2"
    shift 2
    local -a values=("$@")
    local selected=""

    if $HAS_GUM; then
        local -a gum_args=(
            --height 15
            --header "$prompt"
            --cursor.foreground "#7c3aed"
            --selected.foreground "#a78bfa"
        )
        if [[ -n "$preferred" ]] && printf '%s\n' "${values[@]}" | grep -qxF "$preferred"; then
            gum_args+=(--selected "$preferred")
        fi
        set +e
        selected=$(printf '%s\n' "${values[@]}" | gum choose "${gum_args[@]}")
        local status=$?
        set -e
        [[ $status -eq 0 && -n "$selected" ]] || return 1
        printf '%s' "$selected"
        return 0
    fi

    printf '%s\n' "$prompt" >/dev/tty
    local i
    for i in "${!values[@]}"; do
        printf '  %d) %s\n' "$((i + 1))" "${values[$i]}" >/dev/tty
    done
    printf '  > ' >/dev/tty
    local option
    read -r option </dev/tty || return 1
    [[ "$option" =~ ^[0-9]+$ ]] || return 1
    ((option >= 1 && option <= ${#values[@]})) || return 1
    printf '%s' "${values[$((option - 1))]}"
}

input_value() {
    local prompt="$1"
    local initial="${2:-}"
    if $HAS_GUM; then
        gum input --prompt "$prompt: " --value "$initial" --width 60
    else
        printf '%s [%s]: ' "$prompt" "$initial" >/dev/tty
        local value
        read -r value </dev/tty || return 1
        printf '%s' "${value:-$initial}"
    fi
}

auth_status() {
    local cli="$1"
    case "$cli" in
        codex)
            if command -v timeout >/dev/null 2>&1; then
                timeout -k 2s 15s codex login status </dev/null >/dev/null 2>&1
            else
                codex login status </dev/null >/dev/null 2>&1
            fi
            ;;
        claude)
            if command -v timeout >/dev/null 2>&1; then
                timeout -k 2s 15s claude auth status </dev/null >/dev/null 2>&1
            else
                claude auth status </dev/null >/dev/null 2>&1
            fi
            ;;
        opencode)
            local output status
            set +e
            if command -v timeout >/dev/null 2>&1; then
                output=$(timeout -k 2s 15s opencode auth list </dev/null 2>&1)
                status=$?
            else
                output=$(opencode auth list </dev/null 2>&1)
                status=$?
            fi
            set -e
            output=$(printf '%s' "$output" | sed 's/\x1b\[[0-9;]*m//g')
            [[ $status -eq 0 && ! "$output" =~ [[:space:]]0[[:space:]]+credentials ]]
            ;;
        *)
            return 1
            ;;
    esac
}

wait_for_auth() {
    local cli="$1"
    local attempt
    for attempt in 1 2 3 4 5 6; do
        if auth_status "$cli"; then
            return 0
        fi
        if ((attempt < 6)); then
            sleep 1
        fi
    done
    return 1
}

authenticate() {
    local cli="$1"
    if auth_status "$cli"; then
        ok "$cli ya está autenticado."
        return 0
    fi

    info "$cli requiere autenticación; se abrirá su flujo oficial de inicio de sesión."
    if [[ ! -r /dev/tty || ! -w /dev/tty ]]; then
        err "No hay una terminal interactiva disponible para autenticar $cli."
        info "Ejecuta git-ai-commit-config directamente desde una terminal."
        return 1
    fi
    case "$cli" in
        codex) codex login </dev/tty >/dev/tty 2>&1 ;;
        claude) claude auth login --claudeai </dev/tty >/dev/tty 2>&1 ;;
        opencode) opencode auth login </dev/tty >/dev/tty 2>&1 ;;
    esac

    info "Confirmando la autenticación de $cli..."
    if ! wait_for_auth "$cli"; then
        err "No se pudo confirmar la autenticación de $cli."
        return 1
    fi
    ok "Autenticación de $cli confirmada."
}

select_model() {
    local cli="$1"
    local preferred="$2"
    local selected=""
    local -a models=()

    case "$cli" in
        opencode)
            info "Consultando modelos disponibles en OpenCode..." >&2
            local output
            if ! output=$(opencode models 2>&1); then
                err "OpenCode no pudo obtener su lista de modelos."
                printf '%s\n' "$output" >&2
                return 1
            fi
            mapfile -t models < <(
                printf '%s\n' "$output" |
                    sed 's/\r$//' |
                    grep -E '^[^[:space:]]+/[^[:space:]]+$' |
                    sort -u
            )
            ;;
        codex)
            models=(default)
            local cache="${CODEX_HOME:-${HOME}/.codex}/models_cache.json"
            if [[ -r "$cache" ]]; then
                mapfile -t models < <(
                    {
                        printf '%s\n' default
                        jq -r '.models[]? | .slug // empty' "$cache" 2>/dev/null
                    } | awk 'NF && !seen[$0]++'
                )
            fi
            models+=("otro modelo...")
            ;;
        claude)
            models=(default sonnet opus haiku fable "otro modelo...")
            ;;
    esac

    if ((${#models[@]} == 0)); then
        err "$cli no devolvió ningún modelo disponible."
        return 1
    fi

    if [[ -z "$preferred" ]]; then
        preferred=default
    fi
    selected=$(choose_value "Selecciona el modelo de $cli" "$preferred" "${models[@]}") || {
        warn "Configuración cancelada."
        return 1
    }

    if [[ "$selected" == "otro modelo..." ]]; then
        selected=$(input_value "Identificador del modelo" "") || return 1
        if [[ -z "${selected// /}" ]]; then
            err "El identificador del modelo no puede estar vacío."
            return 1
        fi
    elif [[ "$selected" == default ]]; then
        selected=""
    fi

    printf '%s' "$selected"
}

command -v jq >/dev/null 2>&1 || {
    err "Se requiere jq para guardar y validar la configuración."
    exit 1
}

current_cli=""
current_model=""
if [[ -r "$CONFIG_FILE" ]] && jq -e '.version == 1' "$CONFIG_FILE" >/dev/null 2>&1; then
    current_cli=$(jq -r '.cli // empty' "$CONFIG_FILE")
    current_model=$(jq -r '.model // empty' "$CONFIG_FILE")
fi

available_clis=()
for candidate in codex claude opencode; do
    command -v "$candidate" >/dev/null 2>&1 && available_clis+=("$candidate")
done

if ((${#available_clis[@]} == 0)); then
    err "No se encontró ninguno de los CLI compatibles: codex, claude u opencode."
    exit 1
fi

header "🤖 Configurar commits con IA"
cli=$(choose_value "Selecciona el CLI" "$current_cli" "${available_clis[@]}") || {
    warn "Configuración cancelada."
    exit 0
}

authenticate "$cli"

preferred_model=""
[[ "$cli" == "$current_cli" ]] && preferred_model="$current_model"
model=$(select_model "$cli" "$preferred_model") || exit $?

config_dir=${CONFIG_FILE%/*}
mkdir -p "$config_dir"
tmp_config=$(mktemp "${config_dir}/.config.json.XXXXXX")
trap 'rm -f "$tmp_config"' EXIT
chmod 600 "$tmp_config"
jq -n \
    --arg cli "$cli" \
    --arg model "$model" \
    '{version: 1, cli: $cli, model: $model, language: "es"}' \
    >"$tmp_config"
mv "$tmp_config" "$CONFIG_FILE"
trap - EXIT

ok "Configuración guardada en $CONFIG_FILE"
if [[ -n "$model" ]]; then
    info "CLI: $cli · Modelo: $model"
else
    info "CLI: $cli · Modelo predeterminado"
fi
