class_name SettingsWindow
extends AcceptDialog

signal _setting_changed(setting: Setting, new_value: Variant)
signal _settings_changed

var _prev_rect: Rect2


func _prepare_settings() -> Array:
	return [
		SettingChangeObserved(SettingCfg(
			"application/config/auto_close",
			Config.AUTO_CLOSE,
			SettingCheckbox,
			tr("Close on launch.")
		)),

		SettingRestartRequired(SettingChangeObserved(SettingCfg(
			"application/config/scale",
			Config.SAVED_EDSCALE.bake_default(-1),
			SettingScale,
		))),

		SettingChangeObserved(SettingCfg(
			"application/config/default_projects_path",
			Config.DEFAULT_PROJECTS_PATH,
			SettingFilePath,
			tr("Default folder to scan/import projects from.")
		)),

		SettingFiltered(SettingRestartRequired(SettingChangeObserved(SettingCfg(
			"application/config/use_system_titlebar",
			Config.USE_SYSTEM_TITLE_BAR,
			SettingCheckbox
		))), func() -> bool: return DisplayServer.has_feature(DisplayServer.FEATURE_EXTEND_TO_TITLE)),
		
		SettingRestartRequired(SettingChangeObserved(SettingCfg(
			"application/config/use_native_file_dialog",
			Config.USE_NATIVE_FILE_DIALOG,
			SettingCheckbox
		))),
		
		SettingChangeObserved(SettingCfg(
			"application/config/remember_window_rect",
			Config.REMEMBER_WINDOW_SIZE,
			SettingCheckbox,
			tr("Restore last window size and position on startup.")
		)),
		
		SettingRestartRequired(SettingChangeObserved(SettingCfg(
			"application/theme/preset",
			ConfigFileValue.new(
				IConfigFileLike.of_config(Config._cfg), 
				"theme",
				"interface/theme/preset"
			).bake_default("Default"),
			SettingThemePreset,
		))),

		SettingCustomPresetTrigger(SettingRestartRequired(SettingChangeObserved(SettingCfg(
			"application/theme/base_color",
			ConfigFileValue.new(
				IConfigFileLike.of_config(Config._cfg), 
				"theme",
				"interface/theme/base_color"
			).bake_default(Color(0.21, 0.24, 0.29)),
			SettingColorPicker,
			tr("Base color for the theme. Affects the background and primary UI elements.")
		)))),
		
		SettingCustomPresetTrigger(SettingRestartRequired(SettingChangeObserved(SettingCfg(
			"application/theme/accent_color",
			ConfigFileValue.new(
				IConfigFileLike.of_config(Config._cfg), 
				"theme",
				"interface/theme/accent_color"
			).bake_default(Color(0.44, 0.73, 0.98)),
			SettingColorPicker,
			tr("Accent color for the theme. Used for highlights and interactive elements.")
		)))),

		SettingCustomPresetTrigger(SettingRestartRequired(SettingChangeObserved(SettingCfg(
			"application/theme/contrast",
			ConfigFileValue.new(
				IConfigFileLike.of_config(Config._cfg), 
				"theme",
				"interface/theme/contrast"
			).bake_default(0.3),
			SettingSlider,
			tr("Contrast ratio for the theme. Affects the brightness of the UI.")
		)))),

		SettingRestartRequired(SettingChangeObserved(SettingCfg(
			"application/advanced/downloads_path",
			Config.DOWNLOADS_PATH,
			SettingFilePath,
			tr("Temp dir for downloaded zips.")
		))),

		SettingRestartRequired(SettingChangeObserved(SettingCfg(
			"application/advanced/versions_path",
			Config.VERSIONS_PATH,
			SettingFilePath,
			tr("Dir for downloaded editors.")
		))),

		SettingChangeObserved(SettingCfg(
			"application/advanced/show_orphan_editor_explorer",
			Config.SHOW_ORPHAN_EDITOR,
			SettingCheckbox,
			tr("Check if there are some leaked Godot binaries on the filesystem that can be safely removed. For advanced users.")
		)),

		SettingChangeObserved(SettingCfg(
			"application/advanced/allow_install_to_not_empty_dir",
			Config.ALLOW_INSTALL_TO_NOT_EMPTY_DIR,
			SettingCheckbox,
			tr("By default the project installing is forbidden if the target dir is not empty. To allow it, check the checkbox.")
		)),

		SettingChangeObserved(SettingCfg(
			"application/advanced/check_only_stable_updates",
			Config.ONLY_STABLE_UPDATES,
			SettingCheckbox,
			tr("Will check only stable Godots releases.")
		)),
		SettingChangeObserved(SettingCfg(
			"network/http_proxy/host",
			Config.HTTP_PROXY_HOST,
			SettingText,
			tr("Host")
		)),
		SettingChangeObserved(SettingCfg(
			"network/http_proxy/port",
			Config.HTTP_PROXY_PORT,
			SettingPort,
			tr("Port")
		)),
	]


