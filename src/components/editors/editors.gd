extends HBoxContainer

@onready var _editors_list: VBoxContainer = $EditorsList


func update_items(config: ConfigFile):
	var items = []
	for section in config.get_sections():
		items.append(LocalEditorItem.new(section, config))
	_editors_list.load_items(items)


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
