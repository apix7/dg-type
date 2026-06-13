# dg-type

`dg-type` is a small Linux dictation tool that streams microphone audio to Deepgram and types the transcript into the focused window.

It is designed for KDE/Wayland setups where normal Wayland text injection is restricted. It uses `ydotoold` for focused-window typing, supports a KDE hotkey wrapper, and includes a small whisrs-style recording overlay.

## Features

- Deepgram live transcription via WebSocket streaming
- Live interim typing with correction/backspace rewriting
- Focused-window text injection through `ydotool`
- KDE shortcut wrapper
- Bottom-screen voice indicator overlay
- Root systemd service for `ydotoold` socket setup
- Reuses credentials from the official `dg` / `deepctl` profile when available

## Requirements

- Linux with systemd
- Python 3.14 or compatible Python 3
- Deepgram API key
- `ydotool` client in `PATH`
- `ydotoold` available either:
  - as `vendor/ydotoold`
  - from the system `PATH`
  - or via `DG_TYPE_YDOTOOLD=/path/to/ydotoold`
- Python packages:
  - `pyaudio`
  - `websockets`
  - optional for overlay: `python3-gobject`, `python3-cairo`, GTK 3

On Fedora Kinoite/Silverblue, install desktop/system packages with Flatpak/rpm-ostree only when needed. The installer only writes user files and a root systemd unit under `/etc/systemd/system`.

## Install

From a local checkout:

```bash
./install.sh
```

One-liner install from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/YOU/dg-type/main/install-remote.sh | DG_TYPE_REPO_URL=https://github.com/YOU/dg-type.git bash
```

Replace `YOU` with your GitHub username or organization.

Then verify:

```bash
dg-type --check
```

Expected:

```text
Deepgram key: found via ...
Python dependency pyaudio: ok
Python dependency websockets.sync.client: ok
Text injector: ydotool
```

## Deepgram Auth

Preferred setup:

```bash
dg-easy setup
```

or use the official Deepgram CLI login flow.

Fallbacks supported by `dg-type`:

- `DEEPGRAM_API_KEY`
- `~/.config/deepgram-api-key`

Do not commit API keys or Deepgram config files.

## Usage

Final-only transcription:

```bash
dg-type
```

Low-latency live typing:

```bash
dg-type --live
```

Delay start so you can focus the target field:

```bash
dg-type --live --delay 3
```

Run again to stop an active dictation session:

```bash
dg-type
```

## KDE Shortcut

Install creates:

```text
~/.local/share/applications/dg-type-hotkey.desktop
```

In KDE:

1. Open `System Settings`
2. Go to `Keyboard` -> `Shortcuts`
3. Search for `Deepgram Dictation Hotkey`
4. Assign your shortcut

You can also bind directly to:

```text
~/.local/bin/dg-type-hotkey
```

## Overlay

The overlay is enabled by default. Disable it:

```bash
dg-type --no-overlay
```

Theme options:

```bash
DG_TYPE_OVERLAY_THEME=carbon dg-type --live
DG_TYPE_OVERLAY_THEME=ember dg-type --live
DG_TYPE_OVERLAY_THEME=cyan dg-type --live
```

Overlay visuals and animation constants are adapted from [`y0sif/whisrs`](https://github.com/y0sif/whisrs), MIT License.

## Security Notes

`ydotoold` runs as root so it can access `/dev/uinput`. This is required for reliable focused-window typing on KDE Wayland, but it means the daemon can inject keyboard events. Review `systemd/dg-type-ydotoold.service` before installing.

The systemd unit creates a user-owned socket at:

```text
/run/user/<uid>/.ydotool_socket
```

Only the installing user should be able to access it.

## Files

```text
bin/dg-type                  main dictation command
bin/dg-type-hotkey           KDE shortcut wrapper
bin/dg-type-overlay          animated overlay
desktop/dg-type-hotkey.desktop
systemd/dg-type-ydotoold.service
install.sh
LICENSE
```

`vendor/` is intentionally ignored by git. If you need to bundle `ydotoold` locally for your machine, place it at `vendor/ydotoold` before running `install.sh`.

## Troubleshooting

Check service:

```bash
sudo systemctl status dg-type-ydotoold.service --no-pager
journalctl -u dg-type-ydotoold.service -b --no-pager
```

Check socket:

```bash
ls -l /run/user/$(id -u)/.ydotool_socket
```

Check dictation:

```bash
dg-type --check
```
