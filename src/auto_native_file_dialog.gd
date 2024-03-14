extends Node


func _enter_tree():
	get_tree().node_added.connect(_on_node_added)


func _exit_tree():
	get_tree().node_added.disconnect(_on_node_added)


func _on_node_added(node: Node):
	if node is FileDialog:
		node.use_native_dialog = Config.USE_NATIVE_FILE_DIALOG.ret()
