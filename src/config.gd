extends Node

var EDSCALE = 2
var AGENT = ""
const VERSION = "0.0 dev"
const EDITORS_CONFIG_PATH = "user://editors.cfg"
const PROJECTS_CONFIG_PATH = "user://projects.cfg"

var AGENT_HEADER:
	get: return "User-Agent: %s" % AGENT

var DEFAULT_EDITOR_TAGS:
	get: return ["dev", "rc", "alpha", "4.x", "3.x", "stable", "mono"]

var DEFAULT_PROJECT_TAGS:
	get: return []

func _ready():
	AGENT = "Godots/%s (%s) Godot/%s" % [
		VERSION, 
		OS.get_name(), 
		Engine.get_version_info().string
	]
