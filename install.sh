#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/bar"

mkdir -p "$config_dir/modules" "$config_dir/scripts"
install -m 0644 "$repo_dir/bar/modules/local.fan-control.qml" "$config_dir/modules/local.fan-control.qml"
install -m 0755 "$repo_dir/bar/scripts/cpu-temperature" "$config_dir/scripts/cpu-temperature"
install -m 0755 "$repo_dir/bar/scripts/omarchy-fan-fixed-set" "$config_dir/scripts/omarchy-fan-fixed-set"
install -m 0755 "$repo_dir/bar/scripts/omarchy-fan-fixed-status" "$config_dir/scripts/omarchy-fan-fixed-status"

sudo install -m 0755 "$repo_dir/bin/omarchy-fan-max-toggle" /usr/local/bin/omarchy-fan-max-toggle
sudo install -m 0755 "$repo_dir/bin/omarchy-fan-max-status" /usr/local/bin/omarchy-fan-max-status
sudo install -m 0755 "$repo_dir/bin/omarchy-fan-curve-status" /usr/local/bin/omarchy-fan-curve-status
sudo install -m 0755 "$repo_dir/bin/omarchy-fan-curve-set" /usr/local/bin/omarchy-fan-curve-set

echo "Fan kontrolü kuruldu. shell.json kaydını kontrol edip 'omarchy restart shell' çalıştırın."
