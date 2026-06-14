# dg-type

`dg-type` is a Linux dictation helper that streams microphone audio to Deepgram and types the transcript into the currently focused window.

It is built for KDE Plasma Wayland setups where normal text injection is blocked. The reliable path uses `ydotoold` for keyboard injection, plus a KDE hotkey wrapper and a small bottom-screen voice overlay.

## Features

- Deepgram live WebSocket transcription
- Low-latency interim typing with correction/backspace rewriting
- Focused-window typing through `ydotool`
- KDE shortcut launcher
- Bottom-center voice activity overlay
- Root systemd unit for persistent `ydotoold` socket setup
- Deepgram credentials from the official `dg` / `deepctl` profile when available

## Requirements

- Linux with systemd
- Python 3.10 or newer
- Deepgram API key
- `ydotool` client available where `dg-type` runs
- `ydotoold` binary available to install as the root daemon
- Python packages: `pyaudio`, `websockets`
- Optional overlay packages: GTK 3, PyGObject, PyCairo

On Fedora Kinoite/Silverblue, prefer running Python and CLI dependencies in distrobox. The installer does not layer rpm-ostree packages by itself.

## Install

Local checkout:

```bash
git clone https://github.com/apix7/dg-type.git
cd dg-type
./install.sh
```

One-liner from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/apix7/dg-type/main/install-remote.sh | DG_TYPE_REPO_URL=https://github.com/apix7/dg-type.git bash
```

The installer copies user commands to `~/.local/bin`, installs the desktop launcher, copies `ydotoold` to `/usr/local/bin/dg-type-ydotoold`, and enables `/etc/systemd/system/dg-type-ydotoold.service`.

Verify:

```bash
dg-type --check
```

Expected result:

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

```bash
export DEEPGRAM_API_KEY=...
```

```text
~/.config/deepgram-api-key
```

Do not commit API keys, Deepgram config files, shell history containing keys, or `.env` files.

## Usage

Low-latency dictation:

```bash
dg-type --live
```

Delay start so you can focus the target field:

```bash
dg-type --live --delay 3
```

Final-only mode:

```bash
dg-type
```

Run `dg-type` again while it is listening to stop the active session.

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

The hotkey wrapper uses live mode by default:

```text
dg-type --live --delay 0 --silence-timeout 15 --no-auto-setup
```

## Configuration

Set these environment variables when needed:

```bash
DG_TYPE_DISTROBOX=fedora
```

Name of the distrobox container used by `dg-type-hotkey`. Default is `fedora`.

```bash
DG_TYPE_KEYTERMS="project name,technical term,person name"
```

Comma-separated Deepgram keyterms. Defaults to empty so the public package does not ship personal vocabulary.

```bash
DG_TYPE_YDOTOOLD=/path/to/ydotoold
```

Override the daemon binary used by `install.sh`.

```bash
DG_TYPE_OVERLAY_THEME=carbon
```

Overlay theme. Supported values: `carbon`, `ember`, `cyan`.

```bash
DG_TYPE_INSTALL_DIR=$HOME/.local/share/dg-type-src
```

Remote installer checkout path.

```bash
DG_TYPE_REPO_URL=https://github.com/apix7/dg-type.git
```

Git repo URL used by `install-remote.sh`.

## Overlay

The overlay is enabled by default. Disable it:

```bash
dg-type --no-overlay
```

Overlay visuals and animation constants are adapted from [`y0sif/whisrs`](https://github.com/y0sif/whisrs), MIT License.

## Security Notes

`ydotoold` runs as root because it needs `/dev/uinput`. This is what makes focused-window typing reliable on KDE Wayland.

That also means the daemon can inject keyboard events. Review `systemd/dg-type-ydotoold.service` before installing and only expose the socket to your user.

The systemd unit creates:

```text
/run/user/<uid>/.ydotool_socket
```

The socket is installed with mode `0600` and owner `<uid>:<gid>`.

## Files

```text
bin/dg-type                         main dictation command
bin/dg-type-hotkey                  KDE shortcut wrapper
bin/dg-type-overlay                 animated overlay
desktop/dg-type-hotkey.desktop      launcher installed for KDE shortcuts
systemd/dg-type-ydotoold.service    root daemon service template
install.sh                          local installer
install-remote.sh                   one-liner remote installer
LICENSE
```

`vendor/` is ignored by git. If you need to use a local `ydotoold` binary for one machine, place it at `vendor/ydotoold` before running `install.sh`; do not commit it.

## Troubleshooting

Check the daemon:

```bash
sudo systemctl status dg-type-ydotoold.service --no-pager
journalctl -u dg-type-ydotoold.service -b --no-pager
```

Check the socket:

```bash
ls -l /run/user/$(id -u)/.ydotool_socket
```

Check dependencies and injector:

```bash
dg-type --check
```

Check hotkey logs:

```bash
tail -n 100 ~/.cache/dg-type/hotkey.log
```

## Public Repo Checklist

Before pushing:

```bash
git status --short --ignored
rg -n --hidden --glob '!.git/**' --glob '!vendor/**' --glob '!README.md' 'DEEPGRAM_API_KEY=.+|/var/home|/home/|password\s*=|secret\s*=|Token [A-Za-z0-9]{10,}'
```

Only source files should be tracked. Credentials, logs, bytecode caches, tarballs, and local `vendor/` binaries should stay untracked or ignored.
