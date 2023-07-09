extends HBoxContainer

@onready var _editors_list: VBoxContainer = $EditorsList
@onready var _editors_side_bar: VBoxContainer = $EditorsSideBar

const EDITORS_CONFIG_PATH = "user://editors.cfg"
var _editors_cfg = ConfigFile.new()


func _ready() -> void:
	_editors_cfg.load(EDITORS_CONFIG_PATH)
	_load_items()


func add(editor_name, exec_path):
	if not _editors_cfg.has_section(exec_path):
		_editors_cfg.set_value(exec_path, "name", editor_name)
		_editors_cfg.save(EDITORS_CONFIG_PATH)
		_editors_list.add(LocalEditorItem.new(exec_path, _editors_cfg))


func _load_items():
	var items = []
	for section in _editors_cfg.get_sections():
		items.append(LocalEditorItem.new(section, _editors_cfg))
	_editors_list.refresh(items)


func _on_editors_list_editor_item_selected(side_bar_actions_src) -> void:
	_editors_side_bar.refresh_actions(side_bar_actions_src.get_actions())


func _on_editors_list_editor_item_removed(editor_data) -> void:
	var section = editor_data.path
	if _editors_cfg.has_section(section):
		_editors_cfg.erase_section(section)
		_editors_cfg.save(EDITORS_CONFIG_PATH)
	_remove_recursive(editor_data.path.get_base_dir())


# https://www.davidepesce.com/?p=1365
func _remove_recursive(path):
#	var directory = Directory.new()
	var directory = DirAccess.open(path)
	# Open directory
	var error = DirAccess.get_open_error()
	if error == OK:
		directory.include_hidden = true
		# List directory content
		directory.list_dir_begin()
		var file_name = directory.get_next()
		while file_name != "":
			if directory.current_is_dir():
				_remove_recursive(path + "/" + file_name)
			else:
				directory.remove(file_name)
			file_name = directory.get_next()
		
		# Remove current path
		directory.remove(path)
	else:
		print("Error removing " + path)


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
