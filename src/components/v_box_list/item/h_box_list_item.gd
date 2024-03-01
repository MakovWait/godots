class_name HBoxListItem
extends HBoxContainer

signal clicked
signal right_clicked
signal double_clicked
signal hover_changed(is_hovering: bool)
signal selected_changed(is_selected: bool)


var _is_hovering = false:
	set(value):
		if value == _is_hovering:
			return
		_is_hovering = value
		hover_changed.emit(_is_hovering)
		queue_redraw()
var _is_selected = false:
	set(value):
		if value == _is_selected:
			return
		_is_selected = value
		selected_changed.emit(_is_selected)


func _ready():
	pass


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	
	if event is InputEventMouseMotion:
		_is_hovering = get_global_rect().has_point(event.position)

	var mb = event as InputEventMouseButton
	if mb and get_global_rect().has_point(event.position):
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.double_click:
				double_clicked.emit()
			elif mb.is_pressed(): 
				clicked.emit()
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.is_pressed(): 
				right_clicked.emit()


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
