extends HBoxContainer

signal clicked

var _is_hovering = false
var _is_selected = false


func _ready():
	$Favorite/FavoriteButton.texture_normal = get_theme_icon("Favorites", "EditorIcons")
	
	$Icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	$Icon.custom_minimum_size = Vector2(64, 64)
	$Icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	mouse_entered.connect(func(): 
		_is_hovering = true
		queue_redraw();
	)
	mouse_exited.connect(func(): 
		_is_hovering = false
		queue_redraw();
	)


func _input(event):
	if event is InputEventMouseButton and get_rect().has_point(event.position):
		var mb = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.is_pressed(): 
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


func deselect():
	_is_selected = false
