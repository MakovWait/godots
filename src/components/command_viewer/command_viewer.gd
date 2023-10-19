class_name CommandViewer
extends AcceptDialog

@onready var _main_command_view: VBoxContainer = %MainCommandView


func _ready() -> void:
	title = tr("Command Viewer")


func raise(main_schema: OSProcessSchema):
	_main_command_view.set_text(
		"%s:" % tr("Command"), 
		"", 
		_schema_dict_to_string(main_schema.to_dict())
	)
	popup_centered_ratio(0.4)


func _schema_dict_to_string(schema):
	var args = [schema.path]
	args.append_array(schema.args)
	return " ".join(args.filter(func(x): return not x.is_empty()).map(func(x): return '"%s"' % x))
