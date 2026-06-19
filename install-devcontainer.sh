#!/usr/bin/env bash
# ==============================================================================
# Script: install-devcontainer.sh
# Descripción: Instalador idempotente y modular de dotfiles personales con soporte
#              de perfiles, caché persistente en host y validación de versiones.
# ==============================================================================

set -euo pipefail

# --- CONFIGURACIÓN DE ENTORNOS Y RUTAS ---
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- LOGGING UTILS ---
log_info() {
    echo -e "\e[34m[INFO]\e[0m $*"
}

log_warn() {
    echo -e "\e[33m[WARN]\e[0m $*" >&2
}

log_error() {
    echo -e "\e[31m[ERROR]\e[0m $*" >&2
}

# --- ROOT ELEVATION UTILS ---
run_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        log_warn "Se requieren privilegios de root pero 'sudo' no está disponible. Intentando..."
        "$@"
    fi
}

# --- CONFIGURACIÓN DE CACHÉ ---
# El wrapper yobydev pasará DOTFILES_CACHE_DIR apuntando al bind-mount del host
CACHE_DIR="${DOTFILES_CACHE_DIR:-$HOME/.cache/dotfiles-tools}"
log_info "Directorio de caché configurado en: $CACHE_DIR"

# --- DETECCIÓN DE PERFIL ---
# Opciones: core (default), full (core + nice + experimental)
DOTFILES_PROFILE="${DOTFILES_PROFILE:-full}"
log_info "Perfil de instalación seleccionado: $DOTFILES_PROFILE"

