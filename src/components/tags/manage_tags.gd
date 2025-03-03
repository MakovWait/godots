class_name ManageTagsControl
extends ConfirmationDialog

const forbidden_characters = ["/", "\\", "-"]

@export var _tag_scene: PackedScene

@onready var _item_tags_container: HFlowContainer = %ItemTagsContainer
@onready var _all_tags_container: HFlowContainer = %AllTagsContainer
@onready var _create_tag_dialog: ConfirmationDialog = $CreateTagDialog
@onready var _new_tag_name_edit: LineEdit = %NewTagNameEdit
@onready var _create_tag_button: Button = %CreateTagButton
@onready var _tag_error_label: Label = %TagErrorLabel

## Optional[Callable]
var _on_confirm_callback: Variant

func _ready() -> void:
#	super._ready()
	
	_tag_error_label.add_theme_color_override(
		"font_color", 
		get_theme_color("error_color", "Editor")
	)
	
	($VBoxContainer/Label as Control).theme_type_variation = "HeaderMedium"
	($VBoxContainer/Label3 as Control).theme_type_variation = "HeaderMedium"
	
	_item_tags_container.custom_minimum_size = Vector2(0, 100) * Config.EDSCALE
	_all_tags_container.custom_minimum_size = Vector2(0, 100) * Config.EDSCALE
	
	_create_tag_dialog.about_to_popup.connect(func() -> void:
		_new_tag_name_edit.clear()
		_new_tag_name_edit.grab_focus()
	)
	
	_create_tag_dialog.confirmed.connect(func() -> void:
		_add_to_all_tags(_new_tag_name_edit.text)
	)
	
	_create_tag_button.pressed.connect(func() -> void:
		_create_tag_dialog.popup_centered(
			Vector2(500, 0) * Config.EDSCALE
		)
	)
	_create_tag_button.icon = get_theme_icon("Add", "EditorIcons")
	
	confirmed.connect(func() -> void:
		if _on_confirm_callback:
			(_on_confirm_callback as Callable).call(_get_approved_tags())
		_on_confirm_callback = null
	)
	canceled.connect(func() -> void:
		_on_confirm_callback = null
	)
	
	_new_tag_name_edit.text_changed.connect(func(new_text: String) -> void:
		_tag_error_label.text = ""
		_tag_error_label.visible = false
		
		if new_text.is_empty():
			_tag_error_label.text = tr("Tag name can't be empty.")
			_tag_error_label.visible = true
		if new_text.contains(" "):
			_tag_error_label.text = tr("Tag name can't contain spaces.")
			_tag_error_label.visible = true
		if new_text.to_lower() != new_text:
			_tag_error_label.text = tr("Tag name must be lowercase.")
			_tag_error_label.visible = true
		for forbidden_char: String in forbidden_characters:
			if new_text.contains(forbidden_char):
				_tag_error_label.text = tr("These characters are not allowed in tags: %s.") % " ".join(forbidden_characters)
				_tag_error_label.visible = true
		
		_update_ok_button_enabled()
	)


# TODO type
func init(item_tags: Array, all_tags: Array, on_confirm: Callable) -> void:
	_tag_error_label.visible = false
	_tag_error_label.text = ""
	_update_ok_button_enabled()
	_on_confirm_callback = on_confirm
	
	_clear_tag_container_children(_item_tags_container)
	for tag: String in Set.of(item_tags).values():
		_add_to_item_tags(tag)

	_clear_tag_container_children(_all_tags_container)
	for tag: String in Set.of(all_tags).values():
		_add_to_all_tags(tag)


func _update_ok_button_enabled() -> void:
	_create_tag_dialog.get_ok_button().disabled = _tag_error_label.visible


func _add_to_item_tags(tag: String) -> void:
	if not _has_tag_with_text(tag):
		_add_tag_control_to(
			_item_tags_container, 
			tag, 
			true,
			func(tag_control: TagControl) -> void: tag_control.queue_free()
		)


func _add_to_all_tags(tag: String) -> void:
	_all_tags_container.remove_child(_create_tag_button)
	_add_tag_control_to(
		_all_tags_container, 
		tag, 
		false,
		func(_arg: Variant) -> void: _add_to_item_tags(tag)
	)
	_all_tags_container.add_child(_create_tag_button)


func _has_tag_with_text(text: String) -> bool:
	return _get_approved_tags().has(text.to_lower())


func _clear_tag_container_children(container: Control) -> void:
	for tag: Control in container.get_children():
		if not tag is Button:
			tag.free()


## on_pressed: Optional[Callable]
func _add_tag_control_to(parent: Control, text: String, display_close: bool, on_pressed:Variant=null) -> void:
	var tag_control: TagControl = _tag_scene.instantiate()
	parent.add_child(tag_control)
	tag_control.init(text, display_close)
	if on_pressed:
		tag_control.pressed.connect(func() -> void: (on_pressed as Callable).call(tag_control))


# TODO type
func _get_approved_tags() -> Array:
	var raw_tags := (
		_item_tags_container.get_children()
			.map(func(x: TagControl) -> String: return x.text)
			.filter(func(text: String) -> bool: return text is String)
			.map(func(text: String) -> String: return text.to_lower())
	)
	return Set.of(raw_tags).values()
