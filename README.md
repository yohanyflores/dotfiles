## ⚠️ Licencia Propietaria
Este proyecto **NO es software libre ni de código abierto**. El código está expuesto públicamente solo para su revisión y auditoría. Queda prohibida su descarga, uso, modificación o distribución sin autorización. Consulta el archivo `LICENSE` para más detalles.

---

# 🚀 Terminal Dev Container Workflow (Con Caché y SSH Agent)

Este repositorio contiene las configuraciones personales (dotfiles) y el script wrapper local `yobydev` para implementar un entorno de desarrollo profesional basado en terminal utilizando **Dev Containers** sin depender de interfaces gráficas.

## 🧠 Filosofía del Flujo

- **Separación de Responsabilidades**: El Dev Container del proyecto contiene únicamente las herramientas del equipo y el stack de producción. Este repositorio contiene exclusivamente tus utilidades de productividad personal.
- **Conexión Directa**: Usamos `devcontainer up` solo para inicializar el ciclo de vida del contenedor y luego nos conectamos de forma inmediata a través de `devcontainer exec`, logrando mayor consistencia e inyección nativa del entorno.
- **Caché Persistente**: Los archivos binarios descargados desde GitHub Releases se guardan en el host bajo `~/.cache/yobydev/tools` y se montan en el contenedor, permitiendo reconstrucciones casi instantáneas del contenedor sin volver a realizar descargas.

---

## 🛠️ Requisitos en el Host Linux

Asegúrate de contar con las siguientes utilidades instaladas en tu máquina host:
1. **Docker Engine**: Docker debe estar ejecutándose y accesible por tu usuario actual (sin requerir sudo).
2. **CLI de Dev Containers**: Instalado de manera global mediante npm:
   ```bash
   npm install -g @devcontainers/cli
   ```
3. **jq**: Procesador de JSON en terminal.

---

## ⚙️ Configuración e Instalación

### 1. Enlace del Wrapper
Vincula el script wrapper `yobydev` a un directorio que esté en tu `$PATH` de la máquina host para poder ejecutarlo desde cualquier lugar:

```bash
# Otorgar permisos de ejecución en la carpeta de dotfiles
chmod +x install-devcontainer.sh bin/yobydev

# Crear symlink en tu binario local
ln -sf ~/dotfiles/bin/yobydev ~/.local/bin/yobydev
```

### 2. Configurar Variables de Entorno (Host)
Para personalizar el comportamiento, puedes exportar las siguientes variables en el archivo `.bashrc` o `.zshrc` de tu máquina host:

```bash
# Ruta de tu repositorio de dotfiles
export DOTFILES_REPOSITORY="git@github.com:usuario/dotfiles.git"

# Perfil de herramientas: 'core' (default) o 'full'
export DOTFILES_PROFILE="core"

# Token de GitHub para evitar límites de cuota (opcional)
export GITHUB_TOKEN="ghp_tuTokenAqui"
```

---

## 🚀 Uso Diario

1. Abre tu terminal y colócate en la raíz de cualquier repositorio con soporte de Dev Container.
2. Ejecuta el wrapper (el cual te presentará un menú interactivo tipo VS Code):
   ```bash
   yobydev
   ```
   *También puedes ejecutar subcomandos directos (ej. `yobydev attach`, `yobydev logs`, `yobydev destroy`).*
3. **Selección interactiva**:
   - Si hay un solo archivo `devcontainer.json`, `yobydev` lo usará de forma transparente.
   - Si hay múltiples archivos `devcontainer.json` (típico en monorepos), el script te presentará un menú interactivo usando `gum` (si está instalado en tu host) o un menú Bash `select` nativo como fallback para elegir cuál deseas iniciar.
4. El script levantará el entorno, inyectará tus dotfiles, correrá el instalador inteligente (usando la caché si los binarios ya fueron descargados previamente) y te dejará dentro de una sesión interactiva del contenedor.

### 🖥️ Ambiente Tmux

La configuración de tmux es autocontenida, usa la paleta Catppuccin Mocha y
mantiene una interfaz compacta inspirada en Zellij. El instalador la enlaza en
`~/.config/tmux`; no requiere plugins ni pasos adicionales.

```bash
# Crear la sesión "dev" o volver a ella si ya existe
tmux new -As dev
```

