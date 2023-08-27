extends ConfirmationDialog

const forbidden_characters = ["/", "\\", "-"]

@export var _tag_scene: PackedScene

@onready var _item_tags_container: HFlowContainer = %ItemTagsContainer
@onready var _all_tags_container: HFlowContainer = %AllTagsContainer
@onready var _create_tag_dialog: ConfirmationDialog = $CreateTagDialog
@onready var _new_tag_name_edit: LineEdit = %NewTagNameEdit
@onready var _create_tag_button: Button = %CreateTagButton
@onready var _tag_error_label: Label = %TagErrorLabel

var _on_confirm_callback

func _ready() -> void:
#	super._ready()
	
	_tag_error_label.add_theme_color_override(
		"font_color", 
		get_theme_color("error_color", "Editor")
	)
	
	$VBoxContainer/Label.theme_type_variation = "HeaderMedium"
	$VBoxContainer/Label3.theme_type_variation = "HeaderMedium"
	
	_item_tags_container.custom_minimum_size = Vector2(0, 100) * Config.EDSCALE
	_all_tags_container.custom_minimum_size = Vector2(0, 100) * Config.EDSCALE
	
	_create_tag_dialog.about_to_popup.connect(func():
		_new_tag_name_edit.clear()
		_new_tag_name_edit.grab_focus()
	)
	
	_create_tag_dialog.confirmed.connect(func():
		_add_to_all_tags(_new_tag_name_edit.text)
	)
	
	_create_tag_button.pressed.connect(func():
		_create_tag_dialog.popup_centered(
			Vector2(500, 0) * Config.EDSCALE
		)
	)
	_create_tag_button.icon = get_theme_icon("Add", "EditorIcons")
	
	confirmed.connect(func():
		if _on_confirm_callback:
			_on_confirm_callback.call(_get_approved_tags())
		_on_confirm_callback = null
	)
	canceled.connect(func():
		_on_confirm_callback = null
	)
	
	_new_tag_name_edit.text_changed.connect(func(new_text):
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
		for forbidden_char in forbidden_characters:
			if new_text.contains(forbidden_char):
				_tag_error_label.text = tr("These characters are not allowed in tags: %s.") % " ".join(forbidden_characters)
				_tag_error_label.visible = true
		
		_update_ok_button_enabled()
	)


func init(item_tags, all_tags, on_confirm):
	_tag_error_label.visible = false
	_tag_error_label.text = ""
	_update_ok_button_enabled()
	_on_confirm_callback = on_confirm
	
	_clear_tag_container_children(_item_tags_container)
	for tag in Set.of(item_tags).values():
		_add_to_item_tags(tag)

	_clear_tag_container_children(_all_tags_container)
	for tag in Set.of(all_tags).values():
		_add_to_all_tags(tag)


func _update_ok_button_enabled():
	_create_tag_dialog.get_ok_button().disabled = _tag_error_label.visible


func _add_to_item_tags(tag):
	if not _has_tag_with_text(tag):
		_add_tag_control_to(
			_item_tags_container, 
			tag, 
			true,
			func(tag_control): tag_control.queue_free()
		)


func _add_to_all_tags(tag):
	_all_tags_container.remove_child(_create_tag_button)
	_add_tag_control_to(
		_all_tags_container, 
		tag, 
		false,
		func(_arg): _add_to_item_tags(tag)
	)
	_all_tags_container.add_child(_create_tag_button)


func _has_tag_with_text(text):
	return _get_approved_tags().has(text.to_lower())


func _clear_tag_container_children(container):
	for tag in container.get_children():
		if not tag is Button:
			tag.free()


func _add_tag_control_to(parent, text, display_close, on_pressed=null):
	var tag_control = _tag_scene.instantiate()
	parent.add_child(tag_control)
	tag_control.init(text, display_close)
	if on_pressed:
		tag_control.pressed.connect(func(): on_pressed.call(tag_control))


func _get_approved_tags():
	var raw_tags = (
		_item_tags_container.get_children()
			.map(func(x): return x.text)
			.filter(func(text): return text is String)
			.map(func(text): return text.to_lower())
	)
	return Set.of(raw_tags).values()
