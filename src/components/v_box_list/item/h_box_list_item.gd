class_name HBoxListItem
extends HBoxContainer

signal clicked
signal right_clicked
signal double_clicked
signal hover_changed(is_hovering: bool)
signal selected_changed(is_selected: bool)


var _is_hovering := false:
	set(value):
		if value == _is_hovering:
			return
		_is_hovering = value
		hover_changed.emit(_is_hovering)
		queue_redraw()
var _is_selected := false:
	set(value):
		if value == _is_selected:
			return
		_is_selected = value
		selected_changed.emit(_is_selected)


func _ready() -> void:
	pass


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion
		_is_hovering = get_global_rect().has_point(mouse_motion.position as Vector2)


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb:
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.double_click:
				double_clicked.emit()
			elif mb.is_pressed():
				clicked.emit()
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.is_pressed(): 
				right_clicked.emit()


func _draw() -> void:
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


func select() -> void:
	_is_selected = true
	queue_redraw()


func deselect() -> void:
	_is_selected = false
	queue_redraw()
