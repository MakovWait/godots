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
	var items = []
	for section in _editors_cfg.get_sections():
		items.append(LocalEditorItem.new(
			ConfigFileSection.new(section, _editors_cfg)
		))
	_editors_list.refresh(items)


func _on_editors_list_item_selected(item) -> void:
	_sidebar.refresh_actions(item.get_actions())


func _on_editors_list_item_removed(item_data: LocalEditorItem) -> void:
	var section = item_data.path
	if _editors_cfg.has_section(section):
		_editors_cfg.erase_section(section)
		_editors_cfg.save(Config.EDITORS_CONFIG_PATH)
	dir.remove_recursive(item_data.path.get_base_dir())
	_sidebar.refresh_actions([])


class LocalEditorItem extends RefCounted:
	var _section: ConfigFileSection
	
	var path:
		get: return _section.name
	
	var name:
		get: return _section.get_value("name", "")
		set(value): _section.set_value("name", value)
	
	func _init(section: ConfigFileSection) -> void:
		self._section = section
