extends Control

const projects = preload("res://src/services/projects.gd")
const editors = preload("res://src/services/local_editors.gd")
const theme_source = preload("res://theme/theme.gd")

@export var _remote_editors: Control
@export var _local_editors: Control
@export var _projects: Control

@onready var _gui_base: Panel = get_node("%GuiBase")
@onready var _main_v_box: VBoxContainer = get_node("%MainVBox")


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

	_local_editors.editor_download_pressed.connect(func():
		var tab_container = $GuiBase/MainVBox/Content/TabContainer
		tab_container.current_tab = tab_container.get_tab_idx_from_control(
			$"GuiBase/MainVBox/Content/TabContainer/Remote Editors"
		)
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
#	_local_editors.manage_tags_requested.connect(_popup_manage_tags)


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


func _enter_tree():
	theme_source.set_scale(Config.EDSCALE)
	theme = theme_source.create_editor_theme(null)
	
	var window = get_window()
	window.min_size = Vector2(520, 350) * Config.EDSCALE
	window.size = window.min_size


func _popup_manage_tags(item_tags, all_tags, on_confirm):
	$ManageTags.popup_centered(Vector2(500, 0) * Config.EDSCALE)
	$ManageTags.init(item_tags, all_tags, on_confirm)
