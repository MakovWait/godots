extends HBoxListItem

signal download_and_install_requested(url)
signal tag_clicked(tag)

@onready var _title_label = %TitleLabel
@onready var _tag_container = %TagContainer
@onready var _explore_button = %ExploreButton
@onready var _path_label = %PathLabel

var _tags = []
var _get_actions_callback: Callable


func init(item: GodotsReleases.Release):
	_tags = item.tags
	
	_title_label.text = item.name
	_tag_container.set_tags(_tags)
	_path_label.text = item.html_url
	
	_explore_button.pressed.connect(func(): OS.shell_open(item.html_url))
	
	_get_actions_callback = func():
		var install_btn = buttons.simple(
			tr("Download & Install"), 
			get_theme_icon("AssetLib", "EditorIcons"),
			func(): 
				for asset in item.assets:
					if asset.is_godots_bin_for_current_platform():
						download_and_install_requested.emit(
							asset.browser_download_url
						)
						return
				pass\
		)
		return [install_btn]


func _ready():
	super._ready()
	_tag_container.tag_clicked.connect(func(tag): tag_clicked.emit(tag))


func apply_filter(filter):
	return filter.call({
		'name': _title_label.text,
		'path': _path_label.text,
		'tags': _tags
	})


func get_actions():
	if _get_actions_callback:
		return _get_actions_callback.call()
	else:
		return []
