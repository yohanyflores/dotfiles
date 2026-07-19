# Tmux

Configuración autocontenida para desarrollo en contenedores, con una interfaz
inspirada en Zellij y su paleta predeterminada. No requiere TPM, plugins ni
comandos periódicos externos.

## Inicio rápido

```bash
tmux new -As dev
```

El líder común de tmux y Zellij es `Ctrl-G`. Para enviar un `Ctrl-G` real a un
programa dentro del multiplexor, usa `Alt-G`.

## Atajos principales

| Atajo | Acción |
| --- | --- |
| `Ctrl-G` | Activar la capa de comandos |
| `Alt-G` | Enviar `Ctrl-G` a la aplicación |
| `Ctrl-G` + `\|` | Dividir a la derecha |
| `Ctrl-G` + `-` | Dividir hacia abajo |
| `Ctrl-G` + `h/j/k/l` | Cambiar de panel |
| `Alt` + flechas | Cambiar de panel sin prefijo |
| `Ctrl-G` + `H/J/K/L` | Redimensionar el panel |
| `Ctrl-G` + `z` | Maximizar/restaurar el panel |
| `Ctrl-G` + `Space` | Abrir el selector de diseños |
| `Alt` + `[` / `]` | Recorrer diseños |
| `Ctrl-G` + `c` | Crear una ventana |
| `Ctrl-G` + `1…9` | Ir a una ventana |
| `Ctrl-G` + `w` | Selector de ventanas |
| `Ctrl-G` + `s` | Selector de sesiones |
| `Ctrl-G` + `[` | Entrar al modo copia |
| `v`, después `y` | Seleccionar y copiar en modo copia |
| `Ctrl-G` + `r` | Recargar la configuración |
| `Ctrl-G` + `?` | Ver todos los atajos |

Los paneles y las ventanas nuevas conservan el directorio actual. La barra
superior muestra `Tmux (sesión)` y las ventanas; cada marco muestra el proceso y
la ruta de su panel, igual que Zellij. `Ctrl-G › COMMAND` sólo aparece mientras el
líder está activo, y `Z` identifica una ventana con un panel maximizado.

## Si tmux sigue usando otro prefijo

Una sesión iniciada antes de instalar o actualizar estos dotfiles mantiene su
configuración anterior en memoria. Aplica el archivo directamente:

```bash
tmux source-file ~/.config/tmux/tmux.conf
tmux show-options -gv prefix
```

El segundo comando debe imprimir `C-g`. Al volver a ejecutar `install.sh`, se
creará también `~/.tmux.conf` y las sesiones existentes se recargarán de forma
automática.
