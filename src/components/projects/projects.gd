extends HBoxContainer

var _projects_cfg = ConfigFile.new()

@onready var _sidebar: VBoxContainer = $ActionsSidebar
@onready var _projects_list: VBoxContainer = $ProjectsList
@onready var _import_project_button: Button = %ImportProjectButton
@onready var _import_project_dialog: ConfirmationDialog = $ImportProjectDialog

var _local_editors
var _default_icon

func _ready() -> void:
	_default_icon = get_theme_icon("DefaultProjectIcon", "EditorIcons")


func init(local_editors):
	_local_editors = local_editors
	
	_import_project_button.icon = get_theme_icon("Load", "EditorIcons")
	_import_project_button.pressed.connect(func():
		_import_project_dialog.init(local_editors.as_option_button_items())
		_import_project_dialog.popup_centered()
	)
	_import_project_dialog.imported.connect(func(project_path, editor_path):
		var project_item = ProjectItem.new(
			ConfigFileSection.new(project_path, _projects_cfg),
			ExternalProjectInfo.new(project_path, _default_icon),
			_local_editors
		)
		
		project_item.favorite = false
		project_item.editor_path = editor_path

		_projects_cfg.save(Config.PROJECTS_CONFIG_PATH)
		_projects_list.add(project_item)
		_projects_list.sort_items()
	)
	
	_projects_cfg.load(Config.PROJECTS_CONFIG_PATH)
	_load_items()


func _load_items():
	var items = []
	for section in _projects_cfg.get_sections():
		items.append(ProjectItem.new(
			ConfigFileSection.new(section, _projects_cfg),
			ExternalProjectInfo.new(section, _default_icon),
			_local_editors
		))
	_projects_list.refresh(items)
	_projects_list.sort_items()


func _on_projects_list_item_selected(item) -> void:
	_sidebar.refresh_actions(item.get_actions())


func _on_projects_list_item_removed(item_data) -> void:
	var section = item_data.path
	if _projects_cfg.has_section(section):
		_projects_cfg.erase_section(section)
		_projects_cfg.save(Config.PROJECTS_CONFIG_PATH)
	_sidebar.refresh_actions([])


func _on_projects_list_item_edited(item_data) -> void:
	_projects_cfg.save(Config.PROJECTS_CONFIG_PATH)
	_projects_list.sort_items()


class ProjectItem extends RefCounted:
	var path:
		get: return _section.name
	
	var name:
		get: return _external_project_info.name
	
	var editor_name:
		get: return _editor_name_src.get_editor_name_by_path(editor_path)
	
	var icon:
		get: return _external_project_info.icon

	var favorite:
		get: return _section.get_value("favorite", false)
		set(value): _section.set_value("favorite", value)
	
	var editor_path:
		get: return _section.get_value("editor_path", "")
		set(value): _section.set_value("editor_path", value)
	
	var _external_project_info: ExternalProjectInfo
	var _section: ConfigFileSection
	var _editor_name_src
	
	func _init(
		section: ConfigFileSection, 
		project_info: ExternalProjectInfo,
		editor_name_src
	) -> void:
		self._section = section
		self._external_project_info = project_info
		self._editor_name_src = editor_name_src
	
	func load():
		_external_project_info.load()


class ExternalProjectInfo extends RefCounted:
	signal loaded
	
	var icon:
		get: return _icon

	var name:
		get: return _name

	var last_modied:
		get: return _last_modified
	
	var is_loaded:
		get: return _is_loaded

	var _is_loaded = false
	var _project_path
	var _default_icon
	var _icon
	var _name
	var _last_modified
	
	func _init(project_path, default_icon):
		_project_path = project_path
		_default_icon = default_icon
		icon = default_icon
	
	func load():
		var cfg = ConfigFile.new()
		cfg.load(_project_path)
		
		_name = cfg.get_value("application", "config/name", "unknown")
		_icon = _load_icon(cfg)
		
		is_loaded = true
		loaded.emit()
	
	func _load_icon(cfg):
		var result
		var icon_path: String = cfg.get_value("application", "config/icon")
		icon_path = icon_path.replace("res://", self._project_path.get_base_dir() + "/")

		var icon_image = Image.new()
		var err = icon_image.load(icon_path)
		if not err:
			icon_image.resize(
				_default_icon.get_width(), _default_icon.get_height(), Image.INTERPOLATE_LANCZOS
			)
			result = ImageTexture.create_from_image(icon_image)
		else:
			result = _default_icon
		return result