func _init() -> void:
	theme_changed.connect(func() -> void:
		(%Inspector as Control).add_theme_stylebox_override(
			"panel", get_theme_stylebox("panel", "Tree")
		)
		(%RestartContainer as Control).add_theme_stylebox_override(
			"panel", get_theme_stylebox("panel", "Tree")
		)
		(%HideRestartButton as Button).icon = get_theme_icon("Close", "EditorIcons")
		(%WarningRect as Button).icon = get_theme_icon("StatusWarning", "EditorIcons")
		(%WarningRect as Button).self_modulate = get_theme_color("warning_color", "Editor") * Color(1, 1, 1, 0.6)
		(%RestartInfoLabel as Label).self_modulate = get_theme_color("warning_color", "Editor") * Color(1, 1, 1, 0.6)
		
		(%OpenConfigFileButton as Button).icon = get_theme_icon("Load", "EditorIcons")
		
		var sections_root := (%SectionsTree as Tree).get_root()
		if sections_root:
			for child in sections_root.get_children():
				child.set_custom_font(0, get_theme_font("bold", "EditorFonts"))
	)


func _ready() -> void:
	visibility_changed.connect(func() -> void:
		if not visible:
			_prev_rect = Rect2i(position, size)
			Config.save()
	)

	var title_text := tr("Settings") 
	var set_title_text := func(pattern: String) -> void:
		title = pattern % title_text
	title = title_text
	_settings_changed.connect(func() -> void:
		set_title_text.call("(*) %s")
	)
	Config.saved.connect(func() -> void:
		set_title_text.call("%s")
	)
	
	get_ok_button().text = tr("Save & Close")
	
	
	var left_vb := %LeftVB as VBoxContainer
	left_vb.custom_minimum_size = Vector2(190, 0) * Config.EDSCALE
	
	
	var right_vb: = %RightVB as VBoxContainer
	right_vb.custom_minimum_size = Vector2(300, 0) * Config.EDSCALE
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	
	(%RestartInfoLabel as Label).text = tr("Godots must be restarted for changes to take effect.")
	(%RestartButton as Button).pressed.connect(func() -> void:
		Config.save()
		get_tree().quit()
		OS.create_process(OS.get_executable_path(), OS.get_cmdline_args())
#		OS.set_restart_on_exit(true, OS.get_cmdline_args())
#		get_tree().quit()
	, CONNECT_DEFERRED & CONNECT_ONE_SHOT)
	(%HideRestartButton as Button).flat = true
	(%HideRestartButton as Button).pressed.connect(func() -> void:
		(%RestartContainer as PanelContainer).hide()
	)
	(%RestartContainer as Control).hide()
	
	(%OpenConfigFileButton as Button).pressed.connect(func() -> void:
		var config_path := ProjectSettings.globalize_path(Config.APP_CONFIG_PATH.get_base_dir())
		OS.shell_show_in_file_manager(config_path)
	)
	
	_setup_settings()


