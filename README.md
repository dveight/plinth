# Plinth

Gallery art installation system for HP t530 thin clients running Ubuntu 25.10. Manages scheduled power, display control, and media playback for unattended gallery installations.

## Overview

Plinth runs video plinth on loop across one or more displays, turning the system and connected TVs on and off according to gallery opening hours. It is designed to be installed on multiple thin clients, each configured per gallery via a single hours file.

## Requirements

- HP t530 thin client
- Ubuntu 25.10
- GNOME / GDM
- `mpv`
- `git`
- `curl`

## Installation

```bash
curl -sL https://raw.githubusercontent.com/dveight/plinth/main/install.sh | bash
```

The installer will:

- Install dependencies (git, mpv, curl)
- Clone the repo to `~/plinth`
- Configure `PLINTH_HOME` and aliases in `.bashrc`
- Set up autologin via GDM
- Symlink and enable systemd user services
- Add a root cron job for scheduled shutdown
- Configure sudoers for passwordless shutdown
- Copy `mpv.conf` to `~/.config/mpv/`
- Create a default `hours.txt` if one does not exist

## Directory Structure

```
~/plinth/
├── config/
│   ├── gallery/
│   │   └── hours.txt        # Gallery opening hours
│   └── mpv/
│       └── mpv.conf         # MPV configuration
├── logs/
│   └── gallery.log          # Runtime log
├── media/                   # Local plinth files
├── playlist.txt             # Generated at runtime
├── scripts/
│   ├── plinth.sh           # Plinth control CLI
│   ├── gallery-close.sh     # Scheduled shutdown (run by root cron)
│   ├── gallery-open.sh      # TV power on (run by systemd at boot)
│   ├── gallery-status.sh    # Status overview
│   └── play.sh              # Playlist generation and mpv launch
└── systemd/
    ├── user/
│       ├── plinth-player.service       # Runs play.sh after graphical session
        └── gallery-open.service        # Runs gallery-open.sh at boot
```

## Configuration

### Opening Hours

Edit `~/plinth/config/gallery/hours.txt` to set gallery hours. No other files need to change.

```
# Day (0=Sun, 1=Mon ... 6=Sat) | open  | close
0 11:00 17:00
1 09:00 19:00
2 09:00 19:00
3 09:00 19:00
4 09:00 19:00
5 09:00 21:00
6 09:00 17:00
```

### Media

Place video files in `~/plinth/media/`. Supported formats: `.mov`, `.mp4`, `.mkv`, `.avi`.

Files are played in alphabetical order. Media on mounted USB drives is automatically included and sorted alongside local files.

### MPV

MPV is configured via `~/plinth/config/mpv/mpv.conf`, which is copied to `~/.config/mpv/mpv.conf` during install.

## Usage

After installation, source `.bashrc` or open a new terminal to use the aliases:

```bash
plinth on          # Enable plinth and start service
plinth off         # Disable plinth and stop service
plinth status      # Show plinth service status
plinth hours       # Show gallery status overview
plinth maintenance on   # Disable hour checks (persists until disabled)
plinth maintenance off  # Re-enable hour checks
plinth maintenance      # Show maintenance mode status

plinth              # Full gallery status overview
```

## Scheduled Operation

The system manages itself automatically:

| Event | Behaviour |
|---|---|
| BIOS wake at open time | `gallery-open.sh` checks hours, turns TVs on |
| Cron at close time | `gallery-close.sh` turns TVs off, shuts down |
| Manual shutdown → manual boot | No hour checks applied, boots freely |
| Scheduled shutdown → BIOS boot | Hour checks applied |
| Boot outside hours | Shuts back down automatically |
| Power outage | Boots freely, no hour checks |

### BIOS Configuration

On the HP t530, enter BIOS (F10) and configure:

- **Power Management → Wake On Timer** — set to gallery open time
- **After Power Loss** — set to `Power On`

Note: The BIOS supports a single daily wake time. Set it to the earliest open time across the week (09:00). Sunday's later open (11:00) is handled automatically by `gallery-open.sh`.

## TV Control

TV on/off commands are stubbed in `gallery-open.sh` and `gallery-close.sh`. Uncomment and configure the appropriate method per installation:

### IR (no network on TV)

Requires a USB IR blaster (e.g. FLIRC) with an IR emitter extension cable adhered to the TV's IR receiver eye.

```bash
# Install LIRC
sudo apt install lirc

# Record remote codes
irrecord -d /dev/lirc0 ~/lg-tv.conf

# Test
irsend SEND_ONCE LG-TV KEY_POWER
```

### LAN (LG WebOS)

```bash
pip3 install aiowebostv
```

Enable **TV On With Mobile** in the TV's network settings. Pair once on first run.

### LAN (Sony BRAVIA)

```bash
pip3 install bravia-tv
```

## Galleries

Each gallery has its own branch. Gallery-specific configuration (hours, media) lives on that branch.

| Hostname | Branch |
|---|---|
| popper | popper |
| butler | butler |
| russell | russell |
| wittgenstein | wittgenstein |

## Updating

On the thin client:

```bash
cd ~/plinth
git fetch --tags
git checkout <tag>
```

Or to pull the latest gallery branch:

```bash
git pull origin $(hostname)
```

## Uninstalling

```bash
bash ~/plinth/uninstall.sh
```

Removes services, cron, sudoers, autologin, and `.bashrc` entries. Prompts before removing the `~/plinth` directory. Media files require explicit confirmation to delete.

## Branches and Releases

- `main` is always stable
- Gallery branches (`popper`, `butler`, etc.) hold per-gallery config
- Releases are tagged (`v1.0`, `v1.1`, etc.)
- The installer pins to the latest tag, falling back to `main` if no tags exist

## License

MIT
