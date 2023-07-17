@tool
extends EditorPlugin


const scene_popup: PackedScene = preload("res://addons/quick_script_change/QuickChangePopup.tscn")
const KEY_TO_CALL_POPUP = KEY_SHIFT
const MS_DETECT_INPUT = 300
const RECENTLY_SCRIPTS_COUNT = 10

var editor_interface := get_editor_interface()
var script_editor := editor_interface.get_script_editor()

var popup: Popup
var text_edit: LineEdit
var scroll_container: Control

var last_time_shift_pressed: int
var shift_was_pressed: bool = false

var recently_scripts: Array[String]


func _enter_tree() -> void:
	popup = scene_popup.instantiate()
	text_edit = popup.get_child(0).get_child(0) as LineEdit
	scroll_container = popup.get_child(0).get_child(1).get_child(0) as Control

	text_edit.text_changed.connect(_on_change_text)

	get_editor_interface().get_base_control().add_child(popup)
	popup.hide()


func _exit_tree() -> void:
	text_edit.text_changed.disconnect(_on_change_text)
	popup.hide()
	popup.queue_free()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_TO_CALL_POPUP and key_event.is_pressed():
			if shift_was_pressed and (Time.get_ticks_msec() - last_time_shift_pressed) < MS_DETECT_INPUT:
				shift_was_pressed = false
				_show_popup()
			else:
				shift_was_pressed = true
				last_time_shift_pressed = Time.get_ticks_msec()


func _show_popup():
	popup.show()
	text_edit.grab_focus()

	if text_edit.text == "":
		_spawn_buttons(recently_scripts)


func _on_change_text(text):
	if popup == null or not popup.visible:
		return

	if text == "":
		_spawn_buttons(recently_scripts)
		return

	var all_paths := _get_filelist("res://", ["gd"])
	var filtered := all_paths.filter(func(path): return path.to_lower().contains(text.to_lower()))
	_spawn_buttons(filtered)


func _erase_all_buttons():
	for child in scroll_container.get_children():
		child.queue_free()


func _spawn_buttons(all_paths):
	_erase_all_buttons()

	for path in all_paths:
		var btn = Button.new()
		scroll_container.add_child(btn)

		btn.text = path
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(func(): _on_click_btn(path))


func _on_click_btn(path):
	var load_script := load(path)
	if load_script != null:
		editor_interface.set_main_screen_editor("Script")
		editor_interface.edit_script(load_script)

		_add_script_to_recent(path)

	popup.hide()


func _add_script_to_recent(path):
	if recently_scripts.has(path):
		recently_scripts.erase(path)

	recently_scripts.push_front(path)

	if recently_scripts.size() > RECENTLY_SCRIPTS_COUNT:
		recently_scripts.resize(RECENTLY_SCRIPTS_COUNT)


func _get_filelist(scan_dir : String, filter_exts : Array = []) -> Array[String]:
	var my_files : Array[String] = []
	var dir := DirAccess.open(scan_dir)
	if not dir:
		printerr("Warning: could not open directory: ", scan_dir)
		return []

	if dir.list_dir_begin() != OK:
		printerr("Warning: could not list contents of: ", scan_dir)
		return []

	var file_name := dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			my_files += _get_filelist(dir.get_current_dir() + "/" + file_name, filter_exts)
		else:
			if filter_exts.size() == 0:
				my_files.append(dir.get_current_dir() + "/" + file_name)
			else:
				for ext in filter_exts:
					if file_name.get_extension() == ext:
						my_files.append(dir.get_current_dir() + "/" + file_name)
		file_name = dir.get_next()
	return my_files
