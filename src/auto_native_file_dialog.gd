extends Node


func _enter_tree() -> void:
	get_tree().node_added.connect(_on_node_added)


func _exit_tree() -> void:
	get_tree().node_added.disconnect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is FileDialog:
		(node as FileDialog).use_native_dialog = Config.USE_NATIVE_FILE_DIALOG.ret() as bool
