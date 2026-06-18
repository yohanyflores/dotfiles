# Configuración básica de Fish
# ~/.config/fish/config.fish

if status is-interactive
    # Comandos a ejecutar en sesiones interactivas
    alias l="la -la"
    alias g="git"
    alias v="nvim"
    
    # Agregar binarios locales al PATH
    fish_add_path $HOME/.local/bin
end


# Added by Antigravity CLI installer
set -gx PATH "/home/vscode/.local/bin" $PATH
