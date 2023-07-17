class_name HBoxListItem
extends HBoxContainer

signal clicked
signal double_clicked


var _is_hovering = false
var _is_selected = false


func _ready() -> void:
	mouse_entered.connect(func(): 
		_is_hovering = true
		queue_redraw()
	)
	mouse_exited.connect(func(): 
		_is_hovering = false
		queue_redraw()
	)


func _input(event: InputEvent) -> void:
	var mb = event as InputEventMouseButton
	if mb and get_global_rect().has_point(event.position):
		if not _is_hovering:
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.double_click and visible:
				double_clicked.emit()
			elif mb.is_pressed() and visible: 
				clicked.emit()


func _draw():
	if _is_hovering:
		draw_style_box(
			get_theme_stylebox("hover", "Tree"),
			Rect2(Vector2.ZERO, size)
		)
	
	if _is_selected:
		draw_style_box(
			get_theme_stylebox("selected", "Tree"),
			Rect2(Vector2.ZERO, size)
		)
	
	draw_line(
		Vector2(0, size.y + 1), 
		Vector2(size.x, size.y + 1), 
		get_theme_color("guide_color", "Tree")
	)


func select():
	_is_selected = true
	queue_redraw()


func deselect():
	_is_selected = false
	queue_redraw()
