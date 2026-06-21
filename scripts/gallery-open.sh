#!/bin/bash

PLINTH_HOME="${PLINTH_HOME:-$HOME/plinth}"
CONFIG="$PLINTH_HOME/config/gallery/hours.txt"
LOG="$PLINTH_HOME/logs/gallery.log"
SCHEDULED_FLAG="$PLINTH_HOME/config/.scheduled_shutdown"
MAINTENANCE_FLAG="$PLINTH_HOME/config/.maintenance"
DAY=$(date +%w)
TIME_NOW=$(date +%H:%M)

mkdir -p "$PLINTH_HOME/logs"

# Maintenance mode — skip all checks
[ -f "$MAINTENANCE_FLAG" ] && exit 0

# If no scheduled shutdown flag, this was a manual boot — skip hour checks
if [ ! -f "$SCHEDULED_FLAG" ]; then
    echo "$(date): Manual boot detected — skipping hour checks" >> "$LOG"
    exit 0
fi

# Remove the flag — it's been acknowledged
rm -f "$SCHEDULED_FLAG"

# Read today's open and close time
OPEN_TIME=$(grep -v '^#' "$CONFIG" | awk -v day="$DAY" '$1 == day {print $2}')
CLOSE_TIME=$(grep -v '^#' "$CONFIG" | awk -v day="$DAY" '$1 == day {print $3}')

if [ -z "$OPEN_TIME" ] || [ -z "$CLOSE_TIME" ]; then
    echo "$(date): No hours found for day $DAY" >> "$LOG"
    exit 1
fi

# Outside opening hours — shut back down
if [[ "$TIME_NOW" < "$OPEN_TIME" ]] || [[ "$TIME_NOW" > "$CLOSE_TIME" ]]; then
    echo "$(date): Boot outside opening hours ($TIME_NOW), shutting down" >> "$LOG"
    sudo /sbin/shutdown -h now
    exit 0
fi

echo "$(date): Gallery opening (scheduled boot)" >> "$LOG"

sleep 60

# TV on commands go here
"$PLINTH_HOME/venv/bin/python3" "$PLINTH_HOME/scripts/tv.py" on

echo "$(date): TVs on" >> "$LOG"