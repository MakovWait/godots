class_name GodotsReleasesListItemControl
extends HBoxListItem

signal download_and_install_requested(url: String)
signal tag_clicked(tag: String)

@onready var _title_label := %TitleLabel as Label
@onready var _tag_container := %TagContainer as ItemTagContainer
@onready var _explore_button := %ExploreButton as Button
@onready var _path_label := %PathLabel as Label

var _tags := []
var _get_actions_callback: Callable


func init(item: GodotsReleases.Release) -> void:
	_tags = item.tags
	
	_title_label.text = item.name
	_tag_container.set_tags(_tags)
	_path_label.text = item.html_url
	
	_explore_button.pressed.connect(func() -> void: OS.shell_open(item.html_url))
	
	_get_actions_callback = func() -> Array:
		var install_btn := buttons.simple(
			tr("Download & Install"), 
			get_theme_icon("AssetLib", "EditorIcons"),
			func() -> void: 
				for asset in item.assets:
					if asset.is_godots_bin_for_current_platform():
						download_and_install_requested.emit(
							asset.browser_download_url
						)
						return
				pass\
		)
		return [install_btn]


func _ready() -> void:
	super._ready()
	_tag_container.tag_clicked.connect(func(tag: String) -> void: tag_clicked.emit(tag))


func apply_filter(filter: Callable) -> bool:
	return filter.call({
		'name': _title_label.text,
		'path': _path_label.text,
		'tags': _tags
	})


func get_actions() -> Array:
	if _get_actions_callback:
		return _get_actions_callback.call()
	else:
		return []
