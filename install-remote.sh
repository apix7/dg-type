#!/usr/bin/env bash
set -euo pipefail

repo_url="${DG_TYPE_REPO_URL:-https://github.com/YOUR_GITHUB_USERNAME/dg-type.git}"
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
  sudo dnf install -y python3-pip python3-devel portaudio-devel ydotool python3-gobject python3-cairo gtk3

Fedora Kinoite / Silverblue:
  distrobox enter fedora -- sudo dnf install -y python3-pip python3-devel portaudio-devel ydotool python3-gobject python3-cairo gtk3
  sudo rpm-ostree install ydotool
  reboot

Debian / Ubuntu:
  sudo apt-get update
  sudo apt-get install -y python3-pip python3-dev portaudio19-dev ydotool python3-gi python3-cairo gir1.2-gtk-3.0

Arch:
  sudo pacman -S --needed python python-pip portaudio ydotool python-gobject gtk3

openSUSE:
  sudo zypper install python3-pip python3-devel portaudio-devel ydotool python3-gobject python3-cairo gtk3
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
    else
      rm -rf "$install_dir"
      git clone "$repo_url" "$install_dir"
    fi
    return
  fi

  echo "Missing git." >&2
  print_system_deps
  exit 1
}

main() {
  if [[ "$repo_url" == *"YOUR_GITHUB_USERNAME"* ]]; then
    cat >&2 <<'EOF'
Set DG_TYPE_REPO_URL to your repo before using the remote installer.

Example:
  curl -fsSL https://raw.githubusercontent.com/YOU/dg-type/main/install-remote.sh | DG_TYPE_REPO_URL=https://github.com/YOU/dg-type.git bash
EOF
    exit 1
  fi

  fetch_repo
  ensure_python_deps
  "$install_dir/install.sh"
}

main "$@"
