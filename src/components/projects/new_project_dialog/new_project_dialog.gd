extends "res://src/components/projects/install_project_dialog/install_project_dialog.gd"

signal created(path)


func _ready():
	super._ready()
	
	min_size = Vector2(640, 215) * Config.EDSCALE
	
	confirmed.connect(func():
		var dir = _project_path_line_edit.text.strip_edges()
		var project_file_path = dir.path_join("project.godot")

		var initial_settings = ConfigFile.new()
		initial_settings.set_value("application", "config/name", _project_name_edit.text.strip_edges())
		initial_settings.set_value("application", "config/icon", "res://icon.png")
		var err = initial_settings.save(project_file_path)
		if err:
			_error("%s %s: %s." % [
				tr("Couldn't create project.godot in project path."), tr("Code"), err
			])
			return
		else:
			var img: Texture2D = preload("res://assets/default_project_icon.svg")
			img.get_image().save_png(dir.path_join("icon.png"))
			created.emit(project_file_path)
	)
