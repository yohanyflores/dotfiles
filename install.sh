#!/usr/bin/env bash
# ==============================================================================
# Script: install-dotfiles-only.sh
# Descripción: Instalador modular y seguro de dotfiles personales.
#              ESTA VERSIÓN SOLO ENLAZA E INSTALA CONFIGURACIONES,
#              SIN DESCARGAR NI INSTALAR HERRAMIENTAS ADICIONALES.
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
# 1. PREPARACIÓN DE DIRECTORIOS
# ==============================================================================
log_info "Preparando directorios locales..."
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config"

# ==============================================================================
# 2. CONFIGURACIÓN DE SHELLS (~/.bashrc y ~/.zshrc)
# ==============================================================================
log_info "Configurando variables de entorno y alias en archivos de inicio..."

# Configurar en ~/.bashrc
if [ -f "$HOME/.bashrc" ]; then
  if ! grep -q "export LANG=" "$HOME/.bashrc" 2>/dev/null; then
    echo -e '\n# Configuración de locale UTF-8\nexport LANG=en_US.UTF-8\nexport LC_ALL=en_US.UTF-8' >>"$HOME/.bashrc"
    log_info "Locale UTF-8 configurado en ~/.bashrc"
  fi
  if ! grep -q "export EDITOR=" "$HOME/.bashrc" 2>/dev/null; then
    echo -e '\n# Editor predeterminado del sistema\nexport EDITOR=nvim\nexport VISUAL=nvim' >>"$HOME/.bashrc"
    log_info "Editor por defecto configurado en ~/.bashrc"
  fi
  if ! grep -q "alias lv=" "$HOME/.bashrc" 2>/dev/null; then
    echo -e '\n# Alias para LazyVim en paralelo\nalias lv="env NVIM_APPNAME=lazyvim nvim"' >>"$HOME/.bashrc"
    log_info "Alias lv para LazyVim configurado en ~/.bashrc"
  fi
  if ! grep -q "starship init bash" "$HOME/.bashrc" 2>/dev/null; then
    echo -e '\n# Inicializar Starship Prompt\nif command -v starship >/dev/null 2>&1; then\n    eval "$(starship init bash)"\nfi' >>"$HOME/.bashrc"
    log_info "Starship configurado en ~/.bashrc"
  fi
  if ! grep -q "mise activate bash" "$HOME/.bashrc" 2>/dev/null; then
    echo -e '\n# Inicializar mise\nif command -v mise >/dev/null 2>&1; then\n    eval "$(mise activate bash)"\nfi' >>"$HOME/.bashrc"
    log_info "mise configurado en ~/.bashrc"
  fi
  if ! grep -q "direnv hook bash" "$HOME/.bashrc" 2>/dev/null; then
    echo -e '\n# Inicializar direnv\nif command -v direnv >/dev/null 2>&1; then\n    eval "$(direnv hook bash)"\nfi' >>"$HOME/.bashrc"
    log_info "direnv configurado en ~/.bashrc"
  fi
fi

# Configurar en ~/.zshrc
if [ -f "$HOME/.zshrc" ] || [ ! -e "$HOME/.zshrc" ]; then
  touch "$HOME/.zshrc"
  if ! grep -q "export LANG=" "$HOME/.zshrc" 2>/dev/null; then
    echo -e '\n# Configuración de locale UTF-8\nexport LANG=en_US.UTF-8\nexport LC_ALL=en_US.UTF-8' >>"$HOME/.zshrc"
    log_info "Locale UTF-8 configurado en ~/.zshrc"
  fi
  if ! grep -q "export EDITOR=" "$HOME/.zshrc" 2>/dev/null; then
    echo -e '\n# Editor predeterminado del sistema\nexport EDITOR=nvim\nexport VISUAL=nvim' >>"$HOME/.zshrc"
    log_info "Editor por defecto configurado en ~/.zshrc"
  fi
  if ! grep -q "alias lv=" "$HOME/.zshrc" 2>/dev/null; then
    echo -e '\n# Alias para LazyVim en paralelo\nalias lv="env NVIM_APPNAME=lazyvim nvim"' >>"$HOME/.zshrc"
    log_info "Alias lv para LazyVim configurado en ~/.zshrc"
  fi
  if ! grep -q "starship init zsh" "$HOME/.zshrc" 2>/dev/null; then
    echo -e '\n# Inicializar Starship Prompt\nif command -v starship >/dev/null 2>&1; then\n    eval "$(starship init zsh)"\nfi' >>"$HOME/.zshrc"
    log_info "Starship configurado en ~/.zshrc"
  fi
  if ! grep -q "mise activate zsh" "$HOME/.zshrc" 2>/dev/null; then
    echo -e '\n# Inicializar mise\nif command -v mise >/dev/null 2>&1; then\n    eval "$(mise activate zsh)"\nfi' >>"$HOME/.zshrc"
    log_info "mise configurado en ~/.zshrc"
  fi
  if ! grep -q "direnv hook zsh" "$HOME/.zshrc" 2>/dev/null; then
    echo -e '\n# Inicializar direnv\nif command -v direnv >/dev/null 2>&1; then\n    eval "$(direnv hook zsh)"\nfi' >>"$HOME/.zshrc"
    log_info "direnv configurado en ~/.zshrc"
  fi