func raise_settings() -> void:
	if _prev_rect:
		popup(_prev_rect)
	else:
		popup_centered_clamped(Vector2(600, 400) * Config.EDSCALE, 0.8)


func _setup_settings() -> void:
	var settings := _prepare_settings().filter(func(x: Variant) -> bool: return x != null)
	
	for setting: Setting in settings:
		setting.bind_settings_window(self)
		setting.validate()
		setting.add_control(SettingControlTarget.new(%InspectorVBox, setting.category.raw))
	
	var tree := %SectionsTree as Tree
	tree.item_selected.connect(func() -> void:
		var selected := tree.get_selected()
		if selected:
			var section: Variant = selected.get_metadata(0)
			if section is String:
				_update_settings_visibility(section as String)
	)
	tree.hide_root = true
	var root := tree.create_item()
	var categories := {}
	for setting: Setting in settings:
		var category := setting.category
		if not category.first_lvl in categories:
			categories[category.first_lvl] = Set.new()
		var second_lvls := categories[category.first_lvl] as Set
		second_lvls.append(category.second_lvl) 
	var selected := false
	for first_lvl: String in categories.keys():
		var first_lvl_item := tree.create_item(root)
		first_lvl_item.set_text(0, tr(first_lvl.capitalize()))
		first_lvl_item.set_selectable(0, false)
		first_lvl_item.set_custom_font(0, get_theme_font("bold", "EditorFonts"))
		for second_lvl: String in (categories[first_lvl] as Set).values_unsorted():
			var second_lvl_item := tree.create_item(first_lvl_item)
			second_lvl_item.set_text(0, tr(second_lvl.capitalize()))
			second_lvl_item.set_metadata(0, first_lvl + "/" + second_lvl)
			if not selected:
				second_lvl_item.select(0)
				selected = true


func _update_settings_visibility(section: String) -> void:
	for node in %InspectorVBox.get_children():
		var should_be_visible := node.has_meta("category") and (node.get_meta("category") as String).begins_with(section)
		node.set("visible", should_be_visible)


func SettingCfg(category: String, cfg_value: ConfigFileValue, prop_factory: Variant, tooltip:="") -> Setting:
	if prop_factory is Script:
		prop_factory = func(a1: Variant, a2: Variant, a3: Variant, a4: Variant) -> Setting: 
			return (prop_factory as Script).call("new", a1, a2, a3, a4)
	return ((prop_factory as Callable).call(
		category, 
		cfg_value.ret(),
		tooltip,
		cfg_value.get_baked_default()
	) as Setting).on_value_changed(func(v: Variant) -> void: cfg_value.put_custom(v, IConfigFileLike.of_config(Config._cfg)))


func SettingChangeObserved(origin: Setting) -> Setting:
	return origin.on_value_changed(
		func(new_value: Variant) -> void: 
			_setting_changed.emit(origin, new_value)
			_settings_changed.emit()
	)


func SettingFiltered(origin: Setting, filter: Callable) -> Setting:
	if filter.call():
		return origin
	else:
		return null


func SettingRestartRequired(origin: Setting) -> Setting:
	return origin.on_value_changed(func(_a: Variant) -> void: (%RestartContainer as PanelContainer).show())


func SettingCustomPresetTrigger(origin: Setting) -> Setting:
	return origin.with_meta("__custom_preset_trigger__", "")


class Category:
	var _category: String
	
	var name: String:
		get: return _category.get_file().capitalize()
	
	var first_lvl: String:
		get: return _category.split("/")[0]
	
	var second_lvl: String:
		get: return _category.split("/")[1]
	
	var raw: String:
		get: return _category
	
	func _init(category: String) -> void:
		_category = category
	
	func validate() -> void:
		assert(
			len(_category.split("/")) == 3, 
			"Invalid category %s! Category format is: s/s/s" % _category
		)


class SettingControlTarget:
	var _target: Node
	var _category: String
	
	func _init(target: Node, category: String) -> void:
		_target = target
		_category = category
	
	func add_child(child: Node) -> void:
		child.set_meta("category", _category)
		_target.add_child(child)


