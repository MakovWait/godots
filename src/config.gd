extends Node

var EDSCALE = 1
var AGENT = ""
const VERSION = "1.0.rc1"
const APP_CONFIG_PATH = "user://godots.cfg"
const APP_CACHE_PATH = "user://.cache"
const EDITORS_CONFIG_PATH = "user://editors.cfg"
const PROJECTS_CONFIG_PATH = "user://projects.cfg"
const VERSIONS_PATH = "user://versions"
const DOWNLOADS_PATH = "user://downloads"
const RELEASES_URL = "https://github.com/MakovWait/godots/releases"
const RELEASES_LATEST_API_ENDPOINT = "https://api.github.com/repos/MakovWait/godots/releases/latest"


var AGENT_HEADER:
	get: return "User-Agent: %s" % AGENT

var DEFAULT_EDITOR_TAGS:
	get: return get_default_editor_tags(["dev", "rc", "alpha", "4.x", "3.x", "stable", "mono"])

var DEFAULT_PROJECT_TAGS:
	get: return get_default_project_tags([])

var _cfg = ConfigFile.new()
var _cache = ConfigFile.new()


func _ready():
	_cfg.load(APP_CONFIG_PATH)
	_cache.load(APP_CACHE_PATH)
	assert(not VERSIONS_PATH.ends_with("/"))
	assert(not DOWNLOADS_PATH.ends_with("/"))
	AGENT = "Godots/%s (%s) Godot/%s" % [
		VERSION, 
		OS.get_name(), 
		Engine.get_version_info().string
	]


func _enter_tree() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(VERSIONS_PATH))
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(DOWNLOADS_PATH))
	
	EDSCALE = _get_auto_display_scale()


#https://github.com/godotengine/godot/blob/master/editor/editor_settings.cpp#L1400
func _get_auto_display_scale():
#	if OS.has_feature("macos"):
#		return DisplayServer.screen_get_max_scale()
#	else:
	var screen = DisplayServer.window_get_current_screen()
	if DisplayServer.screen_get_size(screen) == Vector2i():
		return 1.0

	# Use the smallest dimension to use a correct display scale on portrait displays.
	var smallest_dimension = min(DisplayServer.screen_get_size(screen).x, DisplayServer.screen_get_size(screen).y);
	if DisplayServer.screen_get_dpi(screen) >= 192 and smallest_dimension >= 1400:
		# hiDPI display.
		return 2.0
	elif smallest_dimension >= 1700:
		# Likely a hiDPI display, but we aren't certain due to the returned DPI.
		# Use an intermediate scale to handle this situation.
		return 1.5
	elif smallest_dimension <= 800:
		# Small loDPI display. Use a smaller display scale so that editor elements fit more easily.
		# Icons won't look great, but this is better than having editor elements overflow from its window.
		return 0.75
	return 1.0


func cache_get_value(section: String, key: String, default: Variant = null):
	return _cache.get_value(section, key, default)


func cache_set_value(section: String, key: String, value: Variant):
	_cache.set_value(section, key, value)


func cache_save():
	return _cache.save(APP_CACHE_PATH)


func get_remote_editors_checkbox_checked(key, default):
	return _cfg.get_value("remote_editor_checkbox", key, default)


func set_remote_editors_checkbox_checked(key, value):
	_cfg.set_value("remote_editor_checkbox", key, value)
	_cfg.save(APP_CONFIG_PATH)


func set_main_current_tab(tab):
	_cfg.set_value("main", "tab", tab)
	_cfg.save(APP_CONFIG_PATH)


func get_main_current_tab(default=0):
	return _cfg.get_value("main", "tab", default)


func get_default_editor_tags(default):
	return _cfg.get_value("app", "default_editor_tags", default)


func get_default_project_tags(default):
	return _cfg.get_value("app", "default_project_tags", default)


func set_auto_close(value):
	_cfg.set_value("app", "auto_close", value)
	_cfg.save(APP_CONFIG_PATH)


func get_auto_close():
	return _cfg.get_value("app", "auto_close", false)
