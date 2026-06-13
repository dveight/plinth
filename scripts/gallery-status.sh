#!/bin/bash

PLINTH_HOME="${PLINTH_HOME:-$HOME/plinth}"
CONFIG="$PLINTH_HOME/config/gallery/hours.txt"
LOG="$PLINTH_HOME/logs/gallery.log"
DAY=$(date +%w)
TIME_NOW=$(date +%H:%M)
DAY_NAMES=("Sunday" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday")

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BOLD}=== Plinth Status ===${NC}"
echo -e " Host    : $(hostname)"
echo -e " Time    : $(date '+%A %d %B %Y %H:%M')"
echo -e " Home    : $PLINTH_HOME"
echo ""

# ── Hours ─────────────────────────────────────────────────────
echo -e "${BOLD}── Opening Hours ──────────────────────────────${NC}"
while IFS= read -r line; do
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
    DAY_NUM=$(echo "$line" | awk '{print $1}')
    OPEN=$(echo "$line" | awk '{print $2}')
    CLOSE=$(echo "$line" | awk '{print $3}')
    DAY_LABEL="${DAY_NAMES[$DAY_NUM]}"
    if [ "$DAY_NUM" == "$DAY" ]; then
        echo -e " ${GREEN}▶ ${DAY_LABEL}: ${OPEN} – ${CLOSE} (today)${NC}"
    else
        echo -e "   ${DAY_LABEL}: ${OPEN} – ${CLOSE}"
    fi
done < "$CONFIG"

# ── Open or closed right now ───────────────────────────────────
OPEN_TIME=$(grep -v '^#' "$CONFIG" | awk -v day="$DAY" '$1 == day {print $2}')
CLOSE_TIME=$(grep -v '^#' "$CONFIG" | awk -v day="$DAY" '$1 == day {print $3}')

echo ""
echo -e "${BOLD}── Status ─────────────────────────────────────${NC}"
if [[ "$TIME_NOW" > "$OPEN_TIME" ]] && [[ "$TIME_NOW" < "$CLOSE_TIME" ]]; then
    echo -e " Gallery  : ${GREEN}OPEN${NC} (closes $CLOSE_TIME)"
else
    echo -e " Gallery  : ${RED}CLOSED${NC} (opens $OPEN_TIME)"
fi

# ── Media ─────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}── Media ──────────────────────────────────────${NC}"
MEDIA_COUNT=$(find "$PLINTH_HOME/media" -maxdepth 1 -type f \( \
    -iname "*.mov" -o -iname "*.mp4" \
    -o -iname "*.mkv" -o -iname "*.avi" \
\) 2>/dev/null | wc -l)
echo -e " Local    : ${MEDIA_COUNT} file(s)"

USB_COUNT=0
for MOUNT in /media/$USER/*/; do
    [ -d "$MOUNT" ] || continue
    COUNT=$(find "$MOUNT" -maxdepth 2 -type f \( \
        -iname "*.mov" -o -iname "*.mp4" \
        -o -iname "*.mkv" -o -iname "*.avi" \
    \) 2>/dev/null | wc -l)
    USB_COUNT=$((USB_COUNT + COUNT))
done
echo -e " USB      : ${USB_COUNT} file(s)"

if [ -f "$PLINTH_HOME/playlist.txt" ]; then
    PLAYLIST_COUNT=$(wc -l < "$PLINTH_HOME/playlist.txt")
    echo -e " Playlist : ${PLAYLIST_COUNT} file(s)"
else
    echo -e " Playlist : ${YELLOW}not generated${NC}"
fi

# ── Systemd services ──────────────────────────────────────────
echo ""
echo -e "${BOLD}── Services ───────────────────────────────────${NC}"
for SERVICE in plinth gallery-open; do
    STATUS=$(systemctl --user is-active ${SERVICE}.service 2>/dev/null)
    if [ "$STATUS" == "active" ]; then
        echo -e " ${SERVICE} : ${GREEN}running${NC}"
    elif [ "$STATUS" == "inactive" ]; then
        echo -e " ${SERVICE} : ${YELLOW}inactive${NC}"
    else
        echo -e " ${SERVICE} : ${RED}${STATUS}${NC}"
    fi
done

# ── Last log lines ────────────────────────────────────────────
echo ""
echo -e "${BOLD}── Recent Log ─────────────────────────────────${NC}"
if [ -f "$LOG" ]; then
    tail -5 "$LOG" | while IFS= read -r line; do
        echo -e " ${BLUE}${line}${NC}"
    done
else
    echo -e " ${YELLOW}No log file found${NC}"
fi

echo ""
