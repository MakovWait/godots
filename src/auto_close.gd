extends Node


func close_if_should():
	if Config.get_auto_close():
		get_tree().quit()
