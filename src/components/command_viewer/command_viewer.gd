class_name CommandViewer
extends AcceptDialog

const NEW_COMMAND_ACTIONS = [
	Actions.REMOVE, Actions.EXECUTE, Actions.CREATE_PROCESS, Actions.EDIT
]

@export var _command_view_scene: PackedScene
@export var _new_command_dialog_scene: PackedScene
@onready var _execute_output_dialog := $ExecuteOutputDialog as AcceptDialog

var _create_new_command_btn: Button
var _commands: Commands
var _command_creation_allowed := false


func _ready() -> void:
	title = tr("Command Viewer")
	_execute_output_dialog.min_size = Vector2(500, 250) * Config.EDSCALE

	visibility_changed.connect(func() -> void:
		if not visible:
			_commands = null
	)
	
	var help := add_button(tr("Help"))
	help.pressed.connect(func() -> void:
		OS.shell_open("https://github.com/MakovWait/godots/blob/main/.github/assets/FEATURES.md#edit-commands")
	)
	help.icon = get_theme_icon("ExternalLink", "EditorIcons")
	
	_create_new_command_btn = add_button(tr("New Command"))
	_create_new_command_btn.pressed.connect(func() -> void:
		_popup_new_command_dialog("", "", [], "Terminal", false, 
		func(cmd_name: String, cmd_path: String, cmd_args: PackedStringArray, cmd_icon: String, is_local: bool) -> void:
			if _commands:
				var command := _commands.add(
					cmd_name, cmd_path, cmd_args, is_local, cmd_icon,
					NEW_COMMAND_ACTIONS.duplicate()
				)
				_refresh()
		)
	)


func raise(commands: Commands, command_creation_allowed:=false) -> void:
	_commands = commands
	_command_creation_allowed = command_creation_allowed
	_update_view(_commands, _command_creation_allowed)
	popup_centered_ratio(0.4)


func _update_view(commands: Commands, command_creation_allowed:=false) -> void:
	if command_creation_allowed:
		_create_new_command_btn.show()
	else:
		_create_new_command_btn.hide()

	for c in %VBoxContainer.get_children():
		if c.has_method("hide"):
			c.call("hide")
		c.queue_free()
	
	for command in commands.all():
		_add_view(command, commands)


func _refresh() -> void:
	_update_view(_commands, _command_creation_allowed)


func _add_view(command: Command, commands: Commands) -> void:
	var command_view := _command_view_scene.instantiate() as CommandTextView
	%VBoxContainer.add_child(command_view)
	_set_text_to_command_view(command, command_view)
	if command.is_action_allowed(Actions.CREATE_PROCESS):
		command_view.create_process_btn.disabled = false
		command_view.create_process_btn.pressed.connect(func() -> void:
			command.create_process()
		)
	if command.is_action_allowed(Actions.REMOVE):
		command_view.remove_btn.disabled = false
		command_view.remove_btn.pressed.connect(func() -> void:
			var confirm := ConfirmationDialogAutoFree.new()
			confirm.dialog_text = tr("Are you sure to remove the command?")
			confirm.confirmed.connect(func() -> void:
				command.remove_from(commands)
				_refresh()
			)
			add_child(confirm)
			confirm.popup_centered()
		)
	if command.is_action_allowed(Actions.EXECUTE):
		command_view.execute_btn.disabled = false
		command_view.execute_btn.pressed.connect(func() -> void:
			var output := []
			var err := command.execute(output)
			var output_text := ""
			if len(output) > 0:
				output_text = output[0]
			
			var rich_text_label := %OutputLabel as RichTextLabel
			rich_text_label.custom_minimum_size = Vector2i(0, 100) * Config.EDSCALE
			rich_text_label.clear()
			rich_text_label.push_color(get_theme_color("string_color", "CodeEdit"))
			rich_text_label.append_text(output_text)
			(%ErrorCodeLabel as Label).text = str(err)
			_execute_output_dialog.popup_centered()
		)
	if command.is_action_allowed(Actions.EDIT):
		command_view.edit_btn.disabled = false
		command_view.edit_btn.pressed.connect(func() -> void:
			_popup_new_command_dialog(command.name(), command.path(), command.args(), command.icon(), command.is_local(),
			func(cmd_name: String, cmd_path: String, cmd_args: PackedStringArray, cmd_icon: String, is_local: bool) -> void:
				if _commands:
					_commands.add(
						cmd_name, cmd_path, cmd_args, is_local, cmd_icon,
						NEW_COMMAND_ACTIONS.duplicate()
					)
					_refresh()
			)
		)


