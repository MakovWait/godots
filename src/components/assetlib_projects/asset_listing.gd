class_name AssetListing
extends HBoxContainer
## Class for the listing of an asset.
##
## This class does not handle interaction see asset_listing_interactible.gd
## instead.


var _title: String
var _category: String
var _author: String
var _license: String

@onready var _title_node: LinkButton = %Title
@onready var _category_node: Label = %Category
@onready var _author_node: Label = %Author
@onready var _license_node: Label = %License


func _ready():
	_title_node.text = _title
	_category_node.text = _category
	_author_node.text = _author
	_license_node.text = _license


## Initializes the class.  [param title] is the title of the asset,
## [param category] is the category name the asset belongs to,
## [param author] is the author of the asset, and [param license] is the
## license under which the asset has been released (called
## [code]cost[/code] within the asset library's API).
func init_asset_listing(title: String, category: String, author: String,
		license: String):
	_title = title
	_category = category
	_author = author
	_license = license
	return self
