class_name LocalRemoteEditorsSwitchContext

signal changed

var _local: Control
var _remote: Control
var _tabs: TabContainer


func _init(local, remote, tabs):
	_local = local
	_remote = remote
	_tabs = tabs
	
	_tabs.tab_changed.connect(func(_idx):
		changed.emit()
	)


func go_to_local():
	_tabs.current_tab = _tabs.get_tab_idx_from_control(_local)


func go_to_remote():
	_tabs.current_tab = _tabs.get_tab_idx_from_control(_remote)


func local_is_selected() -> bool:
	return _tabs.current_tab == _tabs.get_tab_idx_from_control(_local)


func remote_is_selected() -> bool:
	return _tabs.current_tab == _tabs.get_tab_idx_from_control(_remote)
