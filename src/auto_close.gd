extends Node


func close_if_should() -> void:
	if Config.AUTO_CLOSE.ret():
		get_tree().quit()
