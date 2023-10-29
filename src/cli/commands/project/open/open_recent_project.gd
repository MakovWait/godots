class_name OpenRecentProject


class Route extends Routes.Item:
	var _ctx: CliContext
	
	func _init(ctx: CliContext):
		_ctx = ctx
	
	func route(cmd: CliParser.ParsedCommandResult, user_args: PackedStringArray):
		OpenRecentProject.new(_ctx.editors, _ctx.projects).execute()

	func match(cmd: CliParser.ParsedCommandResult, user_args: PackedStringArray) -> bool:
		return cmd.args.has_options(["recent", "r"])


var _editors: LocalEditors.List
var _projects: Projects.List


func _init(editors: LocalEditors.List, projects: Projects.List):
	_editors = editors
	_projects = projects


func execute() -> void:
	var project = _projects.get_last_opened()
	if project:
		project.load(false)
		project.edit()
	else:
		Output.push("Recent project does not exist.")