func _set_text_to_command_view(command: Command, command_view: CommandTextView) -> void:
	var local_badge := tr("Local") if command.is_local() else tr("Global")
	command_view.set_text(
		"%s (%s):" % [command.name(), local_badge], 
		"", 
		str(command),
		command.icon()
	)


func _popup_new_command_dialog(cmd_name: String, cmd_path: String, cmd_args: PackedStringArray, cmd_icon: String, is_local: bool, created_callback: Callable) -> void:
	var new_dialog := _new_command_dialog_scene.instantiate() as CommandViewerNewCommandDialog
	new_dialog.created.connect(created_callback)
	add_child(new_dialog)
	new_dialog.init(cmd_name, cmd_path, cmd_args, cmd_icon, is_local)
	new_dialog.popup_centered()


class Actions:
	const CREATE_PROCESS = "create_process"
	const EXECUTE = "execute"
	const REMOVE = "remove"
	const EDIT = "edit"


class Command:
	var _name: String
	var _path: String
	var _args: PackedStringArray
	var _is_local: bool
	var _icon: String
	var _process_src: OSProcessSchema.Source
	var _allowed_actions: PackedStringArray
	
	func _init(
		name: String,
		path: String,
		args: PackedStringArray,
		icon: String,
		is_local: bool, 
		process_src: OSProcessSchema.Source, 
		allowed_actions: PackedStringArray
	) -> void:
		_icon = icon
		_name = name
		_path = path
		_args = args
		_is_local = is_local
		_process_src = process_src
		_allowed_actions = allowed_actions
	
	func icon() -> String:
		return _icon
	
	func is_local() -> bool:
		return _is_local
	
	func is_action_allowed(action: String) -> bool:
		return action in _allowed_actions
	
	func args() -> PackedStringArray:
		return _args
	
	func path() -> String:
		return _path
	
	func name() -> String:
		return _name
	
	func execute(output:=[]) -> int:
		return _process_src.get_os_process_schema(_path, _args).execute(
			output, true, true
		)
	
	func create_process() -> void:
		_process_src.get_os_process_schema(_path, _args).create_process(true)
	
	func remove_from(commands: Commands) -> void:
		commands.remove(_name, _is_local)
	
	func _to_string() -> String:
		return str(_process_src.get_os_process_schema(_path, _args))


class Commands:
	func all() -> Array[Command]:
		return []
	
	func add(name: String, path: String, args: PackedStringArray, is_local: bool, icon: String, allowed_actions: PackedStringArray) -> Command:
		assert(true, "Not implemented")
		return null
	
	func remove(name: String, is_local: bool) -> void:
		pass


class CustomCommandsSource:
	var custom_commands: Array:
		get: return _get_custom_commands()
		set(value): _set_custom_commands(value)
	
	func _get_custom_commands() -> Array:
		return []
	
	func _set_custom_commands(value: Array) -> void:
		pass


class CommandsInMemory extends CommandsWrap:
	func _init(base_process_src: OSProcessSchema.Source) -> void:
		super._init(CommandsDuo.new(
			CommandsGeneric.new(
				base_process_src,
				CustomCommandsSourceArray.new(),
				true,
			),
			CommandsGeneric.new(
				base_process_src,
				CustomCommandsSourceArray.new(),
				false,
			)
		))


class CustomCommandsSourceArray extends CustomCommandsSource:
	var _data: Array[Dictionary] = []
	
	func _init(data: Array[Dictionary]=[]) -> void:
		_data = data
	
	func _get_custom_commands() -> Array:
		return _data
	
	func _set_custom_commands(value: Array) -> void:
		_data = value


class CustomCommandsSourceDynamic extends CustomCommandsSource:
	signal edited
	
	var _delegate: Object
	
	func _init(delegate: Object) -> void:
		_delegate = delegate
	
	func _get_custom_commands() -> Array:
		return _delegate.get("custom_commands")
	
	func _set_custom_commands(value: Array) -> void:
		_delegate.set("custom_commands", value)
		edited.emit()