class Setting extends RefCounted:
	signal changed(new_value: Variant)
	
	var category: Category
	var _value: Variant
	var _tooltip: String
	var _default_value: Variant
	var _settings_window: SettingsWindow
	
	func _init(name: String, value: Variant, tooltip: String, default_value: Variant) -> void:
		self.category = Category.new(name)
		self._value = value
		self._tooltip = tooltip
		self._default_value = default_value
	
	func add_control(target: SettingControlTarget) -> void:
		pass
	
	func on_value_changed(callback: Callable) -> Setting:
		changed.connect(callback)
		return self
	
	func notify_changed() -> void:
		changed.emit(_value)
	
	func set_value(value: Variant) -> void:
		_value = value
	
	func set_value_and_notify(value: Variant) -> void:
		set_value(value)
		notify_changed()
	
	func validate() -> void:
		category.validate()
		assert(_settings_window != null)
	
	func reset() -> void:
		set_value_and_notify(_default_value)
	
	func value_is_not_default() -> bool:
		return _value != _default_value
	
	func bind_settings_window(settings_window: SettingsWindow) -> Setting:
		_settings_window = settings_window
		return self
	
	func with_meta(name: StringName, value: Variant) -> Setting:
		self.set_meta(name, value)
		return self


class SettingText extends Setting:
	func add_control(target: SettingControlTarget) -> void:
		var timer := CompRefs.Simple.new()
		var control := Comp.new(HBoxContainer, [
			Comp.new(Timer).ref(timer).on_init(
				func(this: Timer) -> void: this.timeout.connect(self.notify_changed)
			),
			CompSettingNameContainer.new(self),
			CompSettingPanelContainer.new(_tooltip, [
				Comp.new(LineEdit).on_init([
					CompInit.TOOLTIP_TEXT(_tooltip),
					CompInit.ADD_THEME_STYLEBOX_OVERRIDE("focus", StyleBoxEmpty.new()),
					CompInit.TEXT(self._value),
					CompInit.SIZE_FLAGS_HORIZONTAL_EXPAND_FILL(),
					CompInit.CUSTOM(func(this: LineEdit) -> void:
						self.on_value_changed(func(new_value: Variant) -> void:
							# don't update text if the user is interacting
							# this prevents the caret from going to postition 0
							if not this.has_focus():
								this.text = new_value
						)
						this.text_changed.connect(func(new_text: Variant) -> void:
							_value = new_text
							(timer.value as Timer).start(1)
						)
						pass\
					)
				])
			])
		])
		control.add_to(target)


class SettingPort extends Setting:
	func add_control(target: SettingControlTarget) -> void:
		var timer := CompRefs.Simple.new()
		var control := Comp.new(HBoxContainer, [
			Comp.new(Timer).ref(timer).on_init(
				func(this: Timer) -> void: this.timeout.connect(self.notify_changed)
			),
			CompSettingNameContainer.new(self),
			CompSettingPanelContainer.new(_tooltip, [
				Comp.new(SpinBox).on_init([
					CompInit.TOOLTIP_TEXT(_tooltip),
					CompInit.ADD_THEME_STYLEBOX_OVERRIDE("focus", StyleBoxEmpty.new()),
					CompInit.SIZE_FLAGS_HORIZONTAL_EXPAND_FILL(),
					CompInit.CUSTOM(func(this: SpinBox) -> void:
						# set valid port range
						this.min_value = 0
						this.max_value = 65535
						self.on_value_changed(func(new_value: Variant) -> void:
							this.value = new_value
						)
						this.value_changed.connect(func(new_text: Variant) -> void:
							_value = new_text
							(timer.value as Timer).start(1)
						)
						pass\
					),
					# set value after so it fits within range
					CompInit.VALUE(self._value)
				])
			])
		])
		control.add_to(target)