El prefijo es `Ctrl-a`. Usa `Ctrl-a` + `|` o `-` para dividir paneles,
`Ctrl-a` + `h/j/k/l` para navegar, `Ctrl-a` + `z` para maximizar y
`Ctrl-a` + `r` para recargar cambios. La guía completa está en
[`tmux/README.md`](tmux/README.md).

### 💡 Atajos de Commit con IA en Lazygit

Este repositorio incluye una integración directa con `lazygit`. Cuando te encuentres en el panel de **Files** (Archivos), puedes utilizar los siguientes atajos para generar automáticamente mensajes de commit convencionales basados en los cambios que tienes en stage:

*   **`Alt + c`**: Genera un mensaje de commit usando **`agy`** (Antigravity).
*   **`Alt + Shift + C` o `Alt + C`**: Genera un mensaje de commit usando **`opencode`**.

Ambos atajos abrirán un editor interactivo usando `gum` (o un fallback interactivo en consola si no está instalado) para revisar, editar o cancelar el mensaje generado por la IA antes de confirmar el commit.


---

## 📦 Catálogo de Herramientas Soportadas

El instalador clasifica las herramientas mediante perfiles (`DOTFILES_PROFILE`):

| Perfil | Herramienta | Propósito | Comando de Prueba |
| :--- | :--- | :--- | :--- |
| **core** | **Neovim** | Editor de código principal. | `nvim --version` |
| **core** | **Zellij** / **Tmux** | Multiplexores de terminal. | `zellij --version` / `tmux -V` |
| **core** | **Just** | Ejecutor de comandos alternativo a make. | `just --version` |
| **core** | **Lazygit** | Interfaz Git interactiva. | `lazygit --version` |
| **core** | **ripgrep** / **fd** | Búsqueda ultra rápida de texto y archivos. | `rg --version` / `fd --version` |
| **core** | **fzf** / **jq** / **yq** | Filtro difuso e intérpretes JSON/YAML. | `fzf --version` / `jq --version` / `yq --version` |
| **core** | **tree** | Visualizador de directorios en formato de árbol. | `tree --version` |
| **nice** | **bat** / **eza** | Alternativas modernas a `cat` y `ls`. | `bat --version` / `eza --version` |
| **nice** | **delta** | Formateador de diffs de git premium. | `delta --version` |
| **nice** | **shellcheck** / **shfmt** | Linter y formateador de scripts shell. | `shellcheck --version` / `shfmt --version` |
| **nice** | **xh** / **yazi** / **micro** | HTTP client rápido, file manager y editor simple. | `xh --version` / `yazi --version` / `micro -version` |
| **nice** | **gomplate** | Procesador de plantillas Go. | `gomplate --version` |
| **nice** | **gum** | Herramienta de prompts interactivos y glamorosos en shell. | `gum --version` |
| **experimental** | **antigravity-cli** | Cliente para interactuar con agentes de Antigravity. | `agy --version` |
| **experimental** | **opencode** | Asistente de codificación por IA en la terminal. | `opencode --version` |

---

## 🔒 Seguridad y SSH Agent Forwarding

- **Cero Secretos**: No almacenes credenciales en el repositorio. Usa variables de entorno del host.
- **SSH Agent Forwarding**: Si tienes llaves SSH en tu laptop local y te conectas vía SSH a un servidor remoto, inicia sesión con `ssh -A usuario@servidor-remoto`. El script wrapper `yobydev` detectará automáticamente el socket en `$SSH_AUTH_SOCK` y lo inyectará dinámicamente en el contenedor mediante una configuración de override.
- **GITHUB_TOKEN**: Si se define en la máquina host, se propaga temporalmente al contenedor de manera segura para autenticar las peticiones a la API de GitHub al verificar versiones de releases, evitando bloqueos de IP.

---

## 🔍 Resolución de Problemas (Troubleshooting)

### Error: "Rate limit exceeded" al descargar herramientas
*   **Solución**: Genera un Personal Access Token (PAT) clásico en GitHub con alcances mínimos de lectura pública y expórtalo en tu máquina host como `export GITHUB_TOKEN="tu_token"`. `yobydev` lo inyectará automáticamente en el contenedor para las llamadas de `curl`.

### El agente SSH no funciona dentro del contenedor
*   **Solución**: Verifica que el agente SSH esté corriendo en tu máquina host ejecutando `ssh-add -l`. Si no devuelve llaves cargadas, ejecuta `ssh-add` en tu host antes de arrancar `yobydev`.
