#!/usr/bin/env bash
# ==============================================================================
# Script: git-agy-commit.sh
# Descripción: Wrapper interactivo profesional para validar, editar o cancelar
#              el mensaje de commit generado por agy (AI).
# ==============================================================================

set -euo pipefail

# Colores para salida
log_info() { echo -e "\e[34m[dcdev:commit]\e[0m $*"; }
log_warn() { echo -e "\e[33m[dcdev:commit]\e[0m $*"; }
log_err()  { echo -e "\e[31m[dcdev:commit] ERROR:\e[0m $*" >&2; }

MSG_FILE="/tmp/agy_commit_msg"

# 1. Validar que existan cambios staged
if git diff --quiet --cached; then
    log_err "No hay cambios preparados (staged) para hacer commit."
    read -r -p "Presiona Enter para continuar..." _
    exit 1
fi

# 2. Generar el mensaje con agy
log_info "Generando mensaje de commit con agy..."
if ! git diff --staged | agy --print "Genera un mensaje de commit conciso para estos cambios. Devuelve ÚNICAMENTE el mensaje de commit crudo, sin formato markdown, sin bloques de código, sin comillas y sin explicaciones adicionales. Sigue el formato de Conventional Commits." > "$MSG_FILE" 2>/dev/null; then
    log_err "Fallo al generar el mensaje con agy."
    read -r -p "Presiona Enter para continuar..." _
    exit 1
fi

# 3. Validar que el archivo no esté vacío
if [[ ! -s "$MSG_FILE" ]]; then
    log_err "El mensaje autogenerado por agy está vacío."
    read -r -p "Presiona Enter para continuar..." _
    exit 1
fi

# 4. Flujo interactivo profesional
while true; do
    echo -e "\n\e[32m--- MENSAJE PROPUESTO POR LA AI ---\e[0m"
    cat "$MSG_FILE"
    echo -e "\e[32m-----------------------------------\e[0m\n"
    
    # Intentar usar gum si está disponible para un selector interactivo espectacular
    if command -v gum >/dev/null 2>&1; then
        CHOICE=$(gum choose "Aceptar y hacer commit" "Editar mensaje y hacer commit" "Cancelar y abortar" --header="Selecciona una acción:")
        case "$CHOICE" in
            "Aceptar y hacer commit") OPT="a" ;;
            "Editar mensaje y hacer commit") OPT="e" ;;
            *) OPT="c" ;;
        esac
    else
        echo -e "Opciones:"
        echo -e "  [a] Aceptar y hacer commit directamente"
        echo -e "  [e] Editar el mensaje y hacer commit"
        echo -e "  [c] Cancelar el commit y abortar"
        echo -n "Selecciona una opción [a/e/c]: "
        
        # Asegurar que leemos desde la terminal real
        read -r OPT < /dev/tty
    fi
    
    case "${OPT,,}" in
        a|y)
            log_info "Haciendo commit..."
            git commit -F "$MSG_FILE"
            break
            ;;
        e)
            if command -v gum >/dev/null 2>&1; then
                log_info "Abriendo editor interactivo gum (Ctrl+D para guardar, Ctrl+C para cancelar)..."
                CURRENT_MSG=$(cat "$MSG_FILE")
                
                # Desactivar temporalmente set -e para capturar el código de salida de gum write
                set +e
                NEW_MSG=$(gum write --value "$CURRENT_MSG" --placeholder "Escribe el mensaje de commit..." --width=80)
                GUM_STATUS=$?
                set -e
                
                if [ $GUM_STATUS -eq 0 ]; then
                    echo "$NEW_MSG" > "$MSG_FILE"
                else
                    log_warn "Edición cancelada por el usuario."
                    continue
                fi
            else
                # Determinar editor del sistema o usar vim/nano por defecto
                EDITOR_TO_USE="${VISUAL:-${EDITOR:-vim}}"
                log_info "Abriendo editor ($EDITOR_TO_USE)..."
                "$EDITOR_TO_USE" "$MSG_FILE" < /dev/tty > /dev/tty
            fi
            
            # Si se vacía el archivo en la edición, se aborta
            if [[ ! -s "$MSG_FILE" ]]; then
                log_warn "Mensaje vacío tras la edición. Commit abortado."
                break
            fi
            
            log_info "Haciendo commit con el mensaje editado..."
            git commit -F "$MSG_FILE"
            break
            ;;
        c|q)
            log_warn "Commit cancelado por el usuario."
            break
            ;;
        *)
            log_warn "Opción inválida."
            ;;
    esac
done

# Limpieza silenciosa
rm -f "$MSG_FILE"
