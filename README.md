# slideshows
Slideshows Displayed on Department Displays

## Ubuntu MP4 slideshow player

This repository includes a systemd user-service setup for an Ubuntu display device that:

- starts automatically when the default desktop user auto-logs in;
- checks a remote `hash.txt` file at login and every 5 minutes;
- downloads a new MP4 only when the hash changes;
- verifies the downloaded MP4 with SHA-256 before replacing the local copy;
- restarts VLC in fullscreen loop mode after a successful update.

The services are intended to run as the desktop user that is logged into the display. Because the display device auto-logs in a default user on boot, this setup is unattended after the one-time install: no one needs to start VLC or run an update command after reboots.

### Files

| Path | Purpose |
| --- | --- |
| `scripts/install-slideshow.sh` | One-time installer for the display device |
| `scripts/slideshow-update.sh` | Downloads and verifies updated videos |
| `scripts/slideshow-session-start.sh` | Auto-login bootstrap that imports the desktop environment and starts the services |
| `config/slideshow.conf` | Slideshow URL and download settings |
| `systemd/user/slideshow-player.service` | Runs VLC fullscreen and looped |
| `systemd/user/slideshow-update.service` | One-shot update check |
| `systemd/user/slideshow-update.timer` | Runs the update check on boot and every 5 minutes |

### Prepare the remote files

Upload both files to the remote location:

```bash
sha256sum slideshow.mp4 | awk '{print $1}' > hash.txt
```

The hash in `hash.txt` must match the MP4 available at the configured video URL.

### Install on the Ubuntu display device

Update `config/slideshow.conf` with the remote `hash.txt` and video URLs, then run this once from the repository checkout as the default desktop user that auto-logs in:

```bash
./scripts/install-slideshow.sh
```

The installer copies the scripts, `config/slideshow.conf`, and systemd user units into the auto-login user's home directory, installs `vlc`, `curl`, and `flock`, enables the timer, and creates `~/.config/autostart/slideshow-session.desktop`. On future boots, the desktop auto-login starts the bootstrap script, the bootstrap script starts the timer/update service, and VLC starts or restarts as needed. If the network is unavailable but a previously downloaded video exists, the cached video still starts.

By default, the local video is stored at `~/slideshows/current.mp4`. If you change that path in `scripts/slideshow-update.sh`, also update `systemd/user/slideshow-player.service`.

### Useful commands on the device

```bash
systemctl --user status slideshow-update.timer
systemctl --user status slideshow-player.service
journalctl --user -u slideshow-update.service -u slideshow-player.service --since today
systemctl --user restart slideshow-player.service
systemctl --user start slideshow-update.service
```
