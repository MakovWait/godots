class_name ExecCommand


class Route extends Routes.Item:
	var _ctx: CliContext

	func _init(ctx: CliContext):
		_ctx = ctx

	func route(cmd: CliParser.ParsedCommandResult, user_args: PackedStringArray):
		var selector = LocalEditors.Selector.from_cmd(cmd)
		var explicit = false
		if cmd.args.has_options(["name", "n", "version-hint", "vh"]):
			explicit = true
		var cfg_path = cmd.args.get_first_name()
		ExecCommand.new(_ctx.editors, _ctx.projects).execute(Request.new(selector, user_args, explicit))

	func match(cmd: CliParser.ParsedCommandResult, user_args: PackedStringArray) -> bool:
		return cmd.namesp == "exec"


class Request:
	var selector: LocalEditors.Selector
	var user_args: PackedStringArray
	var explicit: bool

	func _init(selector: LocalEditors.Selector, user_args: PackedStringArray, explicit):
		self.selector = selector
		self.user_args = user_args
		self.explicit = explicit


var _editors: LocalEditors.List
var _projects: Projects.List


func _init(editors: LocalEditors.List, projects: Projects.List):
	_editors = editors
	_projects = projects


func execute(req: Request) -> void:
	var editor: LocalEditors.Item = _find_editor(req)
	if not editor:
		Output.push("Editor was not found")
		return
	Output.push("Using %s" % editor)
	var process = editor.as_process(req.user_args)
	Output.push("Executing %s" % process)
	process.create_process()


func _find_editor(req: Request) -> LocalEditors.Item:
	if req.explicit:
		return _find_explicit(req)
	else:
		Output.push_array("No explicit arguments were provided (-vh | -n). Attempting to derive an editor from user arguments")
		return _find_implicit(req)


func _find_explicit(req: Request) -> LocalEditors.Item:
	return req.selector.select_exact_one(_editors)


func _find_implicit(req: Request) -> LocalEditors.Item:
	var project_base_dir = DirAccess.open(_get_wd(req))
	var game_or_script_path = _first_not_empty([
		_get_script_path(req), 
		_get_game_path(req)
	])
	if not game_or_script_path.begins_with("res://"):
		project_base_dir.change_dir(game_or_script_path.get_base_dir())
	
	project_base_dir = project_base_dir.get_current_dir()
	Output.push("Using path: %s" % project_base_dir)
	
	var editor = _find_editor_by_dir(project_base_dir, _is_upwards(req.user_args))
	return editor


func _find_editor_by_dir(base_dir: String, upwards: bool) -> LocalEditors.Item:
	var editor = _find_by_project_godot_file(base_dir)
	if editor:
		return editor
	
	editor = _find_by_godot_version_file(base_dir)
	if editor:
		return editor
	
	if not upwards:
		Output.push("-u|--upwards was not provided; neither 'project.godot' nor '.godot-version' was found at %s" % base_dir)
	
	if upwards and not (base_dir == "/" or base_dir.is_empty()):
		return _find_editor_by_dir(base_dir.get_base_dir(), upwards)
	
	return null


func _find_by_godot_version_file(base_dir: String) -> LocalEditors.Item:
	var godot_version_file = base_dir.path_join(".godot-version")
	if not FileAccess.file_exists(godot_version_file):
		return null
	var file = FileAccess.open(godot_version_file, FileAccess.READ)
	var version_hint = file.get_line()
	return LocalEditors.Selector.new().by_version_hint(version_hint).select_exact_one(_editors)


func _find_by_project_godot_file(base_dir: String) -> LocalEditors.Item:
	var project_godot_file = base_dir.path_join("project.godot")
	if not FileAccess.file_exists(project_godot_file):
		return null
	if _projects.has(project_godot_file):
		var project = _projects.retrieve(project_godot_file)
		if project and project.is_valid and not project.has_invalid_editor:
			return project.editor
	
	var project_info = Projects.ExternalProjectInfo.new(project_godot_file)
	project_info.load(false)
	
	var version_hint = project_info.version_hint
	return LocalEditors.Selector.new().by_version_hint(version_hint).select_exact_one(_editors)


func _get_wd(req: Request):
	var wd = DirAccess.open(".")
	var project_path = _first_not_empty([
		_get_positional_with_any_suffix(["project.godot"], req.user_args),
		_get_opt_value("--path", req.user_args),
	])

	if not project_path.is_empty() and not project_path.begins_with("res://"):
		var err = wd.change_dir(project_path)
		if err:
			wd.change_dir(project_path.get_base_dir())
	return wd.get_current_dir()


func _first_not_empty(opts):
	for opt in opts:
		if not opt.is_empty():
			return opt
	return ""


func _get_script_path(req: Request):
	var script_path = _first_not_empty([
		_get_opt_value("-s", req.user_args),
		_get_opt_value("--script", req.user_args),
	])
	return script_path


func _get_game_path(req: Request):
	return _get_positional_with_any_suffix([".scn", ".tscn", ".res", ".tres"], req.user_args)


func _get_positional_with_any_suffix(suffixes: Array[String], args: PackedStringArray):
	for arg in args:
		prints(arg, suffixes, arg.is_empty(), arg.begins_with("-"), suffixes.any(func(suff): return arg.ends_with(suff)))
		if not arg.is_empty() and not arg.begins_with("-"):
			if suffixes.any(func(suff): return arg.ends_with(suff)):
				return arg
	return ""


func _get_opt_value(opt, args: PackedStringArray):
	var opt_flag_idx = args.find(opt)
	if opt_flag_idx != -1 and opt_flag_idx + 1 < len(args):
		return args[opt_flag_idx + 1]
	return ""


func _is_upwards(args: PackedStringArray):
	return '-u' in args or '--upwards' in args
