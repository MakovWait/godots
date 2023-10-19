class_name utils


static func guess_editor_name(file_name: String):
	var possible_editor_name = file_name.get_file()
	var tokens_to_replace = []
	tokens_to_replace.append_array([
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
	])
	tokens_to_replace.append_array(["_", "-"])
	for token in tokens_to_replace:
		possible_editor_name = possible_editor_name.replace(token, " ")
	possible_editor_name = possible_editor_name.strip_edges()
	return possible_editor_name


static func find_project_godot_files(dir_path) -> Array[edir.DirListResult]:
	var project_configs = edir.list_recursive(
		ProjectSettings.globalize_path(dir_path), 
		false,
		(func(x: edir.DirListResult): 
			return x.is_file and x.file == "project.godot"),
		(func(x: String): 
			return not x.get_file().begins_with("."))
	)
	return project_configs
