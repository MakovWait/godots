class_name CommandViewer
extends AcceptDialog

@export var _command_view_scene: PackedScene
@export var _new_command_dialog_scene: PackedScene
@onready var _execute_output_dialog = $ExecuteOutputDialog

var _create_new_command_btn: Button
var _commands: Commands


func _ready() -> void:
	title = tr("Command Viewer")
	$ExecuteOutputDialog.min_size = Vector2(500, 250) * Config.EDSCALE

	visibility_changed.connect(func():
		if not visible:
			_commands = null
	)
	
	_create_new_command_btn = add_button(tr("New Command"))
	_create_new_command_btn.pressed.connect(func():
		var new_dialog = _new_command_dialog_scene.instantiate() as CommandViewerNewCommandDialog
		add_child(new_dialog)
		new_dialog.popup_centered()
		new_dialog.created.connect(func(cmd_name, cmd_args, is_local):
			if _commands:
				var command = _commands.add(
					cmd_name, cmd_args, is_local, 
					[Actions.REMOVE, Actions.EXECUTE, Actions.CREATE_PROCESS]
				)
				_add_view(command, _commands)
		)
	)


func raise(commands: Commands, command_creation_allowed=false):
	_commands = commands
	
	if command_creation_allowed:
		_create_new_command_btn.show()
	else:
		_create_new_command_btn.hide()

	for c in %VBoxContainer.get_children():
		if c.has_method("hide"):
			c.hide()
		c.queue_free()
	
	for command in commands.all():
		_add_view(command, commands)

	popup_centered_ratio(0.4)


func _add_view(command: Command, commands: Commands):
	var command_view = _command_view_scene.instantiate() as CommandTextView
	%VBoxContainer.add_child(command_view)
	command_view.set_text(
		"%s:" % command.name(), 
		"", 
		str(command)
	)
	if command.is_action_allowed(Actions.CREATE_PROCESS):
		command_view.create_process_btn.disabled = false
		command_view.create_process_btn.pressed.connect(func():
			command.create_process()
		)
	if command.is_action_allowed(Actions.REMOVE):
		command_view.remove_btn.disabled = false
		command_view.remove_btn.pressed.connect(func():
			var confirm = ConfirmationDialogAutoFree.new()
			confirm.dialog_text = tr("Are you sure to remove the command?")
			confirm.confirmed.connect(func():
				command.remove_from(commands)
				command_view.hide()
				command_view.queue_free()
			)
			add_child(confirm)
			confirm.popup_centered()
		)
	if command.is_action_allowed(Actions.EXECUTE):
		command_view.execute_btn.disabled = false
		command_view.execute_btn.pressed.connect(func():
			var output = []
			var err = command.execute(output)
			var output_text = ""
			if len(output) > 0:
				output_text = output[0]
			
			var rich_text_label = %OutputLabel
			rich_text_label.custom_minimum_size = Vector2i(0, 100) * Config.EDSCALE
			rich_text_label.clear()
			rich_text_label.push_color(get_theme_color("string_color", "CodeEdit"))
			rich_text_label.append_text(output_text)
			%ErrorCodeLabel.text = str(err)
			_execute_output_dialog.popup_centered()
		)


class Actions:
	const CREATE_PROCESS = "create_process"
	const EXECUTE = "execute"
	const REMOVE = "remove"


class Command:
	var _name: String
	var _args: PackedStringArray
	var _is_local: bool
	var _base_process: OSProcessSchema
	var _allowed_actions: PackedStringArray
	
	func _init(
		name: String,
		args: PackedStringArray, 
		is_local: bool, 
		base_process: OSProcessSchema, 
		allowed_actions: PackedStringArray
	):
		_name = name
		_args = args
		_is_local = is_local
		_base_process = base_process
		_allowed_actions = allowed_actions
	
	func is_action_allowed(action: String) -> bool:
		return action in _allowed_actions
	
	func name() -> String:
		return _name
	
	func execute(output:=[]) -> int:
		return _base_process.with_args(_args).execute(
			output, true, true
		)
	
	func create_process():
		_base_process.with_args(_args).create_process()
	
	func remove_from(commands: Commands):
		commands.remove(_name, _is_local)
	
	func _to_string():
		return str(_base_process.with_args(_args))


class Commands:
	func all() -> Array[Command]:
		return []
	
	func add(name: String, args: PackedStringArray, is_local: bool, allowed_actions: PackedStringArray) -> Command:
		assert(true, "Not implemented")
		return null
	
	func remove(name: String, is_local: bool) -> void:
		pass


