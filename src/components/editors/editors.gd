extends HBoxContainer

@onready var _editors_list: VBoxContainer = $EditorsList
@onready var _editors_side_bar: VBoxContainer = $EditorsSideBar


func update_items(config: ConfigFile):
	var items = []
	for section in config.get_sections():
		items.append(LocalEditorItem.new(section, config))
	_editors_list.load_items(items)


func _on_editors_list_editor_item_selected(editor_item) -> void:
	_editors_side_bar.refresh_actions(editor_item.get_actions())


class LocalEditorItem extends RefCounted:
	var _cfg: ConfigFile
	var _section: String
	
	var path:
		get: return _section
	
	var name:
		get: return _get_cfg_value("name", "")
	
	func _init(section, cfg) -> void:
		self._cfg = cfg
		self._section = section
	
	func _get_cfg_value(key, default=null):
		return self._cfg.get_value(self._section, key, default)
	
	func _set_cfg_value(key, value):
		self._cfg.set_value(self._section, key, value)