class SettingFilePath extends Setting:
	func add_control(target: SettingControlTarget) -> void:
		var file_dialog := CompRefs.Simple.new()
		var line_edit := CompRefs.Simple.new()
		var update_value := func(new_value: String) -> void: 
				set_value_and_notify(new_value)
				line_edit.value.text = new_value
		self.on_value_changed(func(new_value: String) -> void:
			line_edit.value.text = new_value
		)
		var control := Comp.new(HBoxContainer, [
			Comp.new(FileDialog).ref(file_dialog).on_init(func(x: FileDialog) -> void:
				x.access = FileDialog.ACCESS_FILESYSTEM
				x.file_mode = FileDialog.FILE_MODE_OPEN_DIR
				x.dir_selected.connect(func(dir: String) -> void:
					update_value.call(dir)
				)
				pass\
			),
			CompSettingNameContainer.new(self),
			CompSettingPanelContainer.new(_tooltip, [
				Comp.new(HBoxContainer, [
					Comp.new(LineEdit).on_init([
						CompInit.SET_EDITABLE(false),
						CompInit.TOOLTIP_TEXT(_tooltip),
						CompInit.ADD_THEME_STYLEBOX_OVERRIDE("focus", StyleBoxEmpty.new()),
						CompInit.TEXT(self._value),
						CompInit.SIZE_FLAGS_HORIZONTAL_EXPAND_FILL(),
					]).ref(line_edit),
					Comp.new(Button).on_init([
						CompInit.TREE_ENTERED(
							CompInit.SET_THEME_ICON("Load", "EditorIcons")
						),
						CompInit.PRESSED(func(_a: Control) -> void: 
							var dialog := file_dialog.value as FileDialog 
							dialog.current_dir = self._value
							dialog.popup_centered_ratio(0.5)\
						)
					])
				]).on_init([
					CompInit.SIZE_FLAGS_HORIZONTAL_EXPAND_FILL(),
				])
			])
		])
		control.add_to(target)


class CompSettingName extends Comp:
	func _init(name: String, tooltip: String) -> void:
		super._init(Label)
		on_init(func(this: Label) -> void:
			this.mouse_filter = Control.MOUSE_FILTER_PASS
			this.tooltip_text = tooltip
			this.text = tr(name.get_file().capitalize())
			this.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			this.self_modulate = Color(1, 1, 1, 0.6)
			this.clip_text = true
			this.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			pass\
		)


class CompSettingNameContainer extends Comp:
	func _init(setting: Setting) -> void:
		super._init(HBoxContainer)
		on_init([
			CompInit.SIZE_FLAGS_HORIZONTAL_EXPAND_FILL()
		])
		var reset_btn := CompRefs.Simple.new()
		setting.on_value_changed(func(_a: Variant) -> void:
			reset_btn.value.visible = setting.value_is_not_default()
		)
		children([
			CompSettingName.new(setting.category.name, setting._tooltip),
			Comp.new(Button).on_init([
				CompInit.PRESSED(func(_a: Control) -> void:
					setting.reset()\
				),
				CompInit.CUSTOM(func(this: Control) -> void:
					this.visible = setting.value_is_not_default()\
				),
				CompInit.SET_FLAT(),
				CompInit.TREE_ENTERED(
					CompInit.SET_THEME_ICON("Reload", "EditorIcons")
				),
			]).ref(reset_btn)
		])


class SettingCheckbox extends Setting:
	func add_control(target: SettingControlTarget) -> void:
		var control := Comp.new(HBoxContainer, [
			CompSettingNameContainer.new(self),
			CompSettingPanelContainer.new(_tooltip, [
				Comp.new(CheckBox).on_init([
					CompInit.TOOLTIP_TEXT(_tooltip),
					CompInit.CUSTOM(func(this: CheckBox) -> void:
						self.on_value_changed(func(new_value: Variant) -> void:
							this.button_pressed = new_value
						)
						this.button_pressed = _value as bool
						this.size_flags_horizontal = Control.SIZE_EXPAND_FILL
						this.toggled.connect(func(v: bool) -> void: self.set_value_and_notify(v))
						pass\
					),
					CompInit.SET_FLAT(),
					CompInit.ADD_THEME_STYLEBOX_OVERRIDE("focus", StyleBoxEmpty.new()),
				])
			])
		])
		control.add_to(target)


