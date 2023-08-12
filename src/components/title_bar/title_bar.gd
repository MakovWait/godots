extends HBoxContainer


@onready var _left_spacer = $LeftSpacer
@onready var _right_spacer = $RightSpacer
@onready var _gui_base = get_parent()

var _can_move = true
var _moving = false
var _click_pos = Vector2.ZERO


func _ready():
	if not DisplayServer.has_feature(DisplayServer.FEATURE_EXTEND_TO_TITLE) or Config.get_use_system_titlebar(false):
		queue_free()
		return
	
	_setup_title_label()
	
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_EXTEND_TO_TITLE, true)
	var window = get_window()
	if window:
		window.titlebar_changed.connect(_resize)
	_resize.call_deferred()


# obsolete
func add_button(btn):
	$ButtonsContainer.add_child(btn)


func _setup_title_label():
	var label : Label = $Label
	label.add_theme_font_override("font", get_theme_font("bold", "EditorFonts"))
	label.add_theme_font_size_override("font_size", get_theme_font_size("bold_size", "EditorFonts"))
	
	label.set_text_overrun_behavior(TextServer.OVERRUN_TRIM_ELLIPSIS)
	label.set_text_overrun_behavior(TextServer.OVERRUN_TRIM_ELLIPSIS)
	label.set_vertical_alignment(VERTICAL_ALIGNMENT_CENTER)
	label.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	label.set_mouse_filter(Control.MOUSE_FILTER_PASS)


func _gui_input(event):
	if not _can_move:
		return
	
	if event is InputEventMouseMotion and _moving:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			var w = get_window()
			if w:
				var mouse_pos = DisplayServer.mouse_get_position()
				w.position = mouse_pos - _click_pos
			pass
		else:
			_moving = false

	if event is InputEventMouseButton and get_rect().has_point(event.position):
		var mb = event as InputEventMouseButton
		var w = get_window()
		if w:
			if mb.button_index == MOUSE_BUTTON_LEFT:
				if mb.is_pressed():
					_click_pos = DisplayServer.mouse_get_position() - w.position
					_moving = true
				else:
					_moving = false
			if mb.button_index == MOUSE_BUTTON_LEFT and mb.double_click and mb.pressed:
				if DisplayServer.window_maximize_on_title_dbl_click():
					if w.mode == Window.MODE_WINDOWED:
						w.mode = Window.MODE_MAXIMIZED
					elif w.mode == Window.MODE_MAXIMIZED:
						w.mode = Window.MODE_WINDOWED
				elif DisplayServer.window_minimize_on_title_dbl_click():
					w.mode = Window.MODE_MINIMIZED
				_moving = false


func _resize():
	var buttons_offet = Vector2i(
		self.global_position.y + (self.size.y / 2),
		self.global_position.y + (self.size.y / 2)
	)
	DisplayServer.window_set_window_buttons_offset(
		buttons_offet,
		DisplayServer.MAIN_WINDOW_ID
	)
	var margin = DisplayServer.window_get_safe_title_margins(
		DisplayServer.MAIN_WINDOW_ID
	)
	if _left_spacer: 
		var w = margin.y if self.is_layout_rtl() else margin.x
		_left_spacer.custom_minimum_size = Vector2(w, 0)
	if _right_spacer: 
		var w = margin.x if self.is_layout_rtl() else margin.y
		_right_spacer.custom_minimum_size = Vector2(w, 0)
	_right_spacer.custom_minimum_size = _left_spacer.custom_minimum_size
	self.custom_minimum_size = Vector2(0, margin.z - self.global_position.y)
