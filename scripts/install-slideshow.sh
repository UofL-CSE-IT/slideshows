#!/bin/sh
set -eu

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/install-slideshow.sh [--skip-packages]

Options:
  --skip-packages    Do not install vlc/curl with apt-get
  -h, --help         Show this help
USAGE
}

INSTALL_PACKAGES="yes"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --skip-packages)
      INSTALL_PACKAGES="no"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)"
REPO_CONFIG="$REPO_DIR/config/slideshow.conf"

if [ ! -r "$REPO_CONFIG" ]; then
  echo "Missing readable config file: $REPO_CONFIG" >&2
  exit 1
fi

. "$REPO_CONFIG"

: "${REMOTE_HASH_URL:?Set REMOTE_HASH_URL in config/slideshow.conf}"
: "${REMOTE_VIDEO_URL:?Set REMOTE_VIDEO_URL in config/slideshow.conf}"

if [ "$INSTALL_PACKAGES" = "yes" ]; then
  sudo apt-get update
  sudo apt-get install -y vlc curl util-linux
fi

install -d \
  "$HOME/.local/bin" \
  "$HOME/.config/autostart" \
  "$HOME/.config/slideshow" \
  "$HOME/.config/systemd/user"

install -m 0755 "$REPO_DIR/scripts/slideshow-update.sh" "$HOME/.local/bin/slideshow-update"
install -m 0755 "$REPO_DIR/scripts/slideshow-session-start.sh" "$HOME/.local/bin/slideshow-session-start"

install -m 0644 "$REPO_DIR/systemd/user/slideshow-player.service" "$HOME/.config/systemd/user/"
install -m 0644 "$REPO_DIR/systemd/user/slideshow-update.service" "$HOME/.config/systemd/user/"
install -m 0644 "$REPO_DIR/systemd/user/slideshow-update.timer" "$HOME/.config/systemd/user/"
install -m 0644 "$REPO_CONFIG" "$HOME/.config/slideshow/slideshow.conf"

cat > "$HOME/.config/autostart/slideshow-session.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Slideshow Startup
Comment=Start the unattended VLC slideshow updater
Exec=$HOME/.local/bin/slideshow-session-start
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

systemctl --user daemon-reload
systemctl --user enable --now slideshow-update.timer

if [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
  "$HOME/.local/bin/slideshow-session-start"
else
  systemctl --user start slideshow-update.service
  echo "No desktop display environment detected. VLC will start automatically at the next graphical auto-login."
fi

echo "Slideshow updater installed. The auto-login desktop session will run it unattended on boot."
