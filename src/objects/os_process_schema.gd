class_name OSProcessSchema


var _path: String
var _args: PackedStringArray


func _init(path: String, args: PackedStringArray):
	_path = path
	_args = args


func execute(output:=[], read_stderr:=false, open_console:=false) -> int:
	return OS.execute(_path, _args, output, read_stderr, open_console)


func create_process(open_console:=false) -> int:
	return OS.create_process(_path, _args, open_console)


func to_dict():
	return {
		'path': _path,
		'args': _args.duplicate()
	}
