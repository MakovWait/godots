class Projects extends RefCounted:
	const dict = preload("res://src/extensions/dict.gd")
	
	var _cfg = ConfigFile.new()
	var _projects = {}
	var _cfg_path
	var _default_icon
	var _local_editors
	
	func _init(cfg_path, local_editors, default_icon) -> void:
		_cfg_path = cfg_path
		_local_editors = local_editors
		_default_icon = default_icon
	
	func add(project_path, editor_path) -> Project:
		var project = Project.new(
			ConfigFileSection.new(project_path, _cfg),
			ExternalProjectInfo.new(project_path, _default_icon),
			_local_editors
		)
		project.favorite = false
		project.editor_path = editor_path
		_projects[project_path] = project
		return project
	
	func all() -> Array[Project]:
		var result: Array[Project] = []
		for x in _projects.values():
			result.append(x)
		return result
	
	func retrieve(project_path) -> Project:
		return _projects[project_path]
	
	func has(project_path) -> bool:
		return _projects.has(project_path)
	
	func erase(project_path) -> void:
		_projects.erase(project_path)
		_cfg.erase_section(project_path)
	
	func get_editors_to_bind():
		return _local_editors.as_option_button_items()
	
	func load() -> Error:
		dict.clear_and_free(_projects)
		var err = _cfg.load(_cfg_path)
		if err: return err
		for section in _cfg.get_sections():
			_projects[section] = Project.new(
				ConfigFileSection.new(section, _cfg),
				ExternalProjectInfo.new(section, _default_icon),
				_local_editors
			)
		return Error.OK
	
	func save() -> Error:
		return _cfg.save(_cfg_path)


class Project:
	const dir = preload("res://src/extensions/dir.gd")
	
	signal internals_changed
	
	var path:
		get: return _section.name
	
	var name:
		get: return _external_project_info.name
	
	var editor_name:
		get: return _get_editor_name()
	
	var icon:
		get: return _external_project_info.icon

	var favorite:
		get: return _section.get_value("favorite", false)
		set(value): _section.set_value("favorite", value)
	
	var editor_path:
		get: return _section.get_value("editor_path", "")
		set(value): _section.set_value("editor_path", value)
	
	var has_invalid_editor:
		get: return not _local_editors.editor_is_valid(editor_path)
	
	var is_valid:
		get: return dir.path_is_valid(path)
	
	var _external_project_info: ExternalProjectInfo
	var _section: ConfigFileSection
	var _local_editors
	
	func _init(
		section: ConfigFileSection, 
		project_info: ExternalProjectInfo,
		local_editors
	) -> void:
		self._section = section
		self._external_project_info = project_info
		self._local_editors = local_editors
		self._local_editors.editor_removed.connect(
			_check_editor_changes
		)
		self._local_editors.editor_name_changed.connect(_check_editor_changes)
	
	func load():
		_external_project_info.load()
	
	func _get_editor_name():
		if has_invalid_editor:
			return 'Missing'
		else:
			return _local_editors.retrieve(editor_path).name

	func _check_editor_changes(editor_path):
		if editor_path == self.editor_path:
			emit_internals_changed()
	
	func emit_internals_changed():
		internals_changed.emit()


class ExternalProjectInfo extends RefCounted:
	signal loaded
	
	var icon:
		get: return _icon

	var name:
		get: return _name

	var last_modied:
		get: return _last_modified
	
	var is_loaded:
		get: return _is_loaded

	var _is_loaded = false
	var _project_path
	var _default_icon
	var _icon
	var _name
	var _last_modified
	
	func _init(project_path, default_icon):
		_project_path = project_path
		_default_icon = default_icon
		icon = default_icon
	
	func load():
		var cfg = ConfigFile.new()
		cfg.load(_project_path)
		
		_name = cfg.get_value("application", "config/name", "unknown")
		_icon = _load_icon(cfg)
		
		is_loaded = true
		loaded.emit()
	
	func _load_icon(cfg):
		var result
		var icon_path: String = cfg.get_value("application", "config/icon")
		icon_path = icon_path.replace("res://", self._project_path.get_base_dir() + "/")

		var icon_image = Image.new()
		var err = icon_image.load(icon_path)
		if not err:
			icon_image.resize(
				_default_icon.get_width(), _default_icon.get_height(), Image.INTERPOLATE_LANCZOS
			)
			result = ImageTexture.create_from_image(icon_image)
		else:
			result = _default_icon
		return result
