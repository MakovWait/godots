class_name Projects

class List extends RefCounted:
	const dict = preload("res://src/extensions/dict.gd")
	
	var _cfg := ConfigFile.new()
	var _projects: Dictionary[String, Item] = {}
	var _cfg_path: String
	var _default_icon: Texture2D
	var _local_editors: LocalEditors.List
	
	func _init(cfg_path: String, local_editors: LocalEditors.List, default_icon: Texture2D) -> void:
		_cfg_path = cfg_path
		_local_editors = local_editors
		_default_icon = default_icon
	
	func add(project_path: String, editor_path: String) -> Item:
		var project := Item.new(
			ConfigFileSection.new(project_path, IConfigFileLike.of_config(_cfg)),
			ExternalProjectInfo.new(project_path, _default_icon),
			_local_editors
		)
		project.favorite = false
		if !editor_path.is_empty():
			project.editor_path = editor_path
		_projects[project_path] = project
		return project
	
	func all() -> Array[Item]:
		var result: Array[Item] = []
		for x: Item in _projects.values():
			result.append(x)
		return result
	
	func retrieve(project_path: String) -> Item:
		return _projects[project_path]
	
	func has(project_path: String) -> bool:
		return _projects.has(project_path)
	
	func erase(project_path: String) -> void:
		_projects.erase(project_path)
		_cfg.erase_section(project_path)
	
	func get_editors_to_bind() -> Array[Dictionary]:
		return _local_editors.as_option_button_items()
	
	func get_owners_of(editor: LocalEditors.Item) -> Array[Item]:
		var result: Array[Item]
		for project in all():
			if project.editor_is(editor):
				result.append(project)
		return result
	
	# TODO type
	func get_all_tags() -> Array:
		var set := Set.new()
		for project: Item in _projects.values():
			for tag: String in project.tags:
				set.append(tag.to_lower())
		return set.values()
	
	func load() -> Error:
		cleanup()
		var err := _cfg.load(_cfg_path)
		if err: return err
		for section in _cfg.get_sections():
			_projects[section] = Item.new(
				ConfigFileSection.new(section, IConfigFileLike.of_config(_cfg)),
				ExternalProjectInfo.new(section, _default_icon),
				_local_editors
			)
		return Error.OK
	
	func cleanup() -> void:
		dict.clear_and_free(_projects)
	
	func save() -> Error:
		return _cfg.save(_cfg_path)
	
	func get_last_opened() -> Projects.Item:
		var last_opened := _ProjectsCache.get_last_opened_project()
		return retrieve(last_opened) if has(last_opened) else null


