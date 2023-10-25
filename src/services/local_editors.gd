class_name LocalEditors

class List extends RefCounted:
	const dict = preload("res://src/extensions/dict.gd")
	
	signal editor_removed(editor_path)
	signal editor_name_changed(editor_path)
	
	var _cfg_path
	var _cfg = ConfigFile.new()
	var _editors = {}
	
	func _init(cfg_path) -> void:
		_cfg_path = cfg_path
	
	func add(name, editor_path) -> Item:
		var editor = Item.new(
			ConfigFileSection.new(editor_path, _cfg),
		)
		if OS.has_feature("linux"):
			var output = []
			var exit_code = OS.execute(
				"chmod", 
				["+x", "%s" % ProjectSettings.globalize_path(editor_path) ], 
				output,
				true
			)
			Output.push(output.pop_front())
			Output.push("chmod executed with exit code: %s" % exit_code)
		_connect_name_changed(editor)
		editor.name = name
		editor.favorite = false
		editor.extra_arguments = ""
		_editors[editor_path] = editor
		return editor
	
	func all() -> Array[Item]:
		var result: Array[Item] = []
		for x in _editors.values():
			result.append(x)
		return result
	
	func retrieve(editor_path) -> Item:
		return _editors[editor_path]
	
	func retrieve_by_version_hint(version_hint: String) -> Item:
		for e in all():
			if VersionHint.are_equal(e.version_hint, version_hint):
				return e
		return null
	
	func filter_by_name_pattern(name_pattern: String) -> Array[Item]:
		var sanitized_name_pattern = _sanitize_name(name_pattern)
		var result: Array[Item] = []
		for editor in all():
			if _sanitize_name(editor.name).findn(sanitized_name_pattern) > -1:
				result.push_back(editor)
		return result
	
	func has(editor_path) -> bool:
		return _editors.has(editor_path)
	
	func editor_is_valid(editor_path):
		return has(editor_path) and edir.path_is_valid(editor_path)
	
	func erase(editor_path) -> void:
		var editor = retrieve(editor_path)
		editor.free()
		_editors.erase(editor_path)
		_cfg.erase_section(editor_path)
		editor_removed.emit(editor_path)
	
	func as_option_button_items():
		return all().filter(
			func(x): return self.editor_is_valid(x.path)
		).map(func(x: Item): return {
			'label': x.name,
			'path': x.path,
			'version_hint': x.version_hint
		})
	
	func get_all_tags():
		var set = Set.new()
		for editor in _editors.values():
			for tag in editor.tags:
				set.append(tag.to_lower())
		return set.values()
	
	func load() -> Error:
		dict.clear_and_free(_editors)
		var err = _cfg.load(_cfg_path)
		if err: return err
		for section in _cfg.get_sections():
			var editor = Item.new(
				ConfigFileSection.new(section, _cfg)
			)
			_connect_name_changed(editor)
			_editors[section] = editor
		return Error.OK
	
	func save() -> Error:
		return _cfg.save(_cfg_path)
	
	func _connect_name_changed(editor: Item):
		editor.name_changed.connect(func(_new_name): 
			editor_name_changed.emit(editor.path)
		)
		
	func _sanitize_name(name: String):
		return name.replace(" ", "")

class Item extends Object:
	signal tags_edited
	signal name_changed(new_name)
	
	var mac_os_editor_path_postfix:
		get: return _section.get_value("mac_os_editor_path_postfix", "/Contents/MacOS/Godot")
	
	var path: String:
		get: return _section.name
	
	var name: String:
		get: return _section.get_value("name", "")
		set(value): 
			_section.set_value("name", value)
			name_changed.emit(value)
		
	var extra_arguments:
		get: return _section.get_value("extra_arguments", "")
		set(value): 
			_section.set_value("extra_arguments", value)
			
	var favorite:
		get: return _section.get_value("favorite", false)
		set(value): _section.set_value("favorite", value)
	
	var tags:
		get: return Set.of(_section.get_value("tags", [])).values()
		set(value): _section.set_value("tags", value)
	
	var is_valid:
		get: return edir.path_is_valid(path)
	
	var version_hint: String:
		get: return _section.get_value(
			"version_hint", 
			self.name.to_lower()
				.replace("godot", "")
				.strip_edges()
				.replace(" ", "-")
		)
		set(value): _section.set_value("version_hint", value)

	var custom_commands:
		get: return _section.get_value("custom_commands", [])
		set(value): _section.set_value("custom_commands", value)

	var _section: ConfigFileSection
	
	func _init(section: ConfigFileSection) -> void:
		self._section = section

	func as_process(args: PackedStringArray) -> OSProcessSchema:
		var process_path
		if OS.has_feature("windows") or OS.has_feature("linux"):
			process_path = ProjectSettings.globalize_path(path)
		elif OS.has_feature("macos"):
			process_path = ProjectSettings.globalize_path(path + mac_os_editor_path_postfix)
		var final_args = []
		final_args.append(extra_arguments)
		final_args.append_array(args)
		return OSProcessSchema.new(process_path, final_args)

	func as_project_manager_process() -> OSProcessSchema:
		return as_process(["-p"])
	
	func emit_tags_edited():
		tags_edited.emit()
	
	func is_self_contained():
		if not is_valid:
			return false
		var sub_file_exists = func(file):
			return FileAccess.file_exists(path.get_base_dir().path_join(file))
		return sub_file_exists.call("_sc_") or sub_file_exists.call("._sc_")
