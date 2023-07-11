extends HBoxContainer

const dir = preload("res://src/extensions/dir.gd")

@onready var _editors_list: VBoxContainer = $EditorsList
@onready var _sidebar: VBoxContainer = $ActionsSidebar

var _editors_cfg = ConfigFile.new()


func _ready() -> void:
	_editors_cfg.load(Config.EDITORS_CONFIG_PATH)
	_load_items()


func add(editor_name, exec_path):
	if not _editors_cfg.has_section(exec_path):
		var item = LocalEditorItem.new(
			ConfigFileSection.new(exec_path, _editors_cfg)
		)
		item.name = editor_name
		
		_editors_cfg.save(Config.EDITORS_CONFIG_PATH)
		_editors_list.add(item)


func _load_items():
	var items = get_local_editor_data_items()
	_editors_list.refresh(items)
	_editors_list.sort_items()


func _on_editors_list_item_selected(item) -> void:
	_sidebar.refresh_actions(item.get_actions())


func _on_editors_list_item_removed(item_data: LocalEditorItem) -> void:
	var section = item_data.path
	if _editors_cfg.has_section(section):
		_editors_cfg.erase_section(section)
		_editors_cfg.save(Config.EDITORS_CONFIG_PATH)
	dir.remove_recursive(item_data.path.get_base_dir())
	_sidebar.refresh_actions([])


func _on_editors_list_item_edited(item_data) -> void:
	_editors_cfg.save(Config.EDITORS_CONFIG_PATH)
	_editors_list.sort_items()


func get_local_editor_data_items():
	var items = []
	for section in _editors_cfg.get_sections():
		items.append(LocalEditorItem.new(
			ConfigFileSection.new(section, _editors_cfg)
		))
	return items


func get_editor_name_by_path(path):
	return LocalEditorItem.new(ConfigFileSection.new(path, _editors_cfg)).name


func as_option_button_items():
	return get_local_editor_data_items().map(func(x): return {
		'label': x.name,
		'path': x.path
	})


class LocalEditorItem extends RefCounted:
	var _section: ConfigFileSection
	
	var path:
		get: return _section.name
	
	var name:
		get: return _section.get_value("name", "")
		set(value): _section.set_value("name", value)

	var favorite:
		get: return _section.get_value("favorite", false)
		set(value): _section.set_value("favorite", value)
	
	func _init(section: ConfigFileSection) -> void:
		self._section = section
