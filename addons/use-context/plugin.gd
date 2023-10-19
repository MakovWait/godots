@tool
extends EditorPlugin


const AUTOLOAD_NAME = "Context"


func _enter_tree():
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/use-context/context_node.gd")


func _exit_tree():
	remove_autoload_singleton(AUTOLOAD_NAME)
