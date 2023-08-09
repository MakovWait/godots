extends VBoxContainer


@onready var _copy_to_clipboard: Button = %CopyToClipboard
@onready var _rich_text_label: RichTextLabel = %RichTextLabel
@onready var _title: Label = %Title

var _text = ""


func _ready() -> void:
	_copy_to_clipboard.tooltip_text = "Copy command to clipboard"
	_copy_to_clipboard.text = ""
	_copy_to_clipboard.flat = true
	_copy_to_clipboard.icon = get_theme_icon("ActionCopy", "EditorIcons")
	_copy_to_clipboard.pressed.connect(func():
		if _text and not _text.is_empty():
			DisplayServer.clipboard_set(_text)
	)


func set_text(title, tooltip, text):
	_title.tooltip_text = tooltip
	_title.text = title
	_text = text
	_rich_text_label.tooltip_text = tooltip
	_rich_text_label.clear()
	_rich_text_label.push_color(get_theme_color("string_color", "CodeEdit"))
	_rich_text_label.append_text(text)
