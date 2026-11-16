#!/usr/bin/env bash
# personal-setup · Linux host, ROOT half. Run once, on the host:
#   sudo bash ~/setup/root-steps.sh [new-hostname] [user]
# Everything a fresh Ubuntu desktop needs from apt, the login shell, hardware groups for the rigs,
# the machine name (Tailscale follows it), and ethernet ahead of Wi-Fi.
set -euo pipefail
NEW_HOSTNAME=${1:-}
USER_NAME=${2:-${SUDO_USER:-$USER}}

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y git zsh neovim ripgrep fd-find curl wget rsync \
  build-essential v4l-utils usbutils python3-venv
# Debian packages fd as fdfind; the nvim config and the docs call it fd
ln -sf "$(command -v fdfind)" /usr/local/bin/fd
# the snap curl cannot write into dot-directories (breaks `curl | sh` installers); apt's replaces it
if snap list curl >/dev/null 2>&1; then snap remove curl; fi

chsh -s "$(command -v zsh)" "$USER_NAME"
# arms are USB serial (dialout), cameras are V4L2 (video)
usermod -aG dialout,video,plugdev "$USER_NAME"

if [ -n "$NEW_HOSTNAME" ]; then
  hostnamectl set-hostname "$NEW_HOSTNAME"
  sed -i -E "s/^(127\.0\.1\.1[[:space:]]+).*/\1$NEW_HOSTNAME/" /etc/hosts
  # the tailnet name follows the OS hostname after a restart; set it explicitly so it applies now
  command -v tailscale >/dev/null && tailscale set --hostname "$NEW_HOSTNAME" || true
fi

# Ethernet ahead of the Wi-Fi dongle once a cable is in (the fix opti-dev needed on 2026-09-15;
# netplan may revert it after a reboot — re-run this script if the default route is Wi-Fi again)
if nmcli -t -f NAME con show 2>/dev/null | grep -qx netplan-eno1; then
  nmcli con mod netplan-eno1 ipv4.method auto ipv4.route-metric 100 ipv6.route-metric 100 connection.autoconnect yes
  nmcli con up netplan-eno1 2>/dev/null || echo "eno1 not up (no cable?) — it will come up when one is plugged in"
fi
echo "root steps done for $USER_NAME on $(hostname). Log out and back in for the shell + groups, then re-run: bash ~/setup/user-tools.sh"
