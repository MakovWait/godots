extends Node

var EDSCALE = 2
var AGENT = ""
const VERSION = "0.0 dev"
const APP_CONFIG_PATH = "user://godots.cfg"
const EDITORS_CONFIG_PATH = "user://editors.cfg"
const PROJECTS_CONFIG_PATH = "user://projects.cfg"
const VERSIONS_PATH = "user://versions"
const DOWNLOADS_PATH = "user://downloads"

var AGENT_HEADER:
	get: return "User-Agent: %s" % AGENT

var DEFAULT_EDITOR_TAGS:
	get: return get_default_editor_tags(["dev", "rc", "alpha", "4.x", "3.x", "stable", "mono"])

var DEFAULT_PROJECT_TAGS:
	get: return []

var _cfg = ConfigFile.new()


func _ready():
	_cfg.load(APP_CONFIG_PATH)
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
