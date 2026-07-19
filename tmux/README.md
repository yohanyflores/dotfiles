# Tmux

Configuración autocontenida para desarrollo en contenedores, con una interfaz
inspirada en Zellij y la paleta Catppuccin Mocha. No requiere TPM, plugins ni
comandos periódicos externos.

## Inicio rápido

```bash
tmux new -As dev
```

El líder común de tmux y Zellij es `Ctrl-Space`, con `F12` como alternativa.
Si necesitas enviar `Ctrl-Space` a un programa dentro del multiplexor, púlsalo
dos veces.

## Atajos principales

| Atajo | Acción |
| --- | --- |
| `Ctrl-Space` o `F12` | Activar la capa de comandos |
| `Ctrl-Space` + `\|` | Dividir a la derecha |
| `Ctrl-Space` + `-` | Dividir hacia abajo |
| `Ctrl-Space` + `h/j/k/l` | Cambiar de panel |
| `Alt` + flechas | Cambiar de panel sin prefijo |
| `Ctrl-Space` + `H/J/K/L` | Redimensionar el panel |
| `Ctrl-Space` + `z` | Maximizar/restaurar el panel |
| `Ctrl-Space` + `c` | Crear una ventana |
| `Ctrl-Space` + `1…9` | Ir a una ventana |
| `Ctrl-Space` + `w` | Selector de ventanas |
| `Ctrl-Space` + `s` | Selector de sesiones |
| `Ctrl-Space` + `[` | Entrar al modo copia |
| `v`, después `y` | Seleccionar y copiar en modo copia |
| `Ctrl-Space` + `r` | Recargar la configuración |
| `Ctrl-Space` + `?` | Ver todos los atajos |

Los paneles y las ventanas nuevas conservan el directorio actual. La barra
superior muestra la sesión, las ventanas, el directorio del panel, el nombre del
contenedor o host y la hora. `KEYS` reemplaza a `TMUX` mientras el prefijo está
activo, y `Z` identifica una ventana con un panel maximizado.

## Si tmux sigue usando otro prefijo

Una sesión iniciada antes de instalar o actualizar estos dotfiles mantiene su
configuración anterior en memoria. Aplica el archivo directamente:

```bash
tmux source-file ~/.config/tmux/tmux.conf
tmux show-options -gv prefix
```

El segundo comando debe imprimir `C-Space`. Al volver a ejecutar `install.sh`, se
creará también `~/.tmux.conf` y las sesiones existentes se recargarán de forma
automática.
