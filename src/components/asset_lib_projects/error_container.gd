extends HBoxContainer


var _texture: TextureRect = TextureRect.new()
var _label: Label = Label.new()


func _init():
	add_child(_texture)
	add_child(_label)


func _ready():
	_texture.texture = get_theme_icon("Error", "EditorIcons")
	_texture.size_flags_vertical = Control.SIZE_SHRINK_CENTER


func set_text(text):
	show()
	_label.text = text


func _notification(what):
	if NOTIFICATION_THEME_CHANGED == what:
		_label.add_theme_color_override("color", get_theme_color("error_color", "Editor"))
