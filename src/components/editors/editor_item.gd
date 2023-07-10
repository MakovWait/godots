extends HBoxListItem

#signal edited(data: A)
signal removed


@onready var _path_label: Label = %PathLabel
@onready var _title_label: Label = %TitleLabel
@onready var _explore_button: Button = %ExploreButton

var _get_actions_callback: Callable


func _ready():
	super._ready()
	$Favorite/FavoriteButton.texture_normal = get_theme_icon("Favorites", "EditorIcons")
	
	$Icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	$Icon.custom_minimum_size = Vector2(64, 64) * Config.EDSCALE
	$Icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	_title_label.add_theme_font_override(
		"font", get_theme_font("title", "EditorFonts")
	)
	_title_label.add_theme_font_size_override(
		"font_size", get_theme_font_size("title_size", "EditorFonts")
	)
	_title_label.add_theme_color_override(
		"font_color",
		get_theme_color("font_color", "Tree")
	)

	_path_label.add_theme_color_override(
		"font_color",
		get_theme_color("font_color", "Tree")
	)
	_path_label.clip_text = true
	_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_label.structured_text_bidi_override = TextServer.STRUCTURED_TEXT_FILE
		
	_explore_button.icon = get_theme_icon("Load", "EditorIcons")


func init(item):
	_title_label.text = item.name
	_path_label.text = item.path
	
	_get_actions_callback = func():
		return [
			_make_button(
				"Run", 
				get_theme_icon("Play", "EditorIcons"),
				func():
					# TODO handle all OS
					OS.execute("open", [ProjectSettings.globalize_path(item.path)]),
			),
			_make_button(
				"Rename", 
				get_theme_icon("Edit", "EditorIcons"),
				func(): pass
			),
			_make_button(
				"Remove", 
				get_theme_icon("Remove", "EditorIcons"),
				func(): removed.emit()
			)
		]
	
	_explore_button.pressed.connect(func():
		OS.shell_show_in_file_manager(ProjectSettings.globalize_path(item.path).get_base_dir())
	)


func get_actions():
	if _get_actions_callback:
		return _get_actions_callback.call()
	else:
		return []


func apply_filter(filter):
	return filter.call({
		'name': _title_label.text,
		'path': _path_label.text
	})


static func _make_button(text, icon, on_pressed):
	var btn = Button.new()
	btn.icon = icon
	btn.text = text
	btn.pressed.connect(on_pressed)
	return btn
