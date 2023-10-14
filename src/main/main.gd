extends Node

@export_file() var gui_scene_path: String


func _enter_tree():
	add_child(load(gui_scene_path).instantiate())
