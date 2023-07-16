static func unzip(zip_path, target_dir):
	DirAccess.make_dir_absolute(target_dir)

	var output = []
	var exit_code
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
