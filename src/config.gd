extends Node

var EDSCALE = 2
var AGENT = ""
const VERSION = "0.0 dev"
const EDITORS_CONFIG_PATH = "user://editors.cfg"
const PROJECTS_CONFIG_PATH = "user://projects.cfg"
const VERSIONS_PATH = "user://versions"
const DOWNLOADS_PATH = "user://downloads"

var AGENT_HEADER:
	get: return "User-Agent: %s" % AGENT

var DEFAULT_EDITOR_TAGS:
	get: return ["dev", "rc", "alpha", "4.x", "3.x", "stable", "mono"]

var DEFAULT_PROJECT_TAGS:
	get: return []


func _ready():
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
