@tool
extends EditorPlugin

const scene_top_bar: PackedScene = preload("res://addons/script-name-on-top/topbar.tscn")
const MAX_RECENT_ITEMS = 10
const color_buttons := Color8(106, 180, 255, 255)
const color_background := Color8(66, 78, 120, 128)

var editor_interface := get_editor_interface()
var script_editor := editor_interface.get_script_editor()
var script_editor_menu: Control = script_editor.get_child(0).get_child(0)
var scene_tree_dock: Control = get_editor_interface().get_base_control().find_children("*", "SceneTreeDock", true, false)[0]
var scene_tree_editor: Control = scene_tree_dock.find_children("*", "SceneTreeEditor", true, false)[0]
var the_tree: Tree = scene_tree_editor.get_child(0)
var current_editor: ScriptEditorBase

var recently_opened: Array[String] = []
var extension_top_bar: MenuButton
var extension_popup: PopupMenu


func _enter_tree() -> void:
	turn_off_scripts_panel_if_on()

	# Wait until Godot Editor is fully loaded before continuing
	while script_editor_menu.get_children().size() < 13:
		await get_tree().process_frame

	# Make everything in the top bar not expand, while the extension_top_bar will expand
	for i in script_editor_menu.get_children():
		i.size_flags_horizontal = 0

	# Add extension_top_bar
	extension_top_bar = scene_top_bar.instantiate()
	script_editor_menu.add_child(extension_top_bar)
	script_editor_menu.move_child(extension_top_bar, -8)

	extension_popup = extension_top_bar.get_popup()

	extension_top_bar.pressed.connect(build_recent_scripts_list)
	extension_popup.id_pressed.connect(_on_recent_submenu_pressed)
	extension_popup.window_input.connect(_on_recent_submenu_window_input)

	# Get script that is initially open
	build_recent_scripts_list()
	editing_something_new(script_editor.get_current_editor())


func _process(_delta: float) -> void:
	# This is better than "editor_script_changed" signal since it includes when you edit other files such as .cfg
	if current_editor != script_editor.get_current_editor():
		current_editor = script_editor.get_current_editor()
		editing_something_new(current_editor)
	tree_recursive_highlight(the_tree.get_root())

	var bottom_bar := get_bottom_bar()
	if is_instance_valid(bottom_bar):
		# Show bottom row only if there's an error message
		var lbl_error_message: Label = bottom_bar.get_child(1).get_child(0)
		bottom_bar.visible = (lbl_error_message.text != "")


func _exit_tree() -> void:
	if is_instance_valid(extension_top_bar):
		extension_top_bar.queue_free()


func build_recent_scripts_list() -> void:
	extension_popup.clear()
	for i in recently_opened.size():
		var filepath: String = recently_opened[i]
		extension_popup.add_item(filepath)
	
	# Don't bother opening an empty menu
	if recently_opened.size() == 0:
		extension_popup.visible = false

func add_recent_script_to_array(recent_string: String) -> void:
	var find_existing: int = recently_opened.find(recent_string)
	if find_existing == -1:
		recently_opened.push_front(recent_string)
		if recently_opened.size() > MAX_RECENT_ITEMS:
			recently_opened.pop_back()
	else:
		recently_opened.push_front(recently_opened.pop_at(find_existing))


func turn_off_scripts_panel_if_on() -> void:
	var scripts_panel: Control = get_editor_interface().get_script_editor().get_child(0).get_child(1).get_child(0)
	if scripts_panel.visible == true:
		get_editor_interface().get_script_editor().get_child(0).get_child(0).get_child(0).get_popup().emit_signal("id_pressed", 14)


func editing_something_new(current_editor: ScriptEditorBase) -> void:
	if is_instance_valid(extension_top_bar):
		var new_text: String
		if is_instance_valid(script_editor.get_current_script()):
			new_text = script_editor.get_current_script().resource_path
			add_recent_script_to_array(new_text)
			extension_top_bar.modulate = Color(1,1,1,1)
		else:
			new_text = ""
			extension_top_bar.modulate = Color(0,0,0,0) # Make it invisible if not using it

		extension_top_bar.text = new_text
		extension_top_bar.tooltip_text = new_text


func is_main_screen_visible(screen) -> bool:
	# 0 = 2D, 1 = 3D, 2 = Script, 3 = AssetLib
	return editor_interface.get_editor_main_screen().get_child(2).visible


func get_bottom_bar() -> Control:
	var get_bottom_bar: Control = get_editor_interface().get_script_editor().get_current_editor()
	if is_instance_valid(get_bottom_bar):
		get_bottom_bar = get_bottom_bar.get_child(0)
		if is_instance_valid(get_bottom_bar):
			get_bottom_bar = get_bottom_bar.get_child(0)
			if is_instance_valid(get_bottom_bar) and get_bottom_bar.get_child_count() > 1:
				get_bottom_bar = get_bottom_bar.get_child(1)
				if is_instance_valid(get_bottom_bar):
					return get_bottom_bar
	return null


func tree_recursive_highlight(item) -> void:
	while item != null:
		item.set_custom_bg_color(0, Color(0,0,0,0))

		# Set color of only Script Buttons, not the Visibility Buttons
		for i in item.get_button_count(0):
			var tooltip_text = item.get_button_tooltip_text(0,i)

			item.set_button_color(0, i, Color(1,1,1,1))

			if tooltip_text.begins_with("Open Script: ") and is_main_screen_visible(2) == true:
				item.set_button_color(0, i, Color(1,1,1,1))
				# Change the script tooltip into a script path
				var script_path = tooltip_text.trim_prefix("Open Script: ")
				script_path = script_path.trim_suffix("This script is currently running in the editor.")
				script_path = script_path.strip_escapes()
				#print(scriptPath)
				#print(scriptEditor.get_current_script().resource_path)
				var current_script = script_editor.get_current_script()
				if current_script != null:
					if script_path == current_script.resource_path:
						item.set_button_color(0, i, color_buttons)
						item.set_custom_bg_color(0, color_background)

		tree_recursive_highlight(item.get_first_child())
		item = item.get_next()


func _on_recent_submenu_window_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed == true:
			# Erase item from list
			recently_opened.erase(extension_popup.get_item_text(extension_popup.get_focused_item()))
			build_recent_scripts_list()
			if recently_opened.size() > 0:
				# Refresh and display shrunken list correctly
				extension_top_bar.show_popup()
			else:
				# Don't bother opening an empty menu
				extension_popup.visible = false
		else:
			# Prevent switching to an item upon releasing right click
			extension_popup.hide_on_item_selection = false
			extension_popup.id_pressed.disconnect(_on_recent_submenu_pressed)
			await get_tree().process_frame
			extension_popup.hide_on_item_selection = true
			extension_popup.id_pressed.connect(_on_recent_submenu_pressed)

func _on_recent_submenu_pressed(pressedID: int) -> void:
	var recent_string: String = extension_popup.get_item_text(pressedID)
	var load_script := load(recent_string)
	if load_script != null:
		editor_interface.edit_script(load_script)
