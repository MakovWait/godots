extends HBoxContainer

signal tag_clicked(tag)

@export var _tag_scene: PackedScene = preload("res://src/components/tags/tag/tag.tscn")


func set_tags(tags):
	for child in get_children():
		child.queue_free()
	for tag in tags:
		var tag_control = _tag_scene.instantiate()
		add_child(tag_control)
		tag_control.init(tag)
		tag_control.pressed.connect(func(): tag_clicked.emit(tag))
