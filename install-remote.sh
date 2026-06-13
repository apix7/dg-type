#!/usr/bin/env bash
set -euo pipefail

repo_url="${DG_TYPE_REPO_URL:-}"
install_dir="${DG_TYPE_INSTALL_DIR:-$HOME/.local/share/dg-type-src}"

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

detect_pm() {
  if need_cmd rpm-ostree; then echo "rpm-ostree"; return; fi
  if need_cmd dnf; then echo "dnf"; return; fi
  if need_cmd apt-get; then echo "apt"; return; fi
  if need_cmd pacman; then echo "pacman"; return; fi
  if need_cmd zypper; then echo "zypper"; return; fi
  echo "unknown"
}

print_system_deps() {
  pm="$(detect_pm)"
  cat <<EOF
Missing system dependencies. Install these first, then rerun this installer.

Detected package manager: $pm

Fedora / DNF:
  sudo dnf install -y git python3-pip python3-devel portaudio-devel ydotool python3-gobject python3-cairo gtk3

Fedora Kinoite / Silverblue:
  distrobox enter fedora -- sudo dnf install -y git python3-pip python3-devel portaudio-devel ydotool python3-gobject python3-cairo gtk3
  # If you do not use distrobox for the hotkey wrapper, layer ydotool on the host:
  # sudo rpm-ostree install ydotool && reboot

Debian / Ubuntu:
  sudo apt-get update
  sudo apt-get install -y git python3-pip python3-dev portaudio19-dev ydotool python3-gi python3-cairo gir1.2-gtk-3.0

Arch:
  sudo pacman -S --needed git python python-pip portaudio ydotool python-gobject gtk3

openSUSE:
  sudo zypper install git python3-pip python3-devel portaudio-devel ydotool python3-gobject python3-cairo gtk3
EOF
}

ensure_python_deps() {
  python3 - <<'PY' >/dev/null 2>&1 && return 0
import pyaudio
import websockets.sync.client
PY

  if ! need_cmd python3; then
    echo "Missing python3." >&2
    print_system_deps
    exit 1
  fi

  if ! python3 -m pip --version >/dev/null 2>&1; then
    echo "Missing python3 pip." >&2
    print_system_deps
    exit 1
  fi

  python3 -m pip install --user --upgrade websockets pyaudio
}

fetch_repo() {
  mkdir -p "$(dirname "$install_dir")"
  if need_cmd git; then
    if [[ -d "$install_dir/.git" ]]; then
      git -C "$install_dir" pull --ff-only
    elif [[ -e "$install_dir" ]]; then
      cat >&2 <<EOF
Install directory already exists and is not a git checkout:
  $install_dir

Move it aside or set DG_TYPE_INSTALL_DIR to another path, then rerun.
EOF
      exit 1
    else
      git clone "$repo_url" "$install_dir"
    fi
    return
  fi

  echo "Missing git." >&2
  print_system_deps
  exit 1
}

main() {
  if [[ -z "$repo_url" ]]; then
    cat >&2 <<'EOF'
Set DG_TYPE_REPO_URL to your repo before using the remote installer.

Example:
  curl -fsSL https://raw.githubusercontent.com/<owner>/dg-type/main/install-remote.sh | DG_TYPE_REPO_URL=https://github.com/<owner>/dg-type.git bash
EOF
    exit 1
  fi

  fetch_repo
  ensure_python_deps
  "$install_dir/install.sh"
}

main "$@"