fi

# Configurar Fish como shell por defecto (si ya está instalado)
if command -v fish >/dev/null 2>&1; then
  current_user=$(whoami)
  fish_path=$(command -v fish)

  # Asegurar que fish esté en /etc/shells
  if ! grep -q "$fish_path" /etc/shells 2>/dev/null; then
    log_info "Añadiendo $fish_path a /etc/shells..."
    echo "$fish_path" | run_sudo tee -a /etc/shells >/dev/null
  fi

  # Cambiar shell por defecto
  log_info "Configurando fish como shell por defecto para $current_user..."
  if command -v chsh >/dev/null 2>&1; then
    run_sudo chsh -s "$fish_path" "$current_user" || log_warn "No se pudo cambiar el shell con chsh."
  else
    run_sudo sed -i "s|^${current_user}:\(.*\):[^:]*$|${current_user}:\1:${fish_path}|" /etc/passwd || log_warn "No se pudo cambiar el shell en /etc/passwd."
  fi
fi

# ==============================================================================
# 3. PERSISTENCIA DE CONFIGURACIONES DE AGENTES (AGY Y OPENCODE)
# ==============================================================================
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
  mkdir -p "$WORKSPACE_DIR/.home/.local/share/opencode"
  create_symlink "$WORKSPACE_DIR/.home/.gemini" "$HOME/.gemini"
  create_symlink "$WORKSPACE_DIR/.home/.opencode" "$HOME/.opencode"
  create_symlink "$WORKSPACE_DIR/.home/.local/share/opencode" "$HOME/.local/share/opencode"
else
  log_warn "No se detectó ninguna carpeta de persistencia (.home) en el espacio de trabajo. Omitiendo enlaces de agentes."
fi

# ==============================================================================
# 4. ENLAZAR CONFIGURACIONES PERSONALES (DOTFILES)
# ==============================================================================
log_info "Aplicando enlaces de configuración desde: $DOTFILES_DIR"

create_symlink "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
create_symlink "$DOTFILES_DIR/lazyvim" "$HOME/.config/lazyvim"
create_symlink "$DOTFILES_DIR/micro" "$HOME/.config/micro"
create_symlink "$DOTFILES_DIR/zellij" "$HOME/.config/zellij"
create_symlink "$DOTFILES_DIR/tmux" "$HOME/.config/tmux"
create_symlink "$DOTFILES_DIR/fish" "$HOME/.config/fish"
create_symlink "$DOTFILES_DIR/lazygit" "$HOME/.config/lazygit"
create_symlink "$DOTFILES_DIR/scripts/git-agy-commit.sh" "$HOME/.local/bin/git-agy-commit"
create_symlink "$DOTFILES_DIR/scripts/git-opencode-commit.sh" "$HOME/.local/bin/git-opencode-commit"
create_symlink "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
create_symlink "$DOTFILES_DIR/yazi" "$HOME/.config/yazi"

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
  echo -e '\nexport PATH="$HOME/.local/bin:$PATH"' >>"$HOME/.bashrc"
  log_info "PATH local agregado a ~/.bashrc"
fi

# Instalar todos los plugins definidos en package.toml
if command -v ya >/dev/null 2>&1; then
    echo "Instalando plugins de Yazi..."
    ya pack -i
fi

# Crear marcador de éxito para yobydev / devcontainers
mkdir -p "$HOME/.devcontainer"
touch "$HOME/.devcontainer/.dotfilesSuccess"
mkdir -p "$HOME/.yobydev"
touch "$HOME/.yobydev/success"

log_info "Enlaces de dotfiles creados con éxito (sin instalación de herramientas adicionales)."
