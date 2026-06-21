#!/bin/bash
# ─────────────────────────────────────────────────────────────
# Plinth — Uninstaller
# https://github.com/dveight/plinth
# ─────────────────────────────────────────────────────────────

set -e

PLINTH_HOME="${PLINTH_HOME:-$HOME/plinth}"
USER_NAME="$(whoami)"
LOG="/tmp/plinth-uninstall.log"

# ── Colours ───────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

log()     { echo -e "${GREEN}▶${NC} $1" | tee -a "$LOG"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $1" | tee -a "$LOG"; }
section() { echo -e "\n${BOLD}── $1 ──────────────────────────────────────${NC}"; }

# ─────────────────────────────────────────────────────────────
section "Plinth Uninstaller"
echo -e " User    : $USER_NAME"
echo -e " Home    : $PLINTH_HOME"
echo ""
echo -e " ${RED}This will remove all Plinth services, config and scripts.${NC}"
echo -e " ${YELLOW}Media files in $PLINTH_HOME/media will NOT be deleted.${NC}"
echo ""

read -rp "Are you sure? (yes/n): " CONFIRM </dev/tty
[[ "$CONFIRM" == "yes" ]] || { echo "Aborted."; exit 0; }

# ── Stop and disable user services ───────────────────────────
section "Systemd Services"
for SERVICE in plinth-player gallery-open; do
    if systemctl --user is-active "${SERVICE}.service" &>/dev/null; then
        systemctl --user stop "${SERVICE}.service"
        log "Stopped $SERVICE.service"
    else
        warn "$SERVICE.service was not running"
    fi

    if systemctl --user is-enabled "${SERVICE}.service" &>/dev/null; then
        systemctl --user disable "${SERVICE}.service"
        log "Disabled $SERVICE.service"
    fi

    SYMLINK="$HOME/.config/systemd/user/${SERVICE}.service"
    if [ -L "$SYMLINK" ]; then
        rm "$SYMLINK"
        log "Removed symlink: $SYMLINK"
    fi
done

systemctl --user daemon-reload
log "Systemd daemon reloaded"

# ── Cron ──────────────────────────────────────────────────────
section "Cron"
if crontab -l 2>/dev/null | grep -q "gallery-close"; then
    crontab -l 2>/dev/null | grep -v "gallery-close" | crontab -
    log "Cron job removed"
else
    warn "No Plinth cron job found"
fi

# ── Sudoers ───────────────────────────────────────────────────
section "Sudoers"
SUDOERS_FILE="/etc/sudoers.d/plinth"
if [ -f "$SUDOERS_FILE" ]; then
    sudo rm "$SUDOERS_FILE"
    log "Sudoers entry removed"
else
    warn "No sudoers entry found"
fi

# ── Autologin ─────────────────────────────────────────────────
section "Autologin"
GDM_CONF="/etc/gdm3/custom.conf"
if grep -q "AutomaticLoginEnable=true" "$GDM_CONF" 2>/dev/null; then
    sudo sed -i '/AutomaticLoginEnable=true/d' "$GDM_CONF"
    sudo sed -i "/AutomaticLogin=$USER_NAME/d" "$GDM_CONF"
    log "Autologin removed"
else
    warn "No autologin config found"
fi

# ── Bashrc ────────────────────────────────────────────────────
section "Environment"
BASHRC="$HOME/.bashrc"
if grep -q "PLINTH_HOME" "$BASHRC"; then
    sed -i '/# ── Plinth/,/^alias plinth/d' "$BASHRC"
    log "Removed Plinth entries from .bashrc"
else
    warn "No Plinth entries found in .bashrc"
fi

# ── Linger ────────────────────────────────────────────────────
section "Linger"
if loginctl show-user "$USER_NAME" 2>/dev/null | grep -q "Linger=yes"; then
    read -rp "   Disable linger for $USER_NAME? (y/n): " LINGER </dev/tty
    if [[ "$LINGER" =~ ^[Yy]$ ]]; then
        sudo loginctl disable-linger "$USER_NAME"
        log "Linger disabled"
    else
        warn "Linger left enabled"
    fi
fi

# ── MPV config ────────────────────────────────────────────────
section "MPV Config"
MPV_CONF="$HOME/.config/mpv/mpv.conf"
MPV_BACKUP="${MPV_CONF}.bak"
if [ -f "$MPV_CONF" ]; then
    if [ -f "$MPV_BACKUP" ]; then
        mv "$MPV_BACKUP" "$MPV_CONF"
        log "Restored mpv.conf from backup"
    else
        rm "$MPV_CONF"
        log "Removed mpv.conf (no backup found)"
    fi
else
    warn "No mpv.conf found"
fi

# ── Plinth directory ──────────────────────────────────────────
section "Files"
if [ -d "$PLINTH_HOME" ]; then
    read -rp "   Remove $PLINTH_HOME? Media files will be lost (yes/n): " REMOVE_DIR </dev/tty
    if [[ "$REMOVE_DIR" == "yes" ]]; then
        rm -rf "$PLINTH_HOME"
        log "Removed $PLINTH_HOME"
    else
        warn "Leaving $PLINTH_HOME in place"
    fi    
    # Remove venv separately so it's always cleaned up
    if [ -d "$PLINTH_HOME/venv" ]; then
        rm -rf "$PLINTH_HOME/venv"
        log "Removed venv"
    fi
else
    warn "$PLINTH_HOME not found"
fi


# ── Done ──────────────────────────────────────────────────────
section "Done"
echo -e " ${GREEN}Plinth uninstalled${NC}"
echo ""
echo -e " ${YELLOW}Note:${NC} Installed packages (git, mpv) were not removed."
echo -e " To remove them manually:"
echo -e "   sudo apt remove git mpv"
echo ""
echo -e " Log: $LOG"
echo ""