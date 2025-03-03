class_name OSProcessSchema


var _path: String
var _args: PackedStringArray


func _init(path: String, args: PackedStringArray) -> void:
	_path = path
	_args = args


func execute(output:=[], read_stderr:=false, open_console:=false) -> int:
	return OS.execute(_path, _args, output, read_stderr, open_console)


func create_process(open_console:=false) -> int:
	return OS.create_process(_path, _args, open_console)


func with_args(args: PackedStringArray) -> OSProcessSchema:
	var new_args := _args.duplicate()
	new_args.append_array(args)
	return OSProcessSchema.new(_path, new_args)


func to_dict() -> Dictionary:
	return {
		'path': _path,
		'args': _args.duplicate()
	}


func _to_string() -> String:
	var args := [_path]
	args.append_array(_args)
	return " ".join(args.filter(func(x: String) -> bool: return not x.is_empty()).map(func(x: String) -> String: return '"%s"' % x))


class Source:
	func get_os_process_schema(path: String, args: PackedStringArray) -> OSProcessSchema:
		return OSProcessSchema.new(path, args)


class FmtSource extends Source:
	var _src: Object
	
	func _init(src: Object) -> void:
		assert(src.has_method("as_fmt_process"))
		_src = src
	
	func get_os_process_schema(path: String, args: PackedStringArray) -> OSProcessSchema:
		return _src.call("as_fmt_process", path, args)
