#!/bin/bash

PLINTH_HOME="${PLINTH_HOME:-$HOME/plinth}"
CONFIG="$PLINTH_HOME/config/gallery/hours.txt"
LOG="$PLINTH_HOME/logs/gallery.log"
FLAG=/tmp/plinth_closed
MAINTENANCE_FLAG="$PLINTH_HOME/config/.maintenance"
SCHEDULED_FLAG="$PLINTH_HOME/config/.scheduled_shutdown"
DAY=$(date +%w)
TIME_NOW=$(date +%H:%M)

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
    touch "$SCHEDULED_FLAG"
    echo "$(date): Closing gallery (scheduled)" >> "$LOG"

    # TV off commands go here
    "$PLINTH_HOME/venv/bin/python3" "$PLINTH_HOME/scripts/tv.py" off

    sudo /sbin/shutdown -h now
fi