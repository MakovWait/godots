class_name LocalEditors

class List extends RefCounted:
	const dict = preload("res://src/extensions/dict.gd")
	
	signal editor_removed(editor_path: String)
	signal editor_name_changed(editor_path: String)
	
	var _cfg_path: String
	var _cfg := ConfigFile.new()
	var _editors: Dictionary[String, Item] = {}
	
	func _init(cfg_path: String) -> void:
		_cfg_path = cfg_path
	
	func add(name: String, editor_path: String) -> Item:
		var editor := Item.new(
			ConfigFileSection.new(editor_path, IConfigFileLike.of_config(_cfg)),
		)
		if OS.has_feature("linux"):
			var output := []
			var exit_code := OS.execute(
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
		editor.extra_arguments = []
		_editors[editor_path] = editor
		return editor
	
	func all() -> Array[Item]:
		var result: Array[Item] = []
		for x: Item in _editors.values():
			result.append(x)
		return result
	
	func retrieve(editor_path: String) -> Item:
		return _editors[editor_path]
	
	func has(editor_path: String) -> bool:
		return _editors.has(editor_path)
	
	func editor_is_valid(editor_path: String) -> bool:
		return has(editor_path) and edir.path_is_valid(editor_path)
	
	func erase(editor_path: String) -> void:
		var editor := retrieve(editor_path)
		editor.free()
		_editors.erase(editor_path)
		_cfg.erase_section(editor_path)
		editor_removed.emit(editor_path)
	
	func as_option_button_items() -> Array[Dictionary]:
		var result: Array[Dictionary]
		for x in all():
			if self.editor_is_valid(x.path):
				result.append({
					'label': x.name,
					'path': x.path,
					'version_hint': x.version_hint
				})
		return result
	
	# TODO type
	func get_all_tags() -> Array:
		var set := Set.new()
		for editor: Item in _editors.values():
			for tag: String in editor.tags:
				set.append(tag.to_lower())
		return set.values()
	
	func load() -> Error:
		cleanup()
		var err := _cfg.load(_cfg_path)
		if err: return err
		for section in _cfg.get_sections():
			var editor := Item.new(
				ConfigFileSection.new(section, IConfigFileLike.of_config(_cfg))
			)
			_connect_name_changed(editor)
			_editors[section] = editor
		return Error.OK
	
	func cleanup() -> void:
		dict.clear_and_free(_editors)
	
	func save() -> Error:
		return _cfg.save(_cfg_path)
	
	func _connect_name_changed(editor: Item) -> void:
		editor.name_changed.connect(func(_new_name: String) -> void: 
			editor_name_changed.emit(editor.path)
		)


class Item extends Object:
	signal tags_edited
	signal name_changed(new_name: String)
	
	var mac_os_editor_path_postfix: String:
		get: return _section.get_value("mac_os_editor_path_postfix", "/Contents/MacOS/Godot")
	
	var path: String:
		get: return _section.name
	
	var name: String:
		get: return _section.get_value("name", "")
		set(value): 
			_section.set_value("name", value)
			name_changed.emit(value)
	
	var extra_arguments: PackedStringArray:
		get: return _section.get_typed_value(
			"extra_arguments", 
			func(x: Variant) -> bool: return x is PackedStringArray, 
			[]
		)
		set(value): 
			_section.set_value("extra_arguments", value)
	
	var favorite: bool:
		get: return _section.get_value("favorite", false)
		set(value): _section.set_value("favorite", value)
	
	# TODO type
	var tags: Array:
		get: return Set.of(_section.get_value("tags", []) as Array).values()
		set(value): _section.set_value("tags", value)
	
	var is_valid: bool:
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
	
	# TODO type
	var custom_commands: Array:
		get: return _get_custom_commands("custom_commands-v2")
		set(value): _section.set_value("custom_commands-v2", value)

	var _section: ConfigFileSection
	
	func _init(section: ConfigFileSection) -> void:
		self._section = section

	func _notification(what: int) -> void:
		if NOTIFICATION_PREDELETE == what:
			utils.disconnect_all(self)

	func fmt_string(str: String) -> String:
		var bin_path := _bin_path()
		str = str.replace("{{EDITOR_PATH}}", bin_path)
		str = str.replace("{{EDITOR_DIR}}", bin_path.get_base_dir())
		return str

	func as_process(args: PackedStringArray) -> OSProcessSchema:
		var process_path := _bin_path()
		var final_args := []
		final_args.append_array(extra_arguments)
		final_args.append_array(args)
		return OSProcessSchema.new(process_path, final_args)

	func as_fmt_process(process_path: String, args: PackedStringArray) -> OSProcessSchema:
		var result_path := self.fmt_string(process_path)
		var result_args: PackedStringArray
		var raw_args := extra_arguments.duplicate()
		raw_args.append_array(args)
		for arg in raw_args:
			arg  = self.fmt_string(arg)
			result_args.append(arg)
		return OSProcessSchema.new(result_path, result_args)

	func run() -> void:
		var command: Dictionary = _find_custom_command_by_name("Run", custom_commands)
		as_fmt_process(command.path as String, command.args as PackedStringArray).create_process()
	
	func emit_tags_edited() -> void:
		tags_edited.emit()
	
	func is_self_contained() -> bool:
		if not is_valid:
			return false
		var sub_file_exists := func(file: String) -> bool:
			return FileAccess.file_exists(path.get_base_dir().path_join(file))
		return sub_file_exists.call("_sc_") or sub_file_exists.call("._sc_")
	
	func match_name(search: String) -> bool:
		var sanitazed_name := _sanitize_name(name)
		var sanitazed_search := _sanitize_name(search)
		var findn := sanitazed_name.findn(sanitazed_search)
		return findn > -1
	
	func match_version_hint(hint: String, ignore_mono:=false) -> bool:
		return VersionHint.are_equal(self.version_hint, hint, ignore_mono)
	
	func get_version() -> String:
		var parsed := VersionHint.parse(version_hint)
		if parsed.is_valid:
			return parsed.version
		else:
			return ""
	
	func get_cfg_file_path() -> String:
		var cfg_file_name := get_cfg_file_name()
		if cfg_file_name.is_empty():
			return ""
		var cfg_folder := ""
		if is_self_contained():
			cfg_folder = path.get_base_dir().path_join("editor_data")
		else:
			cfg_folder = OS.get_config_dir().path_join("Godot")
		if cfg_folder.is_empty():
			return ""
		return cfg_folder.path_join(cfg_file_name)
	
	func get_cfg_file_name() -> String:
		var version := get_version()
		if version.is_empty():
			return ""
		if version.begins_with("3"):
			return "editor_settings-3.tres"
		elif version.begins_with("4"):
			return "editor_settings-4.tres"
		else:
			return ""
	
	func _bin_path() -> String:
		var process_path: String
		if OS.has_feature("windows") or OS.has_feature("linux"):
			process_path = ProjectSettings.globalize_path(path)
		elif OS.has_feature("macos"):
			process_path = ProjectSettings.globalize_path(path + mac_os_editor_path_postfix)
		return process_path
	
	func _sanitize_name(name: String) -> String:
		return name.replace(" ", "")
	
	# TODO type
	func _find_custom_command_by_name(name: String, src:=[]) -> Variant:
		for command: Dictionary in src:
			if command.name == name:
				return command
		return null
	
	# TODO type
	func _get_custom_commands(key: String) -> Array:
		var commands := _section.get_value(key, []) as Array
		if _find_custom_command_by_name("Run", commands) == null:
			commands.append({
				'name': 'Run',
				'icon': 'Play',
				'path': '{{EDITOR_PATH}}',
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
	
	## filter: Optional[Callable[[Item], bool]]
	func _init(filter: Variant =null) -> void:
		if filter == null:
			filter = func(x: Variant) -> bool: return true
		_filter = filter
	
	func by_name(name: String) -> Selector:
		return Selector.new(func(el: Item) -> bool:
			return _filter.call(el) and el.match_name(name)
		)
	
	func by_version_hint(hint: String, ignore_mono:=false) -> Selector:
		return Selector.new(func(el: Item) -> bool:
			return _filter.call(el) and el.match_version_hint(hint, ignore_mono)
		)
	
	func select(editors: List) -> Array[Item]:
		var result: Array[Item] = []
		for el in editors.all():
			if _filter.call(el):
				result.append(el)
		return result
	
	func select_first_or_null(editors: List) -> Item:
		var res := select(editors)
		if len(res) > 0:
			return res[0]
		else:
			return null
	
	func select_exact_one(editors: List) -> Item:
		var res := select(editors)
		if len(res) == 1:
			return res[0]
		else:
			if len(res) > 1:
				Output.push("There is ambiguity between editors to run.\n%s" % "\n".join(res))
			return null
	
	static func from_cmd(cmd: CliParser.ParsedCommandResult) -> Selector:
		var name := cmd.args.first_option_value(["name", "n"])
		var version_hint := cmd.args.first_option_value(["version-hint", "vh"])
		var ignore_mono := cmd.args.has_options(["ignore-mono", "im"])
		var selector := Selector.new()
		if not name.is_empty():
			selector = selector.by_name(name)
		if not version_hint.is_empty():
			selector = selector.by_version_hint(version_hint, ignore_mono)
		return selector