class CommandsDuo extends Commands:
	var _local: Commands
	var _global: Commands
	
	func _init(local: Commands, global: Commands) -> void:
		_local = local
		_global = global
	
	func all() -> Array[Command]:
		var result: Array[Command] = []
		result.append_array(_global.all())
		result.append_array(_local.all())
		return result
	
	func add(name: String, path: String, args: PackedStringArray, is_local: bool, icon: String, allowed_actions: PackedStringArray) -> Command:
		if is_local:
			return _local.add(name, path, args, is_local, icon, allowed_actions)
		else:
			return _global.add(name, path, args, is_local, icon, allowed_actions)
	
	func remove(name: String, is_local: bool) -> void:
		if is_local:
			return _local.remove(name, is_local)
		else:
			return _global.remove(name, is_local)


class CommandsWrap extends Commands:
	var _origin: Commands
	
	func _init(origin: Commands) -> void:
		_origin = origin
	
	func all() -> Array[Command]:
		return _origin.all()
	
	func add(name: String, path: String, args: PackedStringArray, is_local: bool, icon: String, allowed_actions: PackedStringArray) -> Command:
		return _origin.add(name, path, args, is_local, icon, allowed_actions)
	
	func remove(name: String, is_local: bool) -> void:
		_origin.remove(name, is_local)


class CommandsWithBasic extends CommandsWrap:
	var _basic: Array[Command]
	
	func _init(origin: Commands, basic: Array[Command]) -> void:
		super._init(origin)
		_basic = basic
	
	func all() -> Array[Command]:
		var result: Array[Command]
		result.append_array(_basic)
		result.append_array(super.all())
		return result


class CommandsGeneric extends Commands:
	var _custom_commands_source: CustomCommandsSource
	var _base_process_src: OSProcessSchema.Source
	var _is_local: bool
	
	func _init(base_process_src: OSProcessSchema.Source, custom_commands_source: CustomCommandsSource, is_local: bool) -> void:
		_base_process_src = base_process_src
		_custom_commands_source = custom_commands_source
		_is_local = is_local
	
	func all() -> Array[Command]:
		var result: Array[Command]
		var commands := _custom_commands_source.custom_commands
		result.append_array(commands.map(func(x: Dictionary) -> Command: return _to_command(
			x.name as String,
			x.path as String,
			x.args as PackedStringArray,
			x.allowed_actions as PackedStringArray,
			x.get('icon', 'Terminal') as String,
			_is_local
		)))
		return result
	
	func add(name: String, path: String, args: PackedStringArray, is_local: bool, icon: String, allowed_actions: PackedStringArray) -> Command:
		if is_local == _is_local:
			var commands := _custom_commands_source.custom_commands
			if _has_by_name(name):
				commands = commands.map(func(x: Dictionary) -> Dictionary:
					if x.name != name:
						return x
					else:
						return {
							"name": name,
							"path": path,
							"args": args,
							"icon": icon,
							"allowed_actions": allowed_actions
						}
				)
			else:
				commands.append({
					"name": name,
					"path": path,
					"args": args,
					"icon": icon,
					"allowed_actions": allowed_actions
				})
			_custom_commands_source.custom_commands = commands
			return _to_command(name, path, args, allowed_actions, icon, is_local)
		else:
			assert(true, "Not implemented")
			return null
	
	func remove(name: String, is_local: bool) -> void:
		if is_local == _is_local:
			var commands := _custom_commands_source.custom_commands
			commands = commands.filter(func(x: Dictionary) -> bool: return x.name != name)
			_custom_commands_source.custom_commands = commands
		else:
			assert(true, "Not implemented")
	
	func _has_by_name(name: String) -> bool:
		return len(
			_custom_commands_source.custom_commands.filter(func(x: Dictionary) -> bool: return x.name == name)
		) > 0
	
	func _to_command(name: String, path: String, args: PackedStringArray, allowed_actions: PackedStringArray, icon: String, is_local: bool) -> Command:
		return Command.new(name, path, args, icon, is_local, _base_process_src, allowed_actions)
