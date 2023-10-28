extends HBoxContainer

var btn: Button


func _init():
	add_spacer(true)
	add_spacer(true)


func clear():
	if is_instance_valid(btn):
		btn.hide()
		btn.queue_free()


func create(callback: Callable):
	clear()
	btn = Button.new()
	btn.pressed.connect(callback)
	btn.text = tr("Retry")
	add_child(btn)
	move_child(btn, 1)