class CustomCommandsSource:
	var custom_commands: 
		get: return _get_custom_commands()
		set(value): _set_custom_commands(value)
	
	func _get_custom_commands():
		pass
	
	func _set_custom_commands(value):
		pass


class CommandsInMemory extends CommandsWrap:
	func _init(base_process: OSProcessSchema):
		super._init(CommandsDuo.new(
			CommandsGeneric.new(
				base_process,
				CustomCommandsSourceArray.new(),
				true,
			),
			CommandsGeneric.new(
				base_process,
				CustomCommandsSourceArray.new(),
				false,
			)
		))


class CustomCommandsSourceArray extends CustomCommandsSource:
	var _data: Array[Dictionary] = []
	
	func _init(data: Array[Dictionary]=[]):
		_data = data
	
	func _get_custom_commands():
		return _data
	
	func _set_custom_commands(value):
		_data = value


class CustomCommandsSourceDynamic extends CustomCommandsSource:
	signal edited
	
	var _delegate
	
	func _init(delegate):
		_delegate = delegate
	
	func _get_custom_commands():
		return _delegate.custom_commands
	
	func _set_custom_commands(value):
		_delegate.custom_commands = value
		edited.emit()


class CommandsDuo extends Commands:
	var _local: Commands
	var _global: Commands
	
	func _init(local: Commands, global: Commands):
		_local = local
		_global = global
	
	func all() -> Array[Command]:
		var result: Array[Command] = []
		result.append_array(_global.all())
		result.append_array(_local.all())
		return result
	
	func add(name: String, args: PackedStringArray, is_local: bool, allowed_actions: PackedStringArray) -> Command:
		if is_local:
			return _local.add(name, args, is_local, allowed_actions)
		else:
			return _global.add(name, args, is_local, allowed_actions)
	
	func remove(name: String, is_local: bool) -> void:
		if is_local:
			return _local.remove(name, is_local)
		else:
			return _global.remove(name, is_local)


class CommandsWrap extends Commands:
	var _origin: Commands
	
	func _init(origin: Commands):
		_origin = origin
	
	func all() -> Array[Command]:
		return _origin.all()
	
	func add(name: String, args: PackedStringArray, is_local: bool, allowed_actions: PackedStringArray) -> Command:
		return _origin.add(name, args, is_local, allowed_actions)
	
	func remove(name: String, is_local: bool) -> void:
		_origin.remove(name, is_local)


class CommandsWithBasic extends CommandsWrap:
	var _basic: Array[Command]
	
	func _init(origin: Commands, basic: Array[Command]):
		super._init(origin)
		_basic = basic
	
	func all() -> Array[Command]:
		var result: Array[Command]
		result.append_array(_basic)
		result.append_array(super.all())
		return result


class CommandsGeneric extends Commands:
	var _custom_commands_source: CustomCommandsSource
	var _base_process: OSProcessSchema
	var _is_local: bool
	
	func _init(base_process: OSProcessSchema, custom_commands_source: CustomCommandsSource, is_local: bool):
		_base_process = base_process
		_custom_commands_source = custom_commands_source
		_is_local = is_local
	
	func all() -> Array[Command]:
		var result: Array[Command]
		var commands = _custom_commands_source.custom_commands
		result.append_array(commands.map(func(x): return _to_command(
			x.name,
			x.args,
			x.allowed_actions,
			_is_local
		)))
		return result
	
	func add(name: String, args: PackedStringArray, is_local: bool, allowed_actions: PackedStringArray) -> Command:
		if is_local == _is_local:
			var commands = _custom_commands_source.custom_commands
			commands.append({
				"name": name,
				"args": args,
				"allowed_actions": allowed_actions
			})
			_custom_commands_source.custom_commands = commands
			return _to_command(name, args, allowed_actions, is_local)
		else:
			assert(true, "Not implemented")
			return null
	
	func remove(name: String, is_local: bool) -> void:
		if is_local == _is_local:
			var commands = _custom_commands_source.custom_commands
			commands = commands.filter(func(x): return x.name != name)
			_custom_commands_source.custom_commands = commands
		else:
			assert(true, "Not implemented")

	func _to_command(name: String, args: PackedStringArray, allowed_actions: PackedStringArray, is_local: bool) -> Command:
		return Command.new(name, args, is_local, _base_process, allowed_actions)
