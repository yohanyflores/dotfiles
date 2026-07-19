# Tmux

Configuración autocontenida para desarrollo en contenedores, con una interfaz
inspirada en Zellij y la paleta Catppuccin Mocha. No requiere TPM, plugins ni
comandos periódicos externos.

## Inicio rápido

```bash
tmux new -As dev
```

El prefijo es `Ctrl-a`. Si necesitas enviar `Ctrl-a` a un programa dentro de
tmux, púlsalo dos veces.

## Atajos principales

| Atajo | Acción |
| --- | --- |
| `Ctrl-a` + `\|` | Dividir a la derecha |
| `Ctrl-a` + `-` | Dividir hacia abajo |
| `Ctrl-a` + `h/j/k/l` | Cambiar de panel |
| `Alt` + flechas | Cambiar de panel sin prefijo |
| `Ctrl-a` + `H/J/K/L` | Redimensionar el panel |
| `Ctrl-a` + `z` | Maximizar/restaurar el panel |
| `Ctrl-a` + `c` | Crear una ventana |
| `Ctrl-a` + `1…9` | Ir a una ventana |
| `Ctrl-a` + `w` | Selector de ventanas |
| `Ctrl-a` + `s` | Selector de sesiones |
| `Ctrl-a` + `[` | Entrar al modo copia |
| `v`, después `y` | Seleccionar y copiar en modo copia |
| `Ctrl-a` + `r` | Recargar la configuración |
| `Ctrl-a` + `?` | Ver todos los atajos |

Los paneles y las ventanas nuevas conservan el directorio actual. La barra
inferior muestra la sesión, las ventanas, el directorio del panel, el nombre del
contenedor o host y la hora. `KEYS` reemplaza a `TMUX` mientras el prefijo está
activo, y `Z` identifica una ventana con un panel maximizado.

## Si tmux sigue usando `Ctrl-b`

Una sesión iniciada antes de instalar o actualizar estos dotfiles mantiene su
configuración anterior en memoria. Aplica el archivo directamente:

```bash
tmux source-file ~/.config/tmux/tmux.conf
tmux show-options -gv prefix
```

El segundo comando debe imprimir `C-a`. Al volver a ejecutar `install.sh`, se
creará también `~/.tmux.conf` y las sesiones existentes se recargarán de forma
automática.
