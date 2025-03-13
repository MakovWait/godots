class_name zip

static func unzip(zip_path: String, target_dir: String) -> void:
	DirAccess.make_dir_absolute(target_dir)

	var output := []
	var exit_code: int
	if OS.has_feature("windows"):
		exit_code = OS.execute(
			"powershell.exe",
			[
				"-command",
				"\"Expand-Archive '%s' '%s'\" -Force" % [
					ProjectSettings.globalize_path(zip_path),
					ProjectSettings.globalize_path(target_dir)
				]
			], output, true
		)
		Output.push(output.pop_front())
		Output.push("unzip executed with exit code: %s" % exit_code)
	elif OS.has_feature("macos"):
		exit_code = OS.execute(
			"unzip",
			[
				"%s" % ProjectSettings.globalize_path(zip_path),
				"-d",
				"%s" % ProjectSettings.globalize_path(target_dir)
			], output, true
		)
		Output.push(output.pop_front())
		Output.push("unzip executed with exit code: %s" % exit_code)
	elif OS.has_feature("linux"):
		exit_code = OS.execute(
			"unzip",
			[
				"-o",
				"%s" % ProjectSettings.globalize_path(zip_path),
				"-d",
				"%s" % ProjectSettings.globalize_path(target_dir)
			], output, true
		)
		Output.push(output.pop_front())
		Output.push("unzip executed with exit code: %s" % exit_code)


## A procedure that unzips a zip file to a target directory, keeping the
## target directory as root, rather than the zip's root directory.
static func unzip_to_path(_zip: ZIPReader, destiny: String) -> Error:
	var files := _zip.get_files()
	var err: int

	for zip_file_name in files:
		if zip_file_name == files[0]:
			continue
		var target_file_name := destiny.path_join(zip_file_name.split("/", false, 1)[1])
		if zip_file_name.ends_with("/"):
			err = DirAccess.make_dir_recursive_absolute(target_file_name)
			if err != OK:
				return (err as Error)
		else:
			var file_contents: PackedByteArray = _zip.read_file(zip_file_name)
			var file := FileAccess.open(target_file_name, FileAccess.WRITE)
			if not file:
				return FileAccess.get_open_error()
			file.store_buffer(file_contents)
			file.close()
	return OK
