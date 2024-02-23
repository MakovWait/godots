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
		cleanup()
		var err = _cfg.load(_cfg_path)
		if err: return err
		for section in _cfg.get_sections():
			var editor = Item.new(
				ConfigFileSection.new(section, _cfg)
			)
			_connect_name_changed(editor)
			_editors[section] = editor
		return Error.OK
	
	func cleanup():
		dict.clear_and_free(_editors)
	
	func save() -> Error:
		return _cfg.save(_cfg_path)
	
	func _connect_name_changed(editor: Item):
		editor.name_changed.connect(func(_new_name): 
			editor_name_changed.emit(editor.path)
		)


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
		get: return _section.get_typed_value(
			"extra_arguments", 
			func(x): return x is PackedStringArray, 
			[]
		)
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
		get: return _get_custom_commands()
		set(value): _section.set_value("custom_commands", value)

	var _section: ConfigFileSection
	
	func _init(section: ConfigFileSection) -> void:
		self._section = section

	func _notification(what):
		if NOTIFICATION_PREDELETE == what:
			utils.disconnect_all(self)

	func as_process(args: PackedStringArray) -> OSProcessSchema:
		var process_path
		if OS.has_feature("windows") or OS.has_feature("linux"):
			process_path = ProjectSettings.globalize_path(path)
		elif OS.has_feature("macos"):
			process_path = ProjectSettings.globalize_path(path + mac_os_editor_path_postfix)
		var final_args = []
		final_args.append_array(extra_arguments)
		final_args.append_array(args)
		return OSProcessSchema.new(process_path, final_args)

	func as_project_manager_process() -> OSProcessSchema:
		return as_process(_get_project_manager_args())
	
	func _get_project_manager_args():
		var command = _find_custom_command_by_name("Run", custom_commands)
		return command.args
	
	func emit_tags_edited():
		tags_edited.emit()
	
	func is_self_contained():
		if not is_valid:
			return false
		var sub_file_exists = func(file):
			return FileAccess.file_exists(path.get_base_dir().path_join(file))
		return sub_file_exists.call("_sc_") or sub_file_exists.call("._sc_")
	
	func match_name(search):
		var sanitazed_name = _sanitize_name(name)
		var sanitazed_search = _sanitize_name(search)
		var findn = sanitazed_name.findn(sanitazed_search)
		return findn > -1
	
	func match_version_hint(hint, ignore_mono=false):
		return VersionHint.are_equal(self.version_hint, hint, ignore_mono)
	
	func get_version() -> String:
		var parsed = VersionHint.parse(version_hint)
		if parsed.is_valid:
			return parsed.version
		else:
			return ""
	
	func get_cfg_file_path() -> String:
		var cfg_file_name = get_cfg_file_name()
		if cfg_file_name.is_empty():
			return ""
		var cfg_folder = ""
		if is_self_contained():
			cfg_folder = path.get_base_dir().path_join("editor_data")
		else:
			cfg_folder = OS.get_config_dir().path_join("Godot")
		if cfg_folder.is_empty():
			return ""
		return cfg_folder.path_join(cfg_file_name)
	
	func get_cfg_file_name() -> String:
		var version = get_version()
		if version.is_empty():
			return ""
		if version.begins_with("3"):
			return "editor_settings-3.tres"
		elif version.begins_with("4"):
			return "editor_settings-4.tres"
		else:
			return ""
	
	func _sanitize_name(name: String):
		return name.replace(" ", "")
	
	func _find_custom_command_by_name(name: String, src=[]):
		for command in src:
			if command.name == name:
				return command
		return null

	func _get_custom_commands():
		var commands = _section.get_value("custom_commands", [])
		if not _find_custom_command_by_name("Run", commands):
			commands.append({
				'name': 'Run',
				'args': ['-p'],
				'allowed_actions': [
					CommandViewer.Actions.EXECUTE, 
					CommandViewer.Actions.EDIT, 
					CommandViewer.Actions.CREATE_PROCESS
				]
			})
		return commands
	
	func _to_string() -> String:
		return "%s (%s)" % [name, VersionHint.parse(version_hint)]


class Selector:
	var _filter: Callable
	
	func _init(filter=null):
		if filter == null:
			filter = func(x): return true
		_filter = filter
	
	func by_name(name) -> Selector:
		return Selector.new(func(el: Item):
			return _filter.call(el) and el.match_name(name)
		)
	
	func by_version_hint(hint, ignore_mono=false) -> Selector:
		return Selector.new(func(el: Item):
			return _filter.call(el) and el.match_version_hint(hint, ignore_mono)
		)
	
	func select(editors: List) -> Array[Item]:
		var result: Array[Item] = []
		for el in editors.all():
			if _filter.call(el):
				result.append(el)
		return result
	
	func select_first_or_null(editors: List) -> Item:
		var res = select(editors)
		if len(res) > 0:
			return res[0]
		else:
			return null
	
	func select_exact_one(editors: List) -> Item:
		var res = select(editors)
		if len(res) == 1:
			return res[0]
		else:
			if len(res) > 1:
				Output.push("There is ambiguity between editors to run.\n%s" % "\n".join(res))
			return null
	
	static func from_cmd(cmd: CliParser.ParsedCommandResult) -> Selector:
		var name = cmd.args.first_option_value(["name", "n"])
		var version_hint = cmd.args.first_option_value(["version-hint", "vh"])
		var ignore_mono = cmd.args.has_options(["ignore-mono", "im"])
		var selector = Selector.new()
		if not name.is_empty():
			selector = selector.by_name(name)
		if not version_hint.is_empty():
			selector = selector.by_version_hint(version_hint, ignore_mono)
		return selector
