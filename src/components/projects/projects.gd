extends HBoxContainer

var _projects_cfg = ConfigFile.new()

@onready var _sidebar: VBoxContainer = $ActionsSidebar
@onready var _projects_list: VBoxContainer = $ProjectsList
@onready var _import_project_button: Button = %ImportProjectButton
@onready var _import_project_dialog: FileDialog = $ImportProjectDialog


func _ready() -> void:
	_import_project_button.icon = get_theme_icon("Load", "EditorIcons")
	_import_project_button.pressed.connect(func():
		_import_project_dialog.popup_centered_ratio()
	)
	_import_project_dialog.file_selected.connect(func(path):
		var project_item = ProjectItem.new(
			ConfigFileSection.new(path, _projects_cfg)
		)
		
		project_item.favorite = false
		
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
			ConfigFileSection.new(section, _projects_cfg)
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
	var _section: ConfigFileSection
	
	var path:
		get: return _section.name
	
	var name:
		get: return _section.get_value("name", "test")

	var favorite:
		get: return _section.get_value("favorite", false)
		set(value): _section.set_value("favorite", value)
	
	func _init(section: ConfigFileSection) -> void:
		self._section = section
