# Configuración básica de Fish
# ~/.config/fish/config.fish

# Configuración de locale UTF-8 para soporte de acentos y caracteres especiales
set -gx LANG en_US.UTF-8
set -gx LC_ALL en_US.UTF-8

# Definir Neovim como editor por defecto del sistema
set -gx EDITOR nvim
set -gx VISUAL nvim

if status is-interactive
    # Comandos a ejecutar en sesiones interactivas
    alias l="la -la"
    alias g="git"
    alias v="nvim"
    alias lv="env NVIM_APPNAME=lazyvim nvim"
    
    # Agregar binarios locales al PATH (compatible con Fish < 3.2.0)
    if functions -q fish_add_path
        fish_add_path $HOME/.local/bin
    else
        contains $HOME/.local/bin $PATH; or set -gx PATH $HOME/.local/bin $PATH
    end

    # Inicializar Starship Prompt
    if command -v starship >/dev/null 2>&1
        starship init fish | source
    end

    # Inicializar mise
    if command -v mise >/dev/null 2>&1
        mise activate fish | source
    end

    # Inicializar direnv
    if command -v direnv >/dev/null 2>&1
        direnv hook fish | source
    end
end


# Added by Antigravity CLI installer
set -gx PATH "/home/vscode/.local/bin" $PATH
