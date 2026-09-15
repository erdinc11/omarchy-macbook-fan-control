# Omarchy MacBook Fan Control

Custom Quickshell modules for Omarchy on a 2013 MacBook Air 11-inch. They show system usage and CPU temperature in the top bar and provide fan control.

Features:

- Shows CPU temperature in a single top-bar icon.
- Shows CPU, RAM, and SSD usage in a system-stats top-bar icon.
- Sets the fan to maximum speed with Max Fan.
- Provides a 20–100% fixed fan-speed slider.
- Allows editing Min/Mid/Max fan-curve temperatures.
- Returns to the automatic curve with one button.

## Installation

```bash
./install.sh
```

The installer copies privileged helper commands to `/usr/local/bin`, the fan-control module to `~/.config/omarchy/bar/`, and the system-stats plugin to `~/.config/omarchy/plugins/local.system-stats/`. The right section of `shell.json` must contain:

```json
{
  "id": "local.fan-control",
  "type": "qml"
},
{
  "id": "local.system-stats"
}
```

After installation:

```bash
omarchy restart shell
```

Fan control requires the `mbpfan` service and the Apple SMC fan sysfs interface. Fan-speed actions are authorized through the graphical polkit prompt.
