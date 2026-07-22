#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILES=(
  "/etc/slideshow/slideshow.conf"
  "$HOME/.config/slideshow/slideshow.conf"
)

for config_file in "${CONFIG_FILES[@]}"; do
  if [[ -r "$config_file" ]]; then
    # shellcheck source=/dev/null
    source "$config_file"
  fi
done

: "${REMOTE_HASH_URL:?Set REMOTE_HASH_URL in ~/.config/slideshow/slideshow.conf}"
: "${REMOTE_VIDEO_URL:?Set REMOTE_VIDEO_URL in ~/.config/slideshow/slideshow.conf}"

SLIDESHOW_DIR="${SLIDESHOW_DIR:-$HOME/slideshows}"
VIDEO_FILENAME="${VIDEO_FILENAME:-current.mp4}"
PLAYER_SERVICE="${PLAYER_SERVICE:-slideshow-player.service}"
DOWNLOAD_RETRIES="${DOWNLOAD_RETRIES:-3}"

LOCAL_VIDEO="$SLIDESHOW_DIR/$VIDEO_FILENAME"
LOCAL_HASH="$SLIDESHOW_DIR/hash.txt"
LOCK_FILE="$SLIDESHOW_DIR/.slideshow-update.lock"

mkdir -p "$SLIDESHOW_DIR"

exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

if [[ -s "$LOCAL_VIDEO" ]]; then
  systemctl --user start "$PLAYER_SERVICE"
fi

tmp_dir="$(mktemp -d "$SLIDESHOW_DIR/.download.XXXXXX")"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

curl_args=(
  --fail
  --silent
  --show-error
  --location
  --retry "$DOWNLOAD_RETRIES"
  --retry-delay 2
)

curl "${curl_args[@]}" --output "$tmp_dir/hash.txt" "$REMOTE_HASH_URL"
remote_hash="$(awk 'NF {print tolower($1); exit}' "$tmp_dir/hash.txt")"

if [[ ! "$remote_hash" =~ ^[a-f0-9]{64}$ ]]; then
  echo "Remote hash is not a valid SHA-256 value: $remote_hash" >&2
  exit 1
fi

local_hash=""
if [[ -f "$LOCAL_HASH" ]]; then
  local_hash="$(awk 'NF {print tolower($1); exit}' "$LOCAL_HASH")"
fi

if [[ -s "$LOCAL_VIDEO" && "$remote_hash" == "$local_hash" ]]; then
  systemctl --user start "$PLAYER_SERVICE"
  exit 0
fi

curl "${curl_args[@]}" --output "$tmp_dir/slideshow.mp4" "$REMOTE_VIDEO_URL"
actual_hash="$(sha256sum "$tmp_dir/slideshow.mp4" | awk '{print tolower($1)}')"

if [[ "$actual_hash" != "$remote_hash" ]]; then
  echo "Downloaded video hash mismatch. Expected $remote_hash but got $actual_hash." >&2
  exit 1
fi

install -m 0644 "$tmp_dir/slideshow.mp4" "$LOCAL_VIDEO.tmp"
printf '%s\n' "$remote_hash" > "$LOCAL_HASH.tmp"

mv -f "$LOCAL_VIDEO.tmp" "$LOCAL_VIDEO"
mv -f "$LOCAL_HASH.tmp" "$LOCAL_HASH"

systemctl --user restart "$PLAYER_SERVICE"
