static func unzip(zip_path, target_dir):
	DirAccess.make_dir_absolute(target_dir)

	var output = []
	var exit_code
	if OS.has_feature("windows"):
		pass
	elif OS.has_feature("macos"):
		exit_code = OS.execute(
			"unzip", 
			[
				"%s" % ProjectSettings.globalize_path(zip_path), 
				"-d", 
				"%s" % ProjectSettings.globalize_path(target_dir)
			], output, true
		)
		print(output.pop_front())
		print("unzip executed with exit code: %s" % exit_code)
	elif OS.has_feature("linux"):
		pass
	
