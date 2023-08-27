extends AcceptDialog

@onready var _main_command_view: VBoxContainer = %MainCommandView
@onready var _alternative_command_view: VBoxContainer = %AlternativeCommandView


func _ready() -> void:
	title = tr("Command Viewer")


func raise(main_schema, alternative_schema):
	_main_command_view.set_text(
		"%s:" % tr("Command"), 
		"", 
		_schema_to_string(main_schema)
	)
	if alternative_schema:
		_alternative_command_view.set_text(
			"%s:" % tr("Alternative MacOS Command"), 
			tr("MacOS alternative command. Guessed path to editor bin."), 
			_schema_to_string(alternative_schema)
		)
	else:
		_alternative_command_view.hide()
	popup_centered_ratio(0.4)


func _schema_to_string(schema):
	var args = [schema.path]
	args.append_array(schema.args)
	return " ".join(args.filter(func(x): return not x.is_empty()).map(func(x): return '"%s"' % x))
