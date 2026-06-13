#!/bin/bash

PLINTH_HOME="${PLINTH_HOME:-$HOME/plinth}"
FLAG=/tmp/disable_plinth_player
MAINTENANCE_FLAG="$PLINTH_HOME/config/.maintenance"
LOG="$PLINTH_HOME/logs/gallery.log"

case "$1" in
    on)
        if [ -f "$FLAG" ]; then
            rm "$FLAG"
            echo "$(date): Plinth enabled" >> "$LOG"
            systemctl --user start plinth-player.service
            echo "Plinth enabled"
        else
            echo "Plinth is already running"
        fi
        ;;
    off)
        if [ ! -f "$FLAG" ]; then
            touch "$FLAG"
            echo "$(date): Plinth disabled" >> "$LOG"
            systemctl --user stop plinth-player.service
            echo "Plinth disabled"
        else
            echo "Plinth is already disabled"
        fi
        ;;
    status)
        if [ -f "$FLAG" ]; then
            echo "Plinth is disabled"
        else
            STATUS=$(systemctl --user is-active plinth-player.service)
            echo "Plinth is enabled (service: $STATUS)"
        fi
        ;;
    hours)
        "$PLINTH_HOME/scripts/gallery-status.sh"
        ;;
    maintenance)
        case "$2" in
            on)
                touch "$MAINTENANCE_FLAG"
                echo "$(date): Maintenance mode enabled" >> "$LOG"
                echo "Maintenance mode enabled — hour checks disabled (persists across reboots)"
                ;;
            off)
                if [ -f "$MAINTENANCE_FLAG" ]; then
                    rm "$MAINTENANCE_FLAG"
                    echo "$(date): Maintenance mode disabled" >> "$LOG"
                    echo "Maintenance mode disabled"
                else
                    echo "Maintenance mode is already off"
                fi
                ;;
            *)
                if [ -f "$MAINTENANCE_FLAG" ]; then
                    echo "Maintenance mode is ON"
                else
                    echo "Maintenance mode is OFF"
                fi
                ;;
        esac
        ;;
    *)
        echo "Usage: $0 {on|off|status|hours|maintenance {on|off}}"
        exit 1
        ;;
esac    