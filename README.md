# Omarchy MacBook Fan Control

Custom Quickshell module for Omarchy on a 2013 MacBook Air 11-inch. It shows CPU temperature in the top bar and provides fan control.

Features:

- Shows CPU temperature in a single top-bar icon.
- Sets the fan to maximum speed with Max Fan.
- Provides a 20–100% fixed fan-speed slider.
- Allows editing Min/Mid/Max fan-curve temperatures.
- Returns to the automatic curve with one button.

## Installation

```bash
./install.sh
```

The installer copies privileged helper commands to `/usr/local/bin` and the Quickshell module to `~/.config/omarchy/bar/`. The right section of `shell.json` must contain:

```json
{
  "id": "local.fan-control",
  "type": "qml"
}
```

After installation:

```bash
omarchy restart shell
```

Fan control requires the `mbpfan` service and the Apple SMC fan sysfs interface. Fan-speed actions are authorized through the graphical polkit prompt.
