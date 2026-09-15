#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy"
bar_config_dir="$config_dir/bar"
stats_plugin_dir="$config_dir/plugins/local.system-stats"

mkdir -p "$bar_config_dir/modules" "$bar_config_dir/scripts" "$stats_plugin_dir"
install -m 0644 "$repo_dir/bar/modules/local.fan-control.qml" "$bar_config_dir/modules/local.fan-control.qml"
install -m 0755 "$repo_dir/bar/scripts/cpu-temperature" "$bar_config_dir/scripts/cpu-temperature"
install -m 0755 "$repo_dir/bar/scripts/omarchy-fan-fixed-set" "$bar_config_dir/scripts/omarchy-fan-fixed-set"
install -m 0755 "$repo_dir/bar/scripts/omarchy-fan-fixed-status" "$bar_config_dir/scripts/omarchy-fan-fixed-status"
install -m 0644 "$repo_dir/plugins/local.system-stats/manifest.json" "$stats_plugin_dir/manifest.json"
install -m 0644 "$repo_dir/plugins/local.system-stats/BarWidget.qml" "$stats_plugin_dir/BarWidget.qml"
install -m 0644 "$repo_dir/plugins/local.system-stats/Panel.qml" "$stats_plugin_dir/Panel.qml"
install -m 0755 "$repo_dir/plugins/local.system-stats/system-stats" "$stats_plugin_dir/system-stats"

sudo install -m 0755 "$repo_dir/bin/omarchy-fan-max-toggle" /usr/local/bin/omarchy-fan-max-toggle
sudo install -m 0755 "$repo_dir/bin/omarchy-fan-max-status" /usr/local/bin/omarchy-fan-max-status
sudo install -m 0755 "$repo_dir/bin/omarchy-fan-curve-status" /usr/local/bin/omarchy-fan-curve-status
sudo install -m 0755 "$repo_dir/bin/omarchy-fan-curve-set" /usr/local/bin/omarchy-fan-curve-set

echo "Fan control and system-stats plugin installed. Check the shell.json entries and run 'omarchy restart shell'."
