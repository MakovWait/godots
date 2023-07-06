extends HBoxContainer

signal clicked

@onready var _path_label: Label = %PathLabel
@onready var _title_label: Label = %TitleLabel

var _is_hovering = false
var _is_selected = false
var _get_actions_callback: Callable


func _ready():
	$Favorite/FavoriteButton.texture_normal = get_theme_icon("Favorites", "EditorIcons")
	
	$Icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	$Icon.custom_minimum_size = Vector2(64, 64)
	$Icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	mouse_entered.connect(func(): 
		_is_hovering = true
		queue_redraw()
	)
	mouse_exited.connect(func(): 
		_is_hovering = false
		queue_redraw()
	)


func init(item):
	_title_label.text = item.name
	_path_label.text = item.path
	
	_get_actions_callback = func():
		var run_btn = Button.new()
		run_btn.text = "Run"
		run_btn.pressed.connect(func():
			# TODO handle all OS
			OS.execute("open", [ProjectSettings.globalize_path(item.path)])
		)
		return [
			run_btn
		]


func get_actions():
	if _get_actions_callback:
		return _get_actions_callback.call()
	else:
		return []


func _input(event: InputEvent) -> void:
	var mb = event as InputEventMouseButton
	if mb and get_global_rect().has_point(event.position):
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
	queue_redraw()


func deselect():
	_is_selected = false
	queue_redraw()
