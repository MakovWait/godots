class_name utils


static func guess_editor_name(file_name: String) -> String:
	var possible_editor_name := file_name.get_file()
	var tokens_to_replace: Array[String]
	tokens_to_replace.append_array(
		[
			"x11.64",
			"linux.64",
			"linux.x86_64",
			"linux.x86_32",
			"osx.universal",
			"macos.universal",
			"osx.fat",
			"osx32",
			"osx64",
			"win64",
			"win32",
			".%s" % file_name.get_extension()
		]
	)
	tokens_to_replace.append_array(["_", "-"])
	for token in tokens_to_replace:
		possible_editor_name = possible_editor_name.replace(token, " ")
	possible_editor_name = possible_editor_name.strip_edges()
	return possible_editor_name


static func find_project_godot_files(dir_path: String) -> Array[edir.DirListResult]:
	var project_configs := edir.list_recursive(
		ProjectSettings.globalize_path(dir_path),
		false,
		func(x: edir.DirListResult) -> bool: return x.is_file and x.file == "project.godot",
		func(x: String) -> bool: return not x.get_file().begins_with(".")
	)
	return project_configs


static func response_to_json(response: Variant, safe := true) -> Variant:
	var body := response[3] as PackedByteArray
	var string := body.get_string_from_utf8()
	if safe:
		return parse_json_safe(string)
	else:
		return JSON.parse_string(string)


static func parse_json_safe(string: String) -> Variant:
	var json := JSON.new()
	var err := json.parse(string)
	if err != OK:
		return null
	else:
		return json.data


static func fit_height(max_height: float, cur_size: Vector2i, callback: Callable) -> void:
	var scale_ratio := max_height / (cur_size.y * Config.EDSCALE)
	if scale_ratio < 1.0:
		callback.call(
			Vector2i(
				cur_size.x * int(Config.EDSCALE) * int(scale_ratio),
				cur_size.y * int(Config.EDSCALE) * int(scale_ratio)
			)
		)


static func disconnect_all(obj: Object) -> void:
	for obj_signal in obj.get_signal_list():
		for connection in obj.get_signal_connection_list(obj_signal.name as StringName):
			obj.disconnect(obj_signal.name as StringName, connection.callable as Callable)


static func prop_is_readonly() -> void:
	assert(false, "Property is readonly")


static func not_implemeted() -> Variant:
	assert(false, "Not Implemented")
	return null


static func empty_func() -> void:
	pass


static func obj_has_method(obj: Variant, method: StringName) -> bool:
	if obj is Object:
		return (obj as Object).has_method(method)
	else:
		return false
