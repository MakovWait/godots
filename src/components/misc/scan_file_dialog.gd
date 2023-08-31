extends FileDialog

signal dir_to_scan_selected(dir: String)

var _use_parent_dir = false


func _init():
	title = tr("Select a Folder to Scan")
	dir_selected.connect(func(dir: String):
		var dir_to_scan
		if _use_parent_dir:
			dir_to_scan = dir.get_base_dir()
		else:
			dir_to_scan = dir
		dir_to_scan_selected.emit(dir_to_scan)
		_use_parent_dir = false
	)
	var select_current_dir_to_scan = add_button(
		tr("Select Parent Folder")
	) as Button
	select_current_dir_to_scan.tooltip_text = tr(
		"Will select the folder from 'Path:' on the top."
	)
	select_current_dir_to_scan.pressed.connect(func():
		_use_parent_dir = true
		get_ok_button().pressed.emit()
		hide()
	)


func _ready():
	file_mode = FileDialog.FILE_MODE_OPEN_DIR
	access = FileDialog.ACCESS_FILESYSTEM
