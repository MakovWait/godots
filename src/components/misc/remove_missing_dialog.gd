class_name RemoveMissingDialog
extends ConfirmationDialog


func _init(callback):
	confirmed.connect(callback)
	dialog_text = tr("Remove all missing items from the list?\nThe item folders' contents won't be modified.")
	get_ok_button().text = tr("Remove All")
