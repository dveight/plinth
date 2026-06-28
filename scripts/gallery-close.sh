#!/bin/bash

PLINTH_HOME="${PLINTH_HOME:-$HOME/plinth}"
CONFIG="$PLINTH_HOME/config/gallery/hours.txt"
LOG="$PLINTH_HOME/logs/gallery.log"
FLAG=/tmp/plinth_closed
MAINTENANCE_FLAG="$PLINTH_HOME/config/.maintenance"
DAY=$(date +%w)
TIME_NOW=$(date +%H:%M)
SOCKET="$PLINTH_HOME/plinth.sock"

mkdir -p "$PLINTH_HOME/logs"

# Maintenance mode — skip all checks (persists across reboots)
[ -f "$MAINTENANCE_FLAG" ] && exit 0

# Already closed today
[ -f "$FLAG" ] && exit 0

# Read today's close time
CLOSE_TIME=$(grep -v '^#' "$CONFIG" | awk -v day="$DAY" '$1 == day {print $3}')

if [ -z "$CLOSE_TIME" ]; then
    echo "$(date): No close time found for day $DAY" >> "$LOG"
    exit 1
fi

if [[ "$TIME_NOW" > "$CLOSE_TIME" ]] || [[ "$TIME_NOW" == "$CLOSE_TIME" ]]; then
    touch "$FLAG"
    echo "$(date): Closing gallery (scheduled)" >> "$LOG"

    # TV off commands go here
    echo '{"command": ["loadfile", "'"$PLINTH_HOME/standby/black.mov"'", "replace"]}' | socat - "$SOCKET"
    echo '{"command": ["set_property", "pause", true]}' | socat - "$SOCKET"
    rm -f "/tmp/plinth_opened"
fi