# --- GITHUB DOWNLOAD WITH CACHE AND VERSION CONTROL ---
install_github_tool() {
    local name="$1"
    local repo="$2"
    local expected_version="$3"
    local asset_pattern="$4"
    local binary_inside_archive="${5:-$name}"
    
    # 1. Comprobar si ya existe con la versión deseada
    if command -v "$name" >/dev/null 2>&1; then
        if "$name" --version </dev/null 2>&1 | grep -F "$expected_version" >/dev/null || \
           "$name" -v </dev/null 2>&1 | grep -F "$expected_version" >/dev/null; then
            log_info "La herramienta '$name' ya está en ~/.local/bin con la versión $expected_version. Saltando."
            return 0
        fi
        log_info "Versión antigua o incorrecta detectada para '$name'. Actualizando a $expected_version..."
    fi

    # Determinar OS y arquitectura
    local os="linux"
    local arch
    arch=$(uname -m)
    local arch_mapped="$arch"
    
    # Adaptación de arquitectura según los nombres de releases de cada herramienta
    case "$name" in
        lazygit|gum)
            if [[ "$arch" == "x86_64" ]]; then arch_mapped="x86_64"; fi
            if [[ "$arch" == "aarch64" ]]; then arch_mapped="arm64"; fi
            ;;
        just|zellij|bat|eza|delta|xh|yazi)
            if [[ "$arch" == "x86_64" ]]; then arch_mapped="x86_64"; fi
            if [[ "$arch" == "aarch64" ]]; then arch_mapped="aarch64"; fi
            ;;
        yq|shfmt|gomplate)
            if [[ "$arch" == "x86_64" ]]; then arch_mapped="amd64"; fi
            if [[ "$arch" == "aarch64" ]]; then arch_mapped="arm64"; fi
            ;;
        micro)
            if [[ "$arch" == "x86_64" ]]; then arch_mapped="linux64-static"; fi
            if [[ "$arch" == "aarch64" ]]; then arch_mapped="linux-arm64-static"; fi
            ;;
    esac

    # Resolver tags de releases (tags con o sin v)
    local version_no_v="${expected_version#v}"
    local tag="v${version_no_v}"
    if [[ "$name" == "just" || "$name" == "delta" ]]; then
        tag="$version_no_v"
    fi

    # Reemplazo de marcadores en el patrón de asset
    local asset_name="$asset_pattern"
    asset_name="${asset_name//\$\{TAG\}/$tag}"
    asset_name="${asset_name//\$\{VERSION_NO_V\}/$version_no_v}"
    asset_name="${asset_name//\$\{ARCH\}/$arch_mapped}"

    # Rutas dentro del cache mount (persistente en el host)
    local cache_tool_dir="${CACHE_DIR}/${name}/${version_no_v}/${os}-${arch_mapped}"
    local cache_file="${cache_tool_dir}/${asset_name}"
    local from_cache=false

    # 2. Buscar en caché o descargar
    if [[ -f "$cache_file" ]]; then
        log_info "Encontrado en caché local del host: $cache_file"
        from_cache=true
    else
        log_info "No está en caché. Descargando desde GitHub..."
        mkdir -p "$cache_tool_dir"
        
        local download_url="https://github.com/${repo}/releases/download/${tag}/${asset_name}"
        
        # Opciones de curl incluyendo GITHUB_TOKEN si existe
        local curl_opts=(-fsSL)
        if [[ -n "${GITHUB_TOKEN:-}" ]]; then
            curl_opts+=(-H "Authorization: Bearer $GITHUB_TOKEN")
        fi
        
        if ! curl "${curl_opts[@]}" -o "$cache_file" "$download_url"; then
            log_error "Fallo al descargar $name desde $download_url"
            rm -f "$cache_file"
            return 1
        fi

        # Intentar obtener archivo de checksum para verificación de integridad
        local checksum_url="${download_url}.sha256"
        local checksum_file="${cache_file}.sha256"
        if curl "${curl_opts[@]}" -o "$checksum_file" "$checksum_url" >/dev/null 2>&1; then
            local expected_hash
            expected_hash=$(awk '{print $1}' "$checksum_file")
            local actual_hash
            actual_hash=$(sha256sum "$cache_file" | awk '{print $1}')
            if [[ "$expected_hash" != "$actual_hash" ]]; then
                log_error "Error: Hash SHA256 no coincide para $cache_file"
                rm -f "$cache_file" "$checksum_file"
                return 1
            fi
            log_info "Integridad SHA256 verificada con éxito."
        else
            # Intentar con .sha256sum
            checksum_url="${download_url}.sha256sum"
            checksum_file="${cache_file}.sha256sum"
            if curl "${curl_opts[@]}" -o "$checksum_file" "$checksum_url" >/dev/null 2>&1; then
                local expected_hash
                expected_hash=$(awk '{print $1}' "$checksum_file")
                local actual_hash
                actual_hash=$(sha256sum "$cache_file" | awk '{print $1}')
                if [[ "$expected_hash" != "$actual_hash" ]]; then
                    log_error "Error: Hash SHA256 no coincide para $cache_file"
                    rm -f "$cache_file" "$checksum_file"
                    return 1
                fi
                log_info "Integridad SHA256 (via .sha256sum) verificada con éxito."
            else
                log_warn "No se encontró archivo de checksum (.sha256 o .sha256sum). Omitiendo verificación."
                rm -f "$checksum_file" 2>/dev/null || true
            fi
        fi
    fi

    # 3. Instalar en ~/.local/bin
    local tmp_extract_dir
    tmp_extract_dir=$(mktemp -d)
    
    mkdir -p "$HOME/.local/bin"
    
    if [[ "$asset_name" == *.tar.gz ]]; then
        tar -xzf "$cache_file" -C "$tmp_extract_dir"
        find "$tmp_extract_dir" -type f -name "$binary_inside_archive" -exec mv {} "$HOME/.local/bin/$name" \;
    elif [[ "$asset_name" == *.zip ]]; then
        unzip -q "$cache_file" -d "$tmp_extract_dir"
        find "$tmp_extract_dir" -type f -name "$binary_inside_archive" -exec mv {} "$HOME/.local/bin/$name" \;
    else
        # Es un binario directo
        cp "$cache_file" "$HOME/.local/bin/$name"
    fi
    
    chmod +x "$HOME/.local/bin/$name"
    rm -rf "$tmp_extract_dir"
    log_info "Herramienta '$name' instalada en ~/.local/bin (Caché: $from_cache)"
}

