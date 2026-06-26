#!/bin/bash

if [ -f /tmp/disable_plinth_player ]; then
    exit 0
fi

PLINTH_HOME="${PLINTH_HOME:-$HOME/plinth}"
PLAYLIST="$PLINTH_HOME/playlist.txt"
MEDIA_DIR="$PLINTH_HOME/media"
LOG="$PLINTH_HOME/logs/gallery.log"

# Clear existing playlist
rm -f "$PLAYLIST"

# ── Local media ───────────────────────────────────────────────
find "$MEDIA_DIR" -maxdepth 1 -type f \( \
    -iname "*.mov" \
    -o -iname "*.mp4" \
    -o -iname "*.mkv" \
    -o -iname "*.avi" \
\) | sort -V >> "$PLAYLIST"

# ── USB media ─────────────────────────────────────────────────
for MOUNT in /media/$USER/*/; do
    [ -d "$MOUNT" ] || continue
    find "$MOUNT" -maxdepth 2 -type f \( \
        -iname "*.mov" \
        -o -iname "*.mp4" \
        -o -iname "*.mkv" \
        -o -iname "*.avi" \
    \) | sort -V >> "$PLAYLIST"
done

# ── Bail if nothing found ─────────────────────────────────────
if [ ! -s "$PLAYLIST" ]; then
    echo "$(date): No media found" >> "$LOG"
    exit 1
fi

echo "$(date): Playlist generated with $(wc -l < "$PLAYLIST") files" >> "$LOG"
unclutter -idle 0 & mpv --playlist="$PLAYLIST"
