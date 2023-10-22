class_name OpenEditor

class Route extends Routes.Item:
	func route(cmd: CliParser.ParsedCommandResult, user_args: PackedStringArray):
		var name = cmd.args.first_option_value(["name", "n"])
		var working_dir = cmd.args.get_first_name(".") if name.is_empty() else ""
		OpenEditor.new().execute(OpenEditor.Request.new(name, user_args, working_dir))

	func match(cmd: CliParser.ParsedCommandResult, user_args: PackedStringArray) -> bool:
		return cmd.verb == "run"

class Request:
	var name_pattern: String
	var user_args: PackedStringArray
	var working_dir: String

	func _init(name_pattern: String, user_args: PackedStringArray, working_dir: String = "."):
		self.name_pattern = name_pattern
		self.user_args = user_args
		self.working_dir = working_dir

var _editors: LocalEditors.List

func _init():
	_editors = LocalEditors.List.new(Config.EDITORS_CONFIG_PATH)

func execute(req: Request) -> void:
	if _editors.load() == Error.OK:
		var editor: LocalEditors.Item = null

		if req.name_pattern.is_empty():
			var project_path = DirAccess.open(req.working_dir).get_current_dir().path_join("project.godot")
			editor = _find_editor_by_proj_godot(project_path)
		else:
			editor = _find_editor_by_name(req.name_pattern)

		if editor != null:
			_run_editor(editor, req.user_args)
	else:
		Output.push("Some error happend during editors loading!")

func _find_editor_by_proj_godot(project_path: String) -> LocalEditors.Item:
	var result: LocalEditors.Item = null

	if FileAccess.file_exists(project_path):
		result = _find_editor_by_project(project_path)
		result = result if result else _find_editor_by_external_project(project_path)
	
		if not result:
			Output.push("Editor not found: either the project isn't bound to an editor or `project.godot` lacks a `version_hint`.")
	else:
		Output.push("Editor not found as path to `project.godot` does not exist.")

	return result
	
func _find_editor_by_project(project_path) -> LocalEditors.Item:
	var result: LocalEditors.Item = null
	var projects = Projects.List.new(
		Config.PROJECTS_CONFIG_PATH,
		_editors,
		null)
	projects.load()
	
	if projects.has(project_path):
		var project = projects.retrieve(project_path)
		result = project.editor
	
	return result
	
func _find_editor_by_external_project(project_path) -> LocalEditors.Item:
	var result: LocalEditors.Item = null
	var project_info = Projects.ExternalProjectInfo.new(project_path)
	project_info.load(false)

	if project_info.has_version_hint:
		result = _editors.retrieve_by_version_hint(project_info.version_hint)

	return result

func _find_editor_by_name(name_pattern: String) -> LocalEditors.Item:
	var result: LocalEditors.Item = null

	var editors = _editors.filter_by_name_pattern(name_pattern)
	if editors.size() == 1:
		result = editors[0]
	elif editors.size() > 1:
		var names: Array[String] = []
		for e in editors:
			names.append(e.name)
		Output.push("There is ambiguity between editors to run.\n%s" % "\n".join(names))
	else:
		Output.push("Required editor is not found!")

	return result

func _run_editor(editor: LocalEditors.Item, user_args: PackedStringArray) -> void:
	Output.push("Editor is found by path: %s " % editor.path)
	Output.push("Run editor with args `%s`" % user_args)
	var pid = editor.as_process(user_args).create_process()
	
	if (pid == -1):
		Output.push('An error occured when create editor process')
