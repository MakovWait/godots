extends Node

const DESKTOP_ENTRY_FOLDER = ".local/share/applications"
const APP_FOLDER = ".local/godots.app"
const DESKTOP_ENTRY_NAME = "godots.desktop"

@export_file() var gui_scene_path: String


func _ready() -> void:
	var args := OS.get_cmdline_args()
	var user_args := OS.get_cmdline_user_args()

	# Check if running as Flatpak by checking for the .flatpak-info file
	var is_flatpak := FileAccess.file_exists("/.flatpak-info")

	# Check and create Godots desktop entry if needed
	if OS.get_name() == "Linux" and not OS.has_feature("editor") and not is_flatpak:
		_ensure_desktop_entry()

	if _is_cli_mode(args):
		Output.push("Run cli mode")
		var adjusted_args := args.slice(1) if OS.has_feature("editor") else args
		CliMain.main(adjusted_args, user_args)
		_exit()
	else:
		Output.push("Run window mode")
		add_child.call_deferred((load(gui_scene_path) as PackedScene).instantiate())
	pass


func _is_cli_mode(args: PackedStringArray) -> bool:
	if args.size() > 1 and OS.has_feature("editor"):
		return true
	elif args.size() >= 1 and OS.has_feature("template"):
		return true
	return false


func _ensure_desktop_entry() -> void:
	var home := OS.get_environment("HOME")
	var desktop_entry_path := home.path_join(DESKTOP_ENTRY_FOLDER).path_join(DESKTOP_ENTRY_NAME)
	var app_path := home.path_join(APP_FOLDER)

	# Create godots.app folder and copy executable
	var dir := DirAccess.open("user://")
	if dir.dir_exists(app_path):
		return
	else:
		dir.make_dir_recursive(app_path)

	var current_exe := OS.get_executable_path()
	var new_exe_path := app_path.path_join("Godots.x86_64")
	var run_path := new_exe_path

	var is_debug := OS.is_debug_build()
	var script_path := current_exe.get_base_dir().path_join("Godots.sh")

	if is_debug and FileAccess.file_exists(script_path):
		var new_script_path := app_path.path_join("Godots.sh")
		if DirAccess.copy_absolute(script_path, new_script_path) == OK:
			OS.execute("chmod", ["+x", new_script_path])
			run_path = new_script_path
	else:
		is_debug = false

	if DirAccess.copy_absolute(current_exe, new_exe_path) == OK:
		# Make it executable
		OS.execute("chmod", ["+x", new_exe_path])

		# Create desktop entry
		# Copy and save the icon
		var icon_path := app_path.path_join("icon.png")
		var icon := load("res://icon.svg") as Texture2D
		var image := icon.get_image()
		image.save_png(icon_path)

		# Create desktop entry
		var desktop_entry := _create_desktop_entry(run_path, icon_path, is_debug)
		var file := FileAccess.open(desktop_entry_path, FileAccess.WRITE)
		if file:
			file.store_string(desktop_entry)
			file.close()
			# Make desktop entry executable
			OS.execute("chmod", ["+x", desktop_entry_path])
		else:
			printerr("Failed to create desktop entry")
	else:
		printerr("Failed to copy executable")


func _create_desktop_entry(exec: String, icon: String, terminal: bool) -> String:
	return (
		"""\
[Desktop Entry]
Name=Godots
GenericName=Libre game engine version manager
Comment=Ultimate go-to hub for managing your Godot versions and projects!
Exec="{exec}" %f
Icon={icon}
Terminal={terminal}
PrefersNonDefaultGPU=true
Type=Application
Categories=Development;IDE;
StartupWMClass=Godot
"""
		. format({"exec": exec, "icon": icon, "terminal": terminal})
	)


func _exit() -> void:
	get_tree().quit()
