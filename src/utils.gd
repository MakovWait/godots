class_name utils


static func guess_editor_name(file_name: String) -> String:
	var base := file_name

	# ✅ Remove only the last extension (.exe, .x86_64, .zip, etc.)
	var last_dot := base.rfind(".")
	if last_dot != -1:
		base = base.substr(0, last_dot)

	var lower := base.to_lower()

	# ✅ Allow versions like 4.1, 4.1.1, 4.1.1.1, etc.
	var re_version := RegEx.new()
	re_version.compile(r"godot[-_]?v?(\d+(?:\.\d+)+)") 

	var re_channel := RegEx.new()
	re_channel.compile(r"-(alpha|beta|rc|stable)(\d*)")

	var version := ""
	var channel := ""
	var channel_num := ""
	var mono := lower.findn("mono") != -1 # detect Mono builds

	var m := re_version.search(lower)
	if m:
		version = m.get_string(1)

	var c := re_channel.search(lower)
	if c:
		channel = c.get_string(1)
		channel_num = c.get_string(2)

	if version == "":
		# Fallback: grab first version-looking substring
		var re_any_ver := RegEx.new()
		re_any_ver.compile(r"(\d+(?:\.\d+)+)")
		var mv := re_any_ver.search(lower)
		if mv:
			version = mv.get_string(1)

	if version == "":
		return base # fallback

	var suffix := ""
	if channel != "":
		suffix = " " + channel
		if channel_num != "":
			suffix += channel_num

	var name := "Godot v%s%s" % [version, suffix]
	if mono:
		name += " mono"

	return name


static func find_project_godot_files(dir_path: String) -> Array[edir.DirListResult]:
	var project_configs := edir.list_recursive(
		ProjectSettings.globalize_path(dir_path), 
		false,
		(func(x: edir.DirListResult) -> bool: 
			return x.is_file and x.file == "project.godot"),
		(func(x: String) -> bool: 
			return not x.get_file().begins_with("."))
	)
	return project_configs


static func response_to_json(response: Variant, safe:=true) -> Variant:
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
	if scale_ratio < 1:
		callback.call(Vector2i(
			cur_size.x * Config.EDSCALE * scale_ratio,
			cur_size.y * Config.EDSCALE * scale_ratio
		))


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