class CompSettingPanelContainer extends Comp:
	func _init(tooltip: String, children: Array) -> void:
		super._init(PanelContainer, children)
		on_init([
			CompInit.TOOLTIP_TEXT(tooltip),
			CompInit.SIZE_FLAGS_HORIZONTAL_EXPAND_FILL(),
			CompInit.TREE_ENTERED(
				CompInit.CUSTOM(func(this: PanelContainer) -> void:
					var set_bg := func() -> void:
						var bg := StyleBoxFlat.new()
						bg.bg_color = this.get_theme_color("dark_color_2", "Editor")
						this.add_theme_stylebox_override("panel", bg)
					this.get_tree().root.theme_changed.connect(func() -> void:
						set_bg.call()
					)
					set_bg.call()
					pass\
				),
			),
		])


class SettingOptionButton extends Setting:
	var _options: Dictionary
	var _fallback_option: String
	
	func _init(name: String, value: Variant, tooltip: String, default_value: Variant, options: Dictionary, fallback_option: String) -> void:
		super._init(name, value, tooltip, default_value)
		self._options = options
		self._fallback_option = fallback_option
	
	func add_control(target: SettingControlTarget) -> void:
		var update_selected_value := func(this: OptionButton) -> void:
			this.clear()
			var item_idx := 0
			var item_to_select_was_found := false
			for key: int in _options.keys():
				this.add_item(_options[key].name as String, key)
				if _options[key].value == self._value:
					this.selected = item_idx
					item_to_select_was_found = true
				item_idx += 1
			
			if not item_to_select_was_found:
				this.add_item(_fallback_option)
				this.selected = item_idx
		
		var control := Comp.new(HBoxContainer, [
			CompSettingNameContainer.new(self),
			CompSettingPanelContainer.new(_tooltip, [
				Comp.new(OptionButton).on_init([
					CompInit.TOOLTIP_TEXT(_tooltip),
					CompInit.SIZE_FLAGS_HORIZONTAL_EXPAND_FILL(),
					CompInit.SET_FLAT(),
					CompInit.ADD_THEME_STYLEBOX_OVERRIDE("focus", StyleBoxEmpty.new()),
					CompInit.CUSTOM(func(this: OptionButton) -> void:
						self.on_value_changed(func(_a: Variant) -> void:
							update_selected_value.call(this)
						)
						update_selected_value.call(this)
						this.self_modulate = Color(1, 1, 1, 0.6)
						this.item_selected.connect(func(item_idx: int) -> void:
							var id := this.get_item_id(item_idx)
							var entry: Variant = _options.get(id, null)
							if entry:
								self.set_value_and_notify(entry.value)
						)
						pass\
					)
				])
			])
		])
		control.add_to(target)


func SettingScale(a1: String, a2: Variant, a3: String, a4: Variant) -> SettingOptionButton:
	return SettingOptionButton.new(a1, a2, a3, a4,
		{
			1: {
				"name": "{0} ({1}%)".format([tr("Auto"), Config.AUTO_EDSCALE * 100]),
				"value": -1
			},
			2: {
				"name": "75%",
				"value": 0.75
			},
			3: {
				"name": "100%",
				"value": 1
			},
			4: {
				"name": "125%",
				"value": 1.25
			},
			5: {
				"name": "150%",
				"value": 1.50
			},
			6: {
				"name": "175%",
				"value": 1.75
			},
			7: {
				"name": "200%",
				"value": 2
			},
			8: {
				"name": "225%",
				"value": 2.25
			},
		}, tr("Custom")
	)


