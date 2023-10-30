class_name EditorCfgCommand


class Route extends Routes.Item:
	var _ctx: CliContext

	func _init(ctx: CliContext):
		_ctx = ctx

	func route(cmd: CliParser.ParsedCommandResult, user_args: PackedStringArray):
		var selector = LocalEditors.Selector.from_cmd(cmd)
		var cfg_path = cmd.args.get_first_name()
		var mode = Mode.MERGE
		if not cmd.args.first_option_value(["override", "o"]).is_empty():
			mode = Mode.OVERRIDE
		elif not cmd.args.first_option_value(["merge", "m"]).is_empty():
			mode = Mode.MERGE
		EditorCfgCommand.new(_ctx.editors, cfg_path, mode).execute(Request.new(selector))

	func match(cmd: CliParser.ParsedCommandResult, user_args: PackedStringArray) -> bool:
		return cmd.verb == "cfg"


class Request:
	var selector: LocalEditors.Selector
	
	func _init(selector: LocalEditors.Selector):
		self.selector = selector


enum Mode {
	MERGE,
	OVERRIDE
}

var _editors: LocalEditors.List
var _cfg_path: String
var _mode: Mode


func _init(editors: LocalEditors.List, cfg_path: String, mode: Mode):
	_editors = editors
	_cfg_path = cfg_path
	_mode = mode


func execute(req: Request) -> void:
	var editor: LocalEditors.Item = req.selector.select_exact_one(_editors)
	if not editor:
		return
	
	var editor_cfg_file_path = editor.get_cfg_file_path()
	if editor_cfg_file_path.is_empty():
		Output.push("Editor config was not found")
		return
	
	var editor_cfg = ConfigFile.new()
	var editor_cfg_load_err = editor_cfg.load(editor_cfg_file_path)
	Output.push_array([editor_cfg_file_path, editor_cfg_load_err, editor_cfg.get_section_keys("resource")])
