# Resumen del Plan de Arquitectura Dev Container en Terminal

Este documento resume las decisiones de diseño y la arquitectura implementada en este repositorio de dotfiles para levantar entornos de desarrollo reproducibles mediante terminal.

## Arquitectura y Componentes

1. **`install-devcontainer.sh` (Script de Instalación en el Contenedor)**
   - **Perfiles (`DOTFILES_PROFILE`)**:
     - `core` (Default): Neovim, Zellij, Tmux, Just, Lazygit, Ripgrep, fd, fzf, jq, yq, Git, curl, unzip, zip.
     - `nice`: Bat, Eza, Delta, Shellcheck, shfmt, Tree, xh, Yazi, Micro, Gomplate, Gum.
     - `experimental`: antigravity-cli, opencode.
     - `full`: Instala todas las anteriores.
   - **Caché Persistente**:
     - Las descargas se realizan hacia una carpeta montada (`DOTFILES_CACHE_DIR`).
     - Si la herramienta ya existe en `~/.local/bin` con la versión correcta, se omite.
     - Si está en caché, se instala desde ahí para no descargar de nuevo.
     - Si no está, se descarga, se valida opcionalmente el checksum, se copia en caché y se instala.
   - **Enlace de Dotfiles**:
     - Crea enlaces simbólicos hacia carpetas en `~/.config` y archivos en `$HOME`.
     - Respaldos con marca de tiempo (`.bak_$(date)`) para evitar pérdidas.

2. **`bin/dcdev` (Wrapper de Host)**
   - Detecta de forma interactiva múltiples archivos `devcontainer.json` en el repositorio, permitiendo seleccionarlos mediante `gum choose` o el comando `select` nativo de Bash.
   - Genera un archivo temporal JSON de override de Dev Container.
   - Si `$SSH_AUTH_SOCK` está presente en el host, inyecta su montaje bind en `/ssh-agent` y establece la variable.
   - Inyecta la caché local del host (`~/.cache/dcdev/tools/`) montándola en `/tmp/dcdev-tools-cache`.
   - Propaga `$GITHUB_TOKEN` si está definido en el host para evitar rate limits de la API.
   - Ejecuta `devcontainer up` pasando el override temporal de forma silenciosa.
   - Se conecta mediante `devcontainer exec` utilizando el shell interactivo del usuario remoto.

## Tabla de Mapeo de Caché

Los binarios descargados se versionan y aíslan en el host bajo la siguiente estructura:
`~/.cache/dcdev/tools/<tool_name>/<version>/linux-<arch_mapped>/`

| Herramienta | Versión Core por Defecto | Repositorio GitHub |
| :--- | :--- | :--- |
| **lazygit** | `0.40.2` | `jesseduffield/lazygit` |
| **just** | `1.14.0` | `casey/just` |
| **zellij** | `0.38.2` | `zellij-org/zellij` |
| **yq** | `4.35.2` | `mikefarah/yq` |
| **gum** | `0.17.0` | `charmbracelet/gum` |

---

## Ejecución Rápida en el Host

1. Dar permisos de ejecución:
   ```bash
   chmod +x install-devcontainer.sh bin/dcdev
   ```
2. Crear un symlink de `dcdev` a tu PATH local del host:
   ```bash
   ln -sf ~/dotfiles/bin/dcdev ~/.local/bin/dcdev
   ```
3. Ejecutar `dcdev` desde la raíz de cualquier proyecto que contenga `.devcontainer/`.
