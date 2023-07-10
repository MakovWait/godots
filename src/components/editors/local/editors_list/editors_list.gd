extends VBoxList

signal item_removed(item_data)


func _post_add(item_data, item_control):
	item_control.removed.connect(
		func(): item_removed.emit(item_data)
	)
