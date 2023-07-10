extends Control

const theme_source = preload("res://theme/theme.gd")


@export var _editor_install_scene: PackedScene


func _ready():
	_test_intall("user://versions/result2/")
	pass


func _enter_tree() -> void:
	theme_source.set_scale(Config.EDSCALE)
	theme = theme_source.create_editor_theme(null)


func _test_intall(path):
	var editor_install = _editor_install_scene.instantiate()
	add_child(editor_install)
	editor_install.init("Godot", path)
#	editor_install.installed.connect(func(name, exec_path):
#		installed.emit(name, ProjectSettings.globalize_path(exec_path))
#	)
	editor_install.popup_centered_ratio()
