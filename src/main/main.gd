extends Control

const projects = preload("res://src/services/projects.gd")
const editors = preload("res://src/services/local_editors.gd")
const theme_source = preload("res://theme/theme.gd")

@export var _remote_editors: Control
@export var _local_editors: Control
@export var _projects: Control

@onready var _gui_base: Panel = get_node("%GuiBase")
@onready var _main_v_box: VBoxContainer = get_node("%MainVBox")
@onready var _tab_container: TabContainer = %TabContainer
@onready var _version_button: LinkButton = %VersionButton
@onready var _auto_close_check_button: CheckButton = %AutoCloseCheckButton


func _ready():
	get_tree().root.files_dropped.connect(func(files):
		if len(files) == 0:
			return
		var file = files[0]
		if file.ends_with("project.godot"):
			_projects.import(file)
		elif file.ends_with(".zip"):
			_remote_editors.install_zip(
				file, 
				file.get_file().replace(".zip", ""), 
				_remote_editors.guess_editor_name(file)
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
	
	# obsolete
	$GuiBase/MainVBox/TitleBar.add_button(
		_make_main_button("Projects", get_theme_icon("File", "EditorIcons")),
	)
	$GuiBase/MainVBox/TitleBar.add_button(
		_make_main_button("Local Editors", get_theme_icon("GodotMonochrome", "EditorIcons"))
	)
	$GuiBase/MainVBox/TitleBar.add_button(
		_make_main_button("Remote Editors", get_theme_icon("Filesystem", "EditorIcons")),
	)

	_tab_container.tab_changed.connect(func(tab):
		Config.set_main_current_tab(tab)
	)
	_tab_container.current_tab = Config.get_main_current_tab()

	_local_editors.editor_download_pressed.connect(func():
		_tab_container.current_tab = _tab_container.get_tab_idx_from_control(
			$"GuiBase/MainVBox/Content/TabContainer/Remote Editors"
		)
	)

	_version_button.text = "v%s" % Config.VERSION
	_version_button.self_modulate = Color(1, 1, 1, 0.6)
	_version_button.underline = LinkButton.UNDERLINE_MODE_ON_HOVER
	_version_button.tooltip_text = "Click to star it on GitHub"
	
	_auto_close_check_button.button_pressed = Config.get_auto_close()
	_auto_close_check_button.tooltip_text = "Close on launch"
	_auto_close_check_button.self_modulate = Color(1, 1, 1, 0.6)
	_auto_close_check_button.toggled.connect(func(toggled):
		Config.set_auto_close(toggled)
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
	
	_projects.manage_tags_requested.connect(_popup_manage_tags)
	_local_editors.manage_tags_requested.connect(_popup_manage_tags)


# obsolete
func _make_main_button(text, icon):
	var btn = Button.new()
	btn.toggle_mode = true
	btn.flat = true
	btn.text = text
	btn.icon = icon
	btn.add_theme_font_override("font", get_theme_font("main_button_font", "EditorFonts"))
	btn.add_theme_font_size_override("font_size", get_theme_font_size("main_button_font_size", "EditorFonts"))
	return btn


func _notification(what: int) -> void:
	if NOTIFICATION_APPLICATION_FOCUS_OUT == what:
		OS.low_processor_usage_mode_sleep_usec = 100000
	elif NOTIFICATION_APPLICATION_FOCUS_IN == what:
		OS.low_processor_usage_mode_sleep_usec = ProjectSettings.get(
			"application/run/low_processor_mode_sleep_usec"
		)


func _enter_tree():
	theme_source.set_scale(Config.EDSCALE)
	theme = theme_source.create_editor_theme(null)
	
	var window = get_window()
	window.min_size = Vector2(520, 350) * Config.EDSCALE
	
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


func _popup_manage_tags(item_tags, all_tags, on_confirm):
	$ManageTags.popup_centered(Vector2(500, 0) * Config.EDSCALE)
	$ManageTags.init(item_tags, all_tags, on_confirm)
