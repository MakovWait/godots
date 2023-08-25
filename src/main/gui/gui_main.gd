extends Control

const projects = preload("res://src/services/projects.gd")
const editors = preload("res://src/services/local_editors.gd")
const theme_source = preload("res://theme/theme.gd")

@export var _remote_editors: Control
@export var _local_editors: Control
@export var _projects: Control
@export var _asset_library_projects: Control
@export var _godots_releases: Control
@export var _auto_updates: Node
@export var _asset_download: PackedScene

@onready var _gui_base: Panel = get_node("%GuiBase")
@onready var _main_v_box: VBoxContainer = get_node("%MainVBox")
@onready var _tab_container: TabContainer = %TabContainer
@onready var _version_button: LinkButton = %VersionButton
@onready var _settings_button = %SettingsButton


func _ready():
	get_tree().root.files_dropped.connect(func(files):
		if len(files) == 0:
			return
		var file = files[0].simplify_path()
		if file.ends_with("project.godot"):
			_projects.import(file)
		elif file.ends_with(".zip"):
			var zip_reader = ZIPReader.new()
			var unzip_err = zip_reader.open(file)
			if unzip_err != OK:
				zip_reader.close()
				return
			var has_project_godot_file = len(
				Array(
					zip_reader.get_files()
				).map(func(x): return x.get_file() == "project.godot")
			) > 0
			if has_project_godot_file:
				_projects.install_zip(
					zip_reader,
					file.get_file().replace(".zip", "").capitalize()
				)
			else:
				zip_reader.close()
				_remote_editors.install_zip(
					file, 
					file.get_file().replace(".zip", ""), 
					utils.guess_editor_name(file.replace(".zip", ""))
				)
		else:
			_local_editors.import("", file)
	)
	
	_gui_base.set(
		"theme_override_styles/panel",
		get_theme_stylebox("Background", "EditorStyles")
	)
	_gui_base.set_anchor(SIDE_RIGHT, Control.ANCHOR_END)
	_gui_base.set_anchor(SIDE_BOTTOM, Control.ANCHOR_END)
	_gui_base.set_end(Vector2.ZERO)
	
	_main_v_box.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT, 
		Control.PRESET_MODE_MINSIZE, 
		get_theme_constant("window_border_margin", "Editor")
	)
	_main_v_box.add_theme_constant_override(
		"separation", 
		get_theme_constant("top_bar_separation", "Editor")
	)

	_remote_editors.installed.connect(func(name, path):
		_local_editors.add(name, path)
	)

	var main_current_tab = Cache.smart_value(
		self, "main_current_tab", true
	)
	_tab_container.tab_changed.connect(func(tab): main_current_tab.put(tab))
	_tab_container.current_tab = main_current_tab.ret(0)

	_local_editors.editor_download_pressed.connect(func():
		_tab_container.current_tab = _tab_container.get_tab_idx_from_control(_remote_editors)
	)

	_version_button.text = Config.VERSION.substr(1)
	_version_button.self_modulate = Color(1, 1, 1, 0.6)
	_version_button.underline = LinkButton.UNDERLINE_MODE_ON_HOVER
	_version_button.tooltip_text = tr("Click to star it on GitHub")
	
	%NewsButton.self_modulate = Color(1, 1, 1, 0.6)
	%NewsButton.underline = LinkButton.UNDERLINE_MODE_ON_HOVER
	%NewsButton.tooltip_text = tr("Click to see the post.")
	
	_settings_button.flat = true
	_settings_button.text = ""
	_settings_button.tooltip_text = tr("Settings.")
	_settings_button.icon = get_theme_icon("Tools", "EditorIcons")
	_settings_button.self_modulate = Color(1, 1, 1, 0.6)
	_settings_button.pressed.connect(func():
		$Settings.raise_settings()
	)
	
	var local_editors = editors.LocalEditors.new(
		Config.EDITORS_CONFIG_PATH
	)
	var projects_service = projects.Projects.new(
		Config.PROJECTS_CONFIG_PATH,
		local_editors,
		get_theme_icon("DefaultProjectIcon", "EditorIcons")
	)
	
	local_editors.load()
	projects_service.load()

	_projects.init(projects_service)
	_local_editors.init(local_editors)
	_remote_editors.init(%DownloadsContainer)

	_projects.manage_tags_requested.connect(_popup_manage_tags)
	_local_editors.manage_tags_requested.connect(_popup_manage_tags)
	
	_asset_library_projects.projects = _projects

	_setup_godots_releases()


func _notification(what: int) -> void:
	if NOTIFICATION_APPLICATION_FOCUS_OUT == what:
		OS.low_processor_usage_mode_sleep_usec = 100000
	elif NOTIFICATION_APPLICATION_FOCUS_IN == what:
		OS.low_processor_usage_mode_sleep_usec = ProjectSettings.get(
			"application/run/low_processor_mode_sleep_usec"
		)


func _enter_tree():
	theme_source.set_scale(Config.EDSCALE)
	theme = theme_source.create_custom_theme(null)
	
	var window = get_window()
	window.min_size = Vector2(520, 370) * Config.EDSCALE
	
	var scale_factor = max(1, Config.EDSCALE * 0.75)
	if scale_factor > 1:
		var window_size = DisplayServer.window_get_size()
		var screen_rect = DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
		
		window_size *= scale_factor
		
		DisplayServer.window_set_size(window_size)
		if screen_rect.size != Vector2i():
			var window_position = Vector2i(
				screen_rect.position.x + (screen_rect.size.x - window_size.x) / 2,
				screen_rect.position.y + (screen_rect.size.y - window_size.y) / 2
			)
			DisplayServer.window_set_position(window_position)
	window.min_size = Vector2(700, 350) * Config.EDSCALE


func _popup_manage_tags(item_tags, all_tags, on_confirm):
	$ManageTags.popup_centered(Vector2(500, 0) * Config.EDSCALE)
	$ManageTags.init(item_tags, all_tags, on_confirm)


func _setup_godots_releases():
	var godots_releases = GodotsReleases.Default.new(
		GodotsReleases.SrcGithub.new()
	)
	var godots_install: GodotsInstall.I
	if OS.has_feature("template"):
		godots_install = GodotsInstall.Default.new(
			OS.get_executable_path(),
			get_tree()
		)
	else:
		godots_install = GodotsInstall.Forbidden.new(self)

	_auto_updates.init(
		GodotsRecentReleases.Cached.new(
			GodotsRecentReleases.Default.new(godots_releases)
		), 
		func(): 
			_tab_container.current_tab = _tab_container.get_tab_idx_from_control(_godots_releases)
	)
	_godots_releases.init(
		godots_releases,
		GodotsDownloads.Default.new(%DownloadsContainer, _asset_download),
		godots_install
	)
