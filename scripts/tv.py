#!/usr/bin/env python3
# ─────────────────────────────────────────────────────────────
# Plinth — TV Control
# ─────────────────────────────────────────────────────────────

import sys
import os
from samsungtvws import SamsungTVWS

CONFIG = os.path.expanduser("~/plinth/config/gallery/tv.conf")
TOKEN_FILE = os.path.expanduser("~/plinth/config/gallery/.tv-token")

def read_config():
    config = {}
    with open(CONFIG) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#'):
                key, _, value = line.partition('=')
                config[key.strip()] = value.strip()
    return config

def usage():
    print("Usage: tv {on|off|status}")
    sys.exit(1)

def get_tv():
    if not os.path.exists(CONFIG):
        print(f"No tv.conf found at {CONFIG}")
        sys.exit(1)
    config = read_config()
    ip = config.get('TV_IP')
    if not ip:
        print("TV_IP not set in tv.conf")
        sys.exit(1)
    return SamsungTVWS(host=ip, token_file=TOKEN_FILE)

def main():
    if len(sys.argv) < 2:
        usage()

    command = sys.argv[1].lower()

    if command == 'on':
        tv = get_tv()
        tv.send_key('KEY_POWERON')
        print("TV on")

    elif command == 'off':
        tv = get_tv()
        tv.send_key('KEY_POWEROFF')
        print("TV off")

    elif command == 'status':
        tv = get_tv()
        info = tv.rest_device_info()
        print(f"TV status: {info}")

    else:
        usage()

if __name__ == '__main__':
    main()