#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
uid="$(id -u)"
gid="$(id -g)"
tmp_files=()

cleanup() {
  for file in "${tmp_files[@]}"; do
    [[ -n "$file" ]] && rm -f "$file"
  done
}
trap cleanup EXIT

install -Dm0755 "$repo_dir/bin/dg-type" "$HOME/.local/bin/dg-type"
install -Dm0755 "$repo_dir/bin/dg-type-hotkey" "$HOME/.local/bin/dg-type-hotkey"
install -Dm0755 "$repo_dir/bin/dg-type-overlay" "$HOME/.local/bin/dg-type-overlay"

desktop_tmp="$(mktemp)"
tmp_files+=("$desktop_tmp")
sed "s|@HOME@|$HOME|g" "$repo_dir/desktop/dg-type-hotkey.desktop" > "$desktop_tmp"
install -Dm0644 "$desktop_tmp" "$HOME/.local/share/applications/dg-type-hotkey.desktop"

ydotoold_source="${DG_TYPE_YDOTOOLD:-}"
if [[ -z "$ydotoold_source" ]]; then
  if [[ -x "$repo_dir/vendor/ydotoold" ]]; then
    ydotoold_source="$repo_dir/vendor/ydotoold"
  elif command -v ydotoold >/dev/null 2>&1; then
    ydotoold_source="$(command -v ydotoold)"
  else
    echo "Missing ydotoold. Install ydotool, or set DG_TYPE_YDOTOOLD=/path/to/ydotoold." >&2
    exit 1
  fi
fi
if [[ ! -x "$ydotoold_source" ]]; then
  echo "ydotoold is not executable: $ydotoold_source" >&2
  exit 1
fi

service_tmp="$(mktemp)"
tmp_files+=("$service_tmp")
sed \
  -e "s|@UID@|$uid|g" \
  -e "s|@GID@|$gid|g" \
  "$repo_dir/systemd/dg-type-ydotoold.service" > "$service_tmp"

sudo install -Dm0755 "$ydotoold_source" /usr/local/bin/dg-type-ydotoold
sudo install -Dm0644 "$service_tmp" /etc/systemd/system/dg-type-ydotoold.service
sudo systemctl daemon-reload
sudo systemctl enable --now dg-type-ydotoold.service

echo "Installed. Run: dg-type --check"