class Item:
	signal internals_changed
	signal loaded
	
	var show_edit_warning: bool:
		get: return _section.get_value("show_edit_warning", true)
		set(value): _section.set_value("show_edit_warning", value)
	
	var path: String:
		get: return _section.name
	
	var name: String:
		get: return _external_project_info.name
		set(value): _external_project_info.name = value
	
	var editor_name: String:
		get: return _get_editor_name()
	
	var icon: Texture2D:
		get: return _external_project_info.icon

	var favorite: bool:
		get: return _section.get_value("favorite", false)
		set(value): _section.set_value("favorite", value)
	
	var editor: LocalEditors.Item:
		get: 
			if has_invalid_editor:
				return null
			return _local_editors.retrieve(editor_path)
	
	var editor_path: String:
		get: return _section.get_value("editor_path", "")
		set(value): 
			show_edit_warning = true
			_section.set_value("editor_path", value)
	
	var has_invalid_editor: bool:
		get: return not _local_editors.editor_is_valid(editor_path)
	
	var is_valid: bool:
		get: return edir.path_is_valid(path)
	
	# TODO type
	var editors_to_bind: Array:
		get: return _get_editors_to_bind()
	
	var is_missing: bool:
		get: return _external_project_info.is_missing
	
	var is_loaded: bool:
		get: return _external_project_info.is_loaded
	
	var tags: Array:
		set(value): _external_project_info.tags = value
		get: return _external_project_info.tags
	
	var last_modified: int:
		get: return _external_project_info.last_modified
	
	# TODO type
	var features: Array:
		get: return _external_project_info.features
	
	var version_hint: String:
		get: return _external_project_info.version_hint
		set(value): _external_project_info.version_hint = value

	var has_version_hint: bool:
		get: return _external_project_info.has_version_hint

	var custom_commands: Array:
		get: return _get_custom_commands("custom_commands-v2")
		set(value): _section.set_value("custom_commands-v2", value)

	var _external_project_info: ExternalProjectInfo
	var _section: ConfigFileSection
	var _local_editors: LocalEditors.List
	
	func _init(
		section: ConfigFileSection, 
		project_info: ExternalProjectInfo,
		local_editors: LocalEditors.List
	) -> void:
		self._section = section
		self._external_project_info = project_info
		self._local_editors = local_editors
		self._local_editors.editor_removed.connect(
			_check_editor_changes
		)
		self._local_editors.editor_name_changed.connect(_check_editor_changes)
		project_info.loaded.connect(func() -> void: loaded.emit())
	
	func before_delete_as_ref_counted() -> void:
		utils.disconnect_all(self)
		if _external_project_info:
			_external_project_info.before_delete_as_ref_counted()
	
	func load(with_icon:=true) -> void:
		_external_project_info.load(with_icon)
	
	func editor_is(editor: LocalEditors.Item) -> bool:
		if has_invalid_editor:
			return false
		return self.editor == editor
	
	func _get_editor_name() -> String:
		if has_invalid_editor:
			return '<null>'
		else:
			return _local_editors.retrieve(editor_path).name

	func _check_editor_changes(editor_path: String) -> void:
		if editor_path == self.editor_path:
			emit_internals_changed()
	
	func emit_internals_changed() -> void:
		internals_changed.emit()
	
	func as_process(args: PackedStringArray) -> OSProcessSchema:
		assert(not has_invalid_editor)
		var editor := _local_editors.retrieve(editor_path)
		var result_args := [
			"--path",
			ProjectSettings.globalize_path(path).get_base_dir(),
		]
		result_args.append_array(args)
		return editor.as_process(result_args)
	
	func fmt_string(str: String) -> String:
		if not has_invalid_editor:
			var editor := _local_editors.retrieve(editor_path)
			str = editor.fmt_string(str)
		str = str.replace(
			'{{PROJECT_DIR}}', ProjectSettings.globalize_path(self.path).get_base_dir()
		)
		return str
	
	func as_fmt_process(process_path: String, args: PackedStringArray) -> OSProcessSchema:
		var result_path := process_path
		var result_args: PackedStringArray
		var raw_args := []
		if not has_invalid_editor:
			result_path = self.fmt_string(process_path)
			if process_path == '{{EDITOR_PATH}}':
				raw_args.append_array(editor.extra_arguments)
		raw_args.append_array(args)
		for arg: String in raw_args:
			arg = self.fmt_string(arg)
			result_args.append(arg)
		return OSProcessSchema.new(result_path, result_args)
	
	func edit() -> void:
		var command: Dictionary = _find_custom_command_by_name("Edit", custom_commands)
		as_fmt_process(command.path as String, command.args as PackedStringArray).create_process()
		_ProjectsCache.set_last_opened_project(path)
	
	func run() -> void:
		var command: Dictionary = _find_custom_command_by_name("Run", custom_commands)
		as_fmt_process(command.path as String, command.args as PackedStringArray).create_process()
	
	# TODO type
	func _find_custom_command_by_name(name: String, src:=[]) -> Variant:
		for command: Dictionary in src:
			if command.name == name:
				return command
		return null
	
	# TODO type
	func _get_custom_commands(key: String) -> Array:
		var commands: Array = _section.get_value(key, [])
		if not _find_custom_command_by_name("Edit", commands):
			commands.append({
				'name': 'Edit',
				'icon': 'Edit',
				'path': '{{EDITOR_PATH}}',
				'args': ['--path', '{{PROJECT_DIR}}' ,'-e'],
				'allowed_actions': [
					CommandViewer.Actions.EXECUTE, 
					CommandViewer.Actions.EDIT, 
					CommandViewer.Actions.CREATE_PROCESS
				]
			})
		if not _find_custom_command_by_name("Run", commands):
			commands.append({
				'name': 'Run',
				'icon': 'Play',
				'path': '{{EDITOR_PATH}}',
				'args': ['--path', '{{PROJECT_DIR}}' ,'-g'],
				'allowed_actions': [
					CommandViewer.Actions.EXECUTE, 
					CommandViewer.Actions.EDIT, 
					CommandViewer.Actions.CREATE_PROCESS
				]
			})
		return commands
	
	#TODO type
	func _get_editors_to_bind() -> Array:
		var options := _local_editors.as_option_button_items()
		_external_project_info.sort_editor_options(options)
		return options


