extends "res://src/components/projects/install_project_dialog/install_project_dialog.gd"

signal about_to_install(project_name, project_dir)


func _ready():
	super._ready()
	confirmed.connect(func():
		about_to_install.emit(
			_project_name_edit.text.strip_edges(),
			_project_path_line_edit.text.strip_edges()
		)
	)
