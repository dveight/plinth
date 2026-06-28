#!/bin/bash

FLAG=/tmp/plinth_opened
PLINTH_HOME="${PLINTH_HOME:-$HOME/plinth}"
CONFIG="$PLINTH_HOME/config/gallery/hours.txt"
LOG="$PLINTH_HOME/logs/gallery.log"
DAY=$(date +%w)
TIME_NOW=$(date +%H:%M)
SOCKET="$PLINTH_HOME/plinth.sock"
MAINTENANCE_FLAG="$PLINTH_HOME/config/.maintenance"

[ -f "$MAINTENANCE_FLAG" ] && exit 0
[ -f "$FLAG" ] && exit 0

OPEN_TIME=$(grep -v '^#' "$CONFIG" | awk -v day="$DAY" '$1 == day {print $2}')
CLOSE_TIME=$(grep -v '^#' "$CONFIG" | awk -v day="$DAY" '$1 == day {print $3}')

if [[ "$TIME_NOW" == "$OPEN_TIME" ]] || [[ "$TIME_NOW" > "$OPEN_TIME" && "$TIME_NOW" < "$CLOSE_TIME" ]]; then
    touch "$FLAG"
    echo "$(date): Gallery opening" >> "$LOG"

    # Switch MPV back to main playlist
    echo '{"command": ["loadlist", "'"$PLINTH_HOME/playlist.txt"'", "replace"]}' | socat - "$SOCKET"
    echo '{"command": ["set_property", "pause", false]}' | socat - "$SOCKET"
    rm -f "/tmp/plinth_closed"
    echo "$(date): Playlist restored" >> "$LOG"
fi
