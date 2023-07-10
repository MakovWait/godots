extends Node

var EDSCALE = 2
var AGENT = ""
const VERSION = "0.0 dev"
const EDITORS_CONFIG_PATH = "user://editors.cfg"
const PROJECTS_CONFIG_PATH = "user://projects.cfg"

var AGENT_HEADER:
	get: return "User-Agent: %s" % AGENT

func _ready():
	AGENT = "Godots/%s (%s) Godot/%s" % [
		VERSION, 
		OS.get_name(), 
		Engine.get_version_info().string
	]