# --- SYMLINKS CON RESPALDOS ---
create_symlink() {
    local src="$1"
    local dest="$2"
    
    if [[ ! -e "$src" ]]; then
        log_warn "Ruta origen '$src' no existe. Saltando enlace."
        return
    fi
    
    mkdir -p "$(dirname "$dest")"
    
    if [[ -e "$dest" || -L "$dest" ]]; then
        if [[ -L "$dest" && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
            log_info "Enlace simbólico ya correcto: $dest"
            return
        fi
        local backup="${dest}.bak_$(date +%Y%m%d%H%M%S)"
        log_info "Creando backup de configuración existente en $backup"
        mv "$dest" "$backup"
    fi
    
    log_info "Enlazando: $dest -> $src"
    ln -s "$src" "$dest"
}

# ==============================================================================
# 1. INSTALACIÓN DE PAQUETES BÁSICOS DE DISTRO
# ==============================================================================
log_info "Detectando gestor de paquetes de la distribución..."
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

if command -v apt-get >/dev/null 2>&1; then
    run_sudo apt-get update -y
    # Instalamos utilidades que siempre están en los repos y son de sistema
    apt_packages=(git curl unzip zip jq ripgrep fzf tmux fd-find neovim tree shellcheck locales)
    run_sudo apt-get install -y "${apt_packages[@]}"
    
    # Generar locale UTF-8 para que editores como nano muestren acentos correctamente
    if [ -f /etc/locale.gen ]; then
        run_sudo sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen
        run_sudo locale-gen en_US.UTF-8 2>/dev/null || true
    fi
    
    # Resolver 'fd' en Debian
    if command -v fdfind >/dev/null 2>&1 && [[ ! -e "$HOME/.local/bin/fd" ]]; then
        ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    fi

elif command -v apk >/dev/null 2>&1; then
    run_sudo apk update
    apk_packages=(git curl unzip zip jq ripgrep fzf tmux fd neovim tree shellcheck)
    run_sudo apk add "${apk_packages[@]}"
fi

# ==============================================================================
# 2. INSTALACIÓN POR PERFILES DESDE TOOLS.JSON
# ==============================================================================

# Localizar archivo tools.json
TOOLS_JSON="${DOTFILES_DIR}/tools.json"

if [[ -f "$TOOLS_JSON" ]]; then
    log_info "Cargando catálogo de herramientas desde $TOOLS_JSON..."
    
    # Filtrar herramientas en base al perfil
    # 'core' instala solo core. 'full' instala core y nice.
    filter="select(.profile == \"core\")"
    if [[ "$DOTFILES_PROFILE" == "full" ]]; then
        filter="select(.profile == \"core\" or .profile == \"nice\")"
    fi

    # Leer herramientas del JSON e instalarlas
    while read -r tool_info; do
        [[ -z "$tool_info" ]] && continue
        
        name=$(echo "$tool_info" | jq -r '.name')
        repo=$(echo "$tool_info" | jq -r '.repo')
        version=$(echo "$tool_info" | jq -r '.version')
        pattern=$(echo "$tool_info" | jq -r '.pattern')
        binary_inside=$(echo "$tool_info" | jq -r '.binary_inside // ""')
        
        log_info "Instalando $name ($version)..."
        install_github_tool "$name" "$repo" "$version" "$pattern" "${binary_inside:-$name}"
    done < <(jq -c ".tools[] | ${filter}" "$TOOLS_JSON")
else
    log_warn "No se encontró el archivo tools.json. Omitiendo instalación de GitHub tools."
fi

# --- PERFIL: EXPERIMENTAL ---
if [[ "$DOTFILES_PROFILE" == "full" ]]; then
    log_info "Instalando herramientas del perfil EXPERIMENTAL..."
    
    # Antigravity CLI
    if ! command -v agy >/dev/null 2>&1; then
        log_info "Instalando antigravity-cli..."
        if ! curl -fsSL https://antigravity.google/cli/install.sh | sed 's/platform="linux_${arch}_musl"/platform="linux_${arch}"/' | bash; then
            log_warn "No se pudo completar la instalación de antigravity-cli."
        fi
    fi

    # OpenCode CLI
    if ! command -v opencode >/dev/null 2>&1; then
        log_info "Instalando opencode cli..."
        if ! curl -fsSL https://opencode.ai/install | bash; then
            log_warn "No se pudo completar la instalación de opencode cli."
        fi
    fi
fi

# ==============================================================================
# 3. ENLAZAR CONFIGURACIONES PERSONALES
# ==============================================================================
log_info "Aplicando enlaces de configuración desde: $DOTFILES_DIR"

create_symlink "$DOTFILES_DIR/nvim"   "$HOME/.config/nvim"
create_symlink "$DOTFILES_DIR/zellij" "$HOME/.config/zellij"
create_symlink "$DOTFILES_DIR/tmux"   "$HOME/.config/tmux"
create_symlink "$DOTFILES_DIR/fish"   "$HOME/.config/fish"
create_symlink "$DOTFILES_DIR/lazygit" "$HOME/.config/lazygit"
create_symlink "$DOTFILES_DIR/scripts/git-agy-commit.sh" "$HOME/.local/bin/git-agy-commit"
create_symlink "$DOTFILES_DIR/scripts/git-opencode-commit.sh" "$HOME/.local/bin/git-opencode-commit"

# Persistencia de configuraciones de agentes (agy y opencode) en el espacio de trabajo
WORKSPACE_DIR=""
if [[ -n "${YOBYDEV_WORKSPACE_FOLDER:-}" && -d "$YOBYDEV_WORKSPACE_FOLDER/.home" ]]; then
    WORKSPACE_DIR="$YOBYDEV_WORKSPACE_FOLDER"
elif [[ -n "${WORKSPACE_FOLDER:-}" && -d "$WORKSPACE_FOLDER/.home" ]]; then
    WORKSPACE_DIR="$WORKSPACE_FOLDER"
elif [[ -n "${WORKSPACE_ROOT:-}" && -d "$WORKSPACE_ROOT/.home" ]]; then
    WORKSPACE_DIR="$WORKSPACE_ROOT"
elif [[ -n "${WORKSPACE_HOME:-}" && -d "$WORKSPACE_HOME/.home" ]]; then
    WORKSPACE_DIR="$WORKSPACE_HOME"
elif [[ -d "/workspace/.home" ]]; then
    WORKSPACE_DIR="/workspace"
else
    # Fallback: Buscar dinámicamente en /workspaces/
    for ws in /workspaces/*; do
        if [[ -d "$ws/.home" ]]; then
            WORKSPACE_DIR="$ws"
            break
        fi
    done
fi

if [[ -n "$WORKSPACE_DIR" ]]; then
    log_info "Carpeta de persistencia detectada en: $WORKSPACE_DIR/.home"
    mkdir -p "$WORKSPACE_DIR/.home/.gemini"
    mkdir -p "$WORKSPACE_DIR/.home/.opencode"
    create_symlink "$WORKSPACE_DIR/.home/.gemini"   "$HOME/.gemini"
    create_symlink "$WORKSPACE_DIR/.home/.opencode" "$HOME/.opencode"
else
    log_warn "No se detectó ninguna carpeta de persistencia (.home) en el espacio de trabajo. Omitiendo enlaces de agentes."
fi

if [[ -f "$DOTFILES_DIR/git/gitconfig" ]]; then
    create_symlink "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"
elif [[ -f "$DOTFILES_DIR/git/.gitconfig" ]]; then
    create_symlink "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
fi

if [[ -f "$DOTFILES_DIR/just/justfile" ]]; then
    create_symlink "$DOTFILES_DIR/just/justfile" "$HOME/.justfile"
fi

# Asegurar persistencia del PATH en ~/.bashrc
if ! grep -q "local/bin" "$HOME/.bashrc" 2>/dev/null; then
    echo -e '\nexport PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    log_info "PATH local agregado a ~/.bashrc"
fi

# Crear marcador de éxito para yobydev
mkdir -p "$HOME/.devcontainer"
touch "$HOME/.devcontainer/.dotfilesSuccess"
mkdir -p "$HOME/.yobydev"
touch "$HOME/.yobydev/success"

log_info "Entorno de Dev Container personalizado con éxito."
