class_name DownloadsContainer
extends ScrollContainer


@onready var hbox = $HBoxContainer


func _ready():
	var update_scroll_container_visibility = func():
		self.visible = hbox.get_child_count() > 0
	hbox.child_entered_tree.connect(func(_node):
		update_scroll_container_visibility.call_deferred()
	)
	hbox.child_exiting_tree.connect(func(_node):
		update_scroll_container_visibility.call_deferred()
	)
	update_scroll_container_visibility.call()
	
	theme_changed.connect(_update_theme)


func _update_theme():
	self.add_theme_stylebox_override("panel", get_theme_stylebox("panel", "Tree"))


func add_download_item(item):
	hbox.add_child(item)