class _ProjectsCache:
	static func set_last_opened_project(path: String) -> void:
		Cache.set_value("projects", "last_opened_project", path)
		Cache.save()

	static func get_last_opened_project() -> String:
		var result := Cache.get_value("projects", "last_opened_project") as String
		return result if result else ""


class ExternalProjectInfo extends RefCounted:
	signal loaded
	
	var icon: Texture2D:
		get: return _icon

	var name: String:
		get: return _name
		set(value):
			if value.strip_edges().is_empty() or is_missing:
				return
			_name = value
			var cfg := ConfigFile.new()
			var err := cfg.load(_project_path)
			if not err:
				cfg.set_value(
					"application", 
					"config/name", 
					_name
				)
				cfg.save(_project_path)
	
	var has_version_hint: bool:
		get: return _version_hint != null
	
	var version_hint: String:
		get: return '' if _version_hint == null else _version_hint
		set(value):
			if is_missing:
				return
			_version_hint = value
			var cfg := ConfigFile.new()
			var err := cfg.load(_project_path)
			if not err:
				cfg.set_value(
					"godots", 
					"version_hint", 
					_version_hint
				)
				cfg.save(_project_path)

	var last_modified: int:
		get: return _last_modified
	
	var is_loaded: bool:
		get: return _is_loaded
	
	var is_missing: bool:
		get: return _is_missing
	
	# TODO type
	var tags: Array:
		set(value):
			_tags = value
			if is_missing:
				return
			var cfg := ConfigFile.new()
			var err := cfg.load(_project_path)
			if not err:
				var set := Set.new()
				for tag: String in _tags:
					set.append(tag.to_lower())
				cfg.set_value(
					"application", 
					"config/tags", 
					PackedStringArray(set.values())
				)
				cfg.save(_project_path)
		get: return Set.of(_tags).values()
	
	# TODO type
	var features: Array:
		get: return _features
	
	var _is_loaded := false
	var _project_path: String
	var _default_icon: Texture2D
	var _icon: Texture2D
	var _name := "Loading..."
	var _last_modified: int
	var _is_missing := false
	var _tags := []
	var _features := []
	var _config_version := -1
	var _has_mono_section := false
	## Optional[String], TODO type
	var _version_hint: Variant = null
	
	func _init(project_path: String, default_icon: Texture2D = null) -> void:
		_project_path = project_path
		_default_icon = default_icon
		_icon = default_icon
	
	func before_delete_as_ref_counted() -> void:
		utils.disconnect_all(self)
	
	func load(with_icon:=true) -> void:
		var cfg := ConfigFile.new()
		var err := cfg.load(_project_path)
		
		_name = cfg.get_value("application", "config/name", "Missing Project")
		_tags = cfg.get_value("application", "config/tags", [])
		_features = cfg.get_value("application", "config/features", [])
		_config_version = cfg.get_value("", "config_version", -1)
		_has_mono_section = cfg.has_section("mono")
		if cfg.has_section_key("godots", "version_hint"):
			_version_hint = cfg.get_value("godots", "version_hint")
			if _version_hint == '':
				_version_hint = null
		
		_last_modified = FileAccess.get_modified_time(_project_path)
		if with_icon:
			_icon = _load_icon(cfg)
		_is_missing = bool(err)
		
		_is_loaded = true
		loaded.emit()
	
	func _load_icon(cfg: ConfigFile) -> Texture2D:
		var result := _default_icon
		var icon_path: String = cfg.get_value("application", "config/icon", "")
		if not icon_path: return result
		var project_path := self._project_path.get_base_dir() + "/"
		if icon_path.begins_with("uid://"):
			var uid_cache := FileAccess.open(project_path + ".godot/uid_cache.bin", FileAccess.READ)
			if uid_cache.get_error() == OK:
				var entries := uid_cache.get_32()
				for i in entries:
					var id := uid_cache.get_64()
					var length := uid_cache.get_32()
					var rl := uid_cache.get_buffer(length)
					if ResourceUID.id_to_text(id) == icon_path:
						icon_path = rl.get_string_from_utf8()
						break

		icon_path = icon_path.replace("res://", project_path)
		
		if FileAccess.file_exists(icon_path):
			var icon_image := Image.new()
			var err := icon_image.load(icon_path)
			if not err:
				icon_image.resize(
					_default_icon.get_width(), _default_icon.get_height(), Image.INTERPOLATE_LANCZOS
				)
				result = ImageTexture.create_from_image(icon_image)
		return result
	
	# TODO type
	func sort_editor_options(options: Array) -> void:
		var has_cs_feature := "C#" in features
		var is_mono := has_cs_feature or _has_mono_section
		
		var check_stable := func(label: String) -> bool:
			return label.contains("stable")
		
		var check_mono := func(label: String) -> bool:
			return label.contains("mono")
		
		var check_version := func(label: String) -> bool:
			if _version_hint != null:
				if VersionHint.same_version(_version_hint as String, label):
					return true
			if _config_version == 3:
				return label.contains("3.0")
			elif _config_version == 4:
				return not label.contains("3.0") and not label.contains("4.")
			elif _config_version > 4:
				var is_version := func(feature: String) -> bool: 
					return feature.contains(".") and feature.substr(0, 3).is_valid_float()
				var version_tags := Array(features).filter(is_version)
				if len(version_tags) > 0:
					return label.contains(version_tags[0] as String)
				else:
					return label.contains("4.")
			else:
				return false
		
		var check_version_hint_similarity := func(version_hint: String) -> int:
			var score := VersionHint.similarity(_version_hint as String, version_hint)
			return score

		options.sort_custom(func(item_a: Dictionary, item_b: Dictionary) -> bool:
			var a := (item_a.version_hint as String).to_lower()
			var b := (item_b.version_hint as String).to_lower()
			
			if _version_hint != null:
				var sim_a: int = check_version_hint_similarity.call(a)
				var sim_b: int = check_version_hint_similarity.call(b)
				if sim_a != sim_b:
					return sim_a > sim_b
				return VersionHint.version_or_nothing(a) > VersionHint.version_or_nothing(b)

			if check_version.call(a) && !check_version.call(b):
				return true
			if check_version.call(b) && !check_version.call(a):
				return false

			if check_mono.call(a) && !check_mono.call(b):
				return true and is_mono
			if check_mono.call(b) && !check_mono.call(a):
				return false or not is_mono

			if check_stable.call(a) && !check_stable.call(b):
				return true
			if check_stable.call(b) && !check_stable.call(a):
				return false
			
			return VersionHint.version_or_nothing(a) > VersionHint.version_or_nothing(b)
		)
