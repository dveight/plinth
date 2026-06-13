#!/bin/bash
# ─────────────────────────────────────────────────────────────
# Plinth — Gallery Art Install System
# https://github.com/dveight/plinth
# ─────────────────────────────────────────────────────────────

set -e

REPO="https://github.com/dveight/plinth.git"
PLINTH_HOME="$HOME/plinth"
USER_NAME="$(whoami)"
LOG="/tmp/plinth-install.log"

# ── Colours ───────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

log()     { echo -e "${GREEN}▶${NC} $1" | tee -a "$LOG"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $1" | tee -a "$LOG"; }
error()   { echo -e "${RED}✗${NC}  $1" | tee -a "$LOG"; exit 1; }
section() { echo -e "\n${BOLD}── $1 ──────────────────────────────────────${NC}"; }

# ─────────────────────────────────────────────────────────────
section "Plinth Installer"
echo -e " Repo    : $REPO"
echo -e " User    : $USER_NAME"
echo -e " Home    : $PLINTH_HOME"
echo -e " Log     : $LOG"
echo ""

# ── Confirm ───────────────────────────────────────────────────
read -rp "Continue? (y/n): " CONFIRM </dev/tty
[[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

# ── Dependencies ──────────────────────────────────────────────
section "Dependencies"
DEPS=(git mpv curl)
sudo apt-get update -qq

for DEP in "${DEPS[@]}"; do
    if ! command -v "$DEP" &>/dev/null; then
        log "Installing $DEP"
        sudo apt-get install -y "$DEP" >> "$LOG" 2>&1
    else
        log "$DEP already installed"
    fi
done

# ── Clone repo ────────────────────────────────────────────────
section "Repository"

if [ -d "$PLINTH_HOME/.git" ]; then
    warn "Plinth already cloned — pulling latest"
    git -C "$PLINTH_HOME" fetch --tags >> "$LOG" 2>&1
else
    log "Cloning $REPO"
    git clone "$REPO" "$PLINTH_HOME" >> "$LOG" 2>&1
    git -C "$PLINTH_HOME" fetch --tags >> "$LOG" 2>&1
fi

# Checkout latest tag, fall back to main
LATEST_TAG=$(git -C "$PLINTH_HOME" describe --tags \
    $(git -C "$PLINTH_HOME" rev-list --tags --max-count=1) 2>/dev/null || true)

if [ -n "$LATEST_TAG" ]; then
    log "Checking out tag $LATEST_TAG"
    git -C "$PLINTH_HOME" checkout "$LATEST_TAG" >> "$LOG" 2>&1
else
    warn "No tags found — using main"
    git -C "$PLINTH_HOME" checkout main >> "$LOG" 2>&1
fi

# ── Directory structure ───────────────────────────────────────
section "Directories"
mkdir -p "$PLINTH_HOME"/{config/gallery,config/mpv,logs,media,scripts,systemd}
log "Directory structure created"

# ── Permissions ───────────────────────────────────────────────
section "Permissions"
find "$PLINTH_HOME" -type d -exec chmod 750 {} \;
find "$PLINTH_HOME" -type f -name "*.sh" -exec chmod 750 {} \;
find "$PLINTH_HOME" -type f ! -name "*.sh" -exec chmod 640 {} \;
log "Permissions set"

# ── Environment ───────────────────────────────────────────────
section "Environment"
BASHRC="$HOME/.bashrc"

if grep -q "PLINTH_HOME" "$BASHRC"; then
    warn "PLINTH_HOME already in .bashrc — skipping"
else
    cat >> "$BASHRC" <<EOF

# ── Plinth ────────────────────────────────────────────────────
export PLINTH_HOME="\$HOME/plinth"
export PATH="\$PLINTH_HOME/scripts:\$PATH"
alias plinth="\$PLINTH_HOME/scripts/plinth.sh"
EOF
    log "PLINTH_HOME and aliases added to .bashrc"
fi

# ── Sudoers ───────────────────────────────────────────────────
section "Sudoers"
SUDOERS_FILE="/etc/sudoers.d/plinth"
if [ -f "$SUDOERS_FILE" ]; then
    warn "Sudoers entry already exists — skipping"
else
    echo "$USER_NAME ALL=(ALL) NOPASSWD: /sbin/shutdown" \
        | sudo tee "$SUDOERS_FILE" > /dev/null
    sudo chmod 440 "$SUDOERS_FILE"
    log "Sudoers entry created"
fi

# ── Root cron ─────────────────────────────────────────────────
section "Cron"
CRON_JOB="* * * * * $PLINTH_HOME/scripts/gallery-close.sh"

if crontab -l 2>/dev/null | grep -q "gallery-close"; then
    warn "Cron job already exists — skipping"
else
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    log "Root cron job added"
fi

# ── Autologin ─────────────────────────────────────────────────
section "Autologin"
GDM_CONF="/etc/gdm3/custom.conf"

if grep -q "AutomaticLoginEnable=true" "$GDM_CONF" 2>/dev/null; then
    warn "Autologin already configured — skipping"
else
    sudo sed -i "/\[daemon\]/a AutomaticLoginEnable=true\nAutomaticLogin=$USER_NAME" \
        "$GDM_CONF"
    log "Autologin configured for $USER_NAME"
fi

# ── Systemd user services ─────────────────────────────────────
section "Systemd Services"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"

for SERVICE in plinth-player gallery-open; do
    SRC="$PLINTH_HOME/systemd/${SERVICE}.service"
    DEST="$SYSTEMD_USER_DIR/${SERVICE}.service"

    if [ ! -f "$SRC" ]; then
        warn "Service file not found: $SRC — skipping"
        continue
    fi

    if [ -L "$DEST" ]; then
        warn "$SERVICE.service symlink already exists — skipping"
    else
        ln -s "$SRC" "$DEST"
        log "Symlinked $SERVICE.service"
    fi
done

systemctl --user daemon-reload
systemctl --user enable plinth-player.service
systemctl --user enable gallery-open.service
log "User services enabled"

# ── Linger (user services survive without login) ──────────────
sudo loginctl enable-linger "$USER_NAME"
log "Linger enabled for $USER_NAME"

# ── Hours config ──────────────────────────────────────────────
section "Hours"
HOURS_FILE="$PLINTH_HOME/config/gallery/hours.txt"

if [ -f "$HOURS_FILE" ]; then
    warn "hours.txt already exists — skipping"
else
    cat > "$HOURS_FILE" <<EOF
# Plinth — Gallery Hours
# Day (0=Sun, 1=Mon ... 6=Sat) | open  | close
0 11:00 17:00
1 09:00 19:00
2 09:00 19:00
3 09:00 19:00
4 09:00 19:00
5 09:00 21:00
6 09:00 17:00
EOF
    log "Default hours.txt created — edit to match gallery hours"
fi

# ── MPV config ───────────────────────────────────────────────
section "MPV Config"
MPV_CONF_SRC="$PLINTH_HOME/config/mpv/mpv.conf"
MPV_CONF_DEST="$HOME/.config/mpv/mpv.conf"

if [ ! -f "$MPV_CONF_SRC" ]; then
    warn "No mpv.conf found in $MPV_CONF_SRC — skipping"
else
    mkdir -p "$HOME/.config/mpv"
    if [ -f "$MPV_CONF_DEST" ]; then
        warn "mpv.conf already exists at $MPV_CONF_DEST — backing up"
        cp "$MPV_CONF_DEST" "${MPV_CONF_DEST}.bak"
        log "Backup saved to ${MPV_CONF_DEST}.bak"
    fi
    cp "$MPV_CONF_SRC" "$MPV_CONF_DEST"
    log "mpv.conf copied to $MPV_CONF_DEST"
fi

# ── Done ──────────────────────────────────────────────────────
section "Done"
echo -e " ${GREEN}Plinth installed successfully${NC}"
echo -e " Version  : ${LATEST_TAG:-main}"
echo -e " Home     : $PLINTH_HOME"
echo ""
echo -e " ${YELLOW}Next steps:${NC}"
echo -e "  1. Edit hours  : nano \$PLINTH_HOME/config/gallery/hours.txt"
echo -e "  2. Add media   : copy files to \$PLINTH_HOME/media/"
echo -e "  3. Set BIOS    : enable wake timer, set after power loss to 'Power On'"
echo -e "  4. Reboot      : sudo reboot"
echo ""