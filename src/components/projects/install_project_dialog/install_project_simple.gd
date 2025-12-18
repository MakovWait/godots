class_name InstallProjectSimpleDialog
extends "res://src/components/projects/install_project_dialog/install_project_dialog.gd"

signal about_to_install(project_name: String, project_dir: String)

## Optional[Callable]
var handle_dir_is_not_empty: Variant


func _ready() -> void:
	super._ready()
	_successfully_confirmed.connect(func() -> void:
		about_to_install.emit(
			_project_name_edit.text.strip_edges(),
			_project_path_line_edit.text.strip_edges()
		)
	)


func _handle_dir_is_not_empty(path: String) -> bool:
	if handle_dir_is_not_empty != null:
		return (handle_dir_is_not_empty as Callable).call(self, path)
	else:
		return super._handle_dir_is_not_empty(path)
