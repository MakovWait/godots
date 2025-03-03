class_name CustomMinimumSize
extends Node


@export var custom_minimum_size: Vector2:
	set(value):
		custom_minimum_size = value
		if not Engine.is_editor_hint():
			_apply()


func _ready() -> void:
	_apply()


func _apply() -> void:
	var target := get_parent() as Control
	if target == null:
		return
	target.custom_minimum_size = custom_minimum_size * Config.EDSCALE
