#!/bin/sh
set -eu

env_vars=""
[ -n "${DISPLAY:-}" ] && env_vars="$env_vars DISPLAY"
[ -n "${WAYLAND_DISPLAY:-}" ] && env_vars="$env_vars WAYLAND_DISPLAY"
[ -n "${XAUTHORITY:-}" ] && env_vars="$env_vars XAUTHORITY"
[ -n "${XDG_CURRENT_DESKTOP:-}" ] && env_vars="$env_vars XDG_CURRENT_DESKTOP"
[ -n "${XDG_SESSION_TYPE:-}" ] && env_vars="$env_vars XDG_SESSION_TYPE"
[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] && env_vars="$env_vars DBUS_SESSION_BUS_ADDRESS"

if [ -n "$env_vars" ]; then
  systemctl --user import-environment $env_vars

  if command -v dbus-update-activation-environment >/dev/null 2>&1; then
    dbus-update-activation-environment --systemd $env_vars
  fi
fi

systemctl --user daemon-reload
systemctl --user enable --now slideshow-update.timer
systemctl --user start slideshow-update.service
