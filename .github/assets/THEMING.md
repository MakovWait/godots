## Overview
To change the theme simply open Settings and choose desired preset

![image](https://github.com/MakovWait/godots/assets/39778897/0bf06bff-6c28-4282-b11e-d05106b30c8a)

In order to load custom theme read the notes below.

## Custom themes

Godots is fully compatible with Godot4 themes. To get them work, simply put desired properties to [theme] section in godots.cfg file that is located in Godots userdata folder (user://godots.cfg)

> Tip: user:// folder can be simply opened with Setting Folder button in Settings

![image](https://github.com/MakovWait/godots/assets/39778897/9082ecc7-12b4-4e0d-84b2-9a28d1fc0126)

## Sample (user://godots.cfg)

```ini
[theme]
interface/editor/main_font_size=14
interface/editor/custom_display_scale=1.25
interface/theme/preset="Default"
interface/theme/icon_and_font_color=0
interface/theme/base_color=Color(0.21, 0.24, 0.29, 1)
interface/theme/accent_color=Color(0.44, 0.73, 0.98, 1)
interface/theme/contrast=0.3
interface/theme/corner_radius=4
interface/theme/additional_spacing=0.5
```
>Note: every property from [resource] section of editor_settings-4.tres (Godot editor cfg file) can be copy pasted to the [theme] section above.