class ThemePresetOptionButton extends SettingOptionButton:
	func add_control(target: SettingControlTarget) -> void:
		_settings_window._setting_changed.connect(func(setting: Setting, new_val: Variant) -> void:
			if setting.has_meta("__custom_preset_trigger__"):
				self.set_value_and_notify("Custom")
		)
		Comp.new(Button).on_init([
			CompInit.TEXT(tr("Custom Theme Guide")),
			CompInit.TREE_ENTERED(
				CompInit.SET_THEME_ICON("ExternalLink", "EditorIcons")
			),
			CompInit.PRESSED(func(_c: Control) -> void:
				OS.shell_open(
					"https://github.com/MakovWait/godots/blob/main/.github/assets/THEMING.md"
				)\
			)
		]).add_to(target)
		super.add_control(target)


func SettingThemePreset(a1: String, a2: String, a3: String, a4: Variant) -> ThemePresetOptionButton:
	var preset_names := [
		"Default",
		"Breeze Dark",
		"Godot 2",
		"Godot Dash",
		"Gray",
		"Light",
		"Solarized (Dark)",
		"Solarized (Light)",
		"Black (OLED)",
		"Custom"
	]
	var options := {}
	for i in range(len(preset_names)):
		options[i + 1] = {
			'name': preset_names[i],
			'value': preset_names[i],
		}
	return ThemePresetOptionButton.new(a1, a2, a3, a4,
		options, tr("Custom")
	)


class SettingColorPicker extends Setting:
	func add_control(target: SettingControlTarget) -> void:
		var color_button := CompRefs.Simple.new()
		var control := Comp.new(HBoxContainer, [
			CompSettingNameContainer.new(self),
			CompSettingPanelContainer.new(_tooltip, [
				Comp.new(ColorPickerButton).ref(color_button).on_init([
					CompInit.SIZE_FLAGS_HORIZONTAL_EXPAND_FILL(),
					CompInit.CUSTOM(func(this: ColorPickerButton) -> void:
						self.on_value_changed(func(new_value: Variant) -> void:
							this.color = new_value
						)
						this.color = self._value
						this.color_changed.connect(func(new_color: Variant) -> void:
							self.set_value_and_notify(new_color)
						)
						this.custom_minimum_size.x = 60

						var picker := this.get_picker()
						picker.deferred_mode = true
						picker.can_add_swatches = true
						picker.presets_visible = true
						pass\
					)
				])
			])
		])
		control.add_to(target)

class SettingSlider extends Setting:
	func add_control(target: SettingControlTarget) -> void:
		var slider := CompRefs.Simple.new()
		var control := Comp.new(HBoxContainer, [
			CompSettingNameContainer.new(self),
			CompSettingPanelContainer.new(_tooltip, [
				Comp.new(HBoxContainer, [
					Comp.new(LineEdit).on_init([
						CompInit.CUSTOM(func(this: LineEdit) -> void:
							this.select_all_on_focus = true
							this.custom_minimum_size.x = 50
							this.text = "%.1f" % self._value
							this.text_submitted.connect(func(new_text: String) -> void:
								if new_text.is_valid_float():
									var new_value := clampf(float(new_text), -1.0, 1.0)
									self.set_value_and_notify(new_value)
									this.release_focus()
								else:
									this.text = "%.1f" % self._value
							)
							self.on_value_changed(func(new_value: Variant) -> void:
								this.text = "%.1f" % new_value
							)
							pass\
						)
					]),
					Comp.new(HSlider).ref(slider).on_init([
						CompInit.SIZE_FLAGS_HORIZONTAL_EXPAND_FILL(),
						CompInit.CUSTOM(func(this: HSlider) -> void:
							this.step = 0.1
							this.min_value = -1
							this.max_value = 1
							
							self.on_value_changed(func(new_value: Variant) -> void:
								this.value = new_value
							)
							
							this.value = self._value
							
							this.value_changed.connect(func(new_value: Variant) -> void:
								self.set_value_and_notify(new_value)
							)
							pass\
						)
					]),
				])
			])
		])
		control.add_to(target)
