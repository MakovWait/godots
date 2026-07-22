class_name TemplateListItemControl
extends HBoxListItem

signal opened
signal removed
signal tag_clicked(tag: String)

@onready var _title_label: Label = %TitleLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _date_label: Label = %DateLabel
@onready var _tag_container: ItemTagContainer = %TagContainer
@onready var _icon: TextureRect = $Icon
@onready var _open_button: Button = %OpenButton
@onready var _actions_container: HBoxContainer = %ActionsContainer

var _template: ProjectTemplates.Item
var _tags := []
var _sort_data := {
	'ref': self
}


func _ready() -> void:
	super._ready()
	_tag_container.tag_clicked.connect(func(tag: String) -> void: tag_clicked.emit(tag))


func init(item: ProjectTemplates.Item) -> void:
	_template = item
	_fill_data(item)
	
	_open_button.pressed.connect(func() -> void: opened.emit())
	
	double_clicked.connect(func() -> void: opened.emit())


func _fill_data(item: ProjectTemplates.Item) -> void:
	_title_label.text = item.name
	_description_label.text = item.description if not item.description.is_empty() else tr("No description")
	_date_label.text = item.get_formatted_date()
	_icon.texture = get_theme_icon("FileList", "EditorIcons")
	_tag_container.set_tags(item.tags)
	_tags = item.tags
	
	if not item.is_zip_valid:
		modulate = Color(1, 1, 1, 0.498)
	
	_sort_data.name = item.name
	_sort_data.created_at = item.created_at
	_sort_data.tag_sort_string = "".join(item.tags)


func apply_filter(filter: Callable) -> bool:
	return filter.call({
		'name': _title_label.text,
		'path': '',
		'tags': _tags
	})


func get_sort_data() -> Dictionary:
	return _sort_data
