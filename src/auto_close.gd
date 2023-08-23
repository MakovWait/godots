extends Node


func close_if_should():
	if Config.AUTO_CLOSE.ret():
		get_tree().quit()
