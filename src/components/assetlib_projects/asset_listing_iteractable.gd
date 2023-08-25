extends AssetListing
## Interactible AssetListing.
##
## Exists as a separate file, because, although it would run at first,
## Godot's resource loader on startup would think that there is a
## problematic dependency cycle.  This is due to the fact that both
## AssetListItem and AssetDialogue would be referencing each other.


const _ASSET_DIALOG_SCENE = preload("res://src/components/assetlib_projects/asset_dialog.tscn")

## Asset id within the asset library.
var _id: int
var _asset_dialog: ConfirmationDialog
var _projects: Control


func _ready():
	super._ready()
	
	_asset_dialog = _ASSET_DIALOG_SCENE.instantiate().init(
			_id, _title, _category, _author, _license, _projects
	)
	_asset_dialog.hide()
	add_child(_asset_dialog)


## Initializes the class. [param id] is the id of the asset within the
## asset library.  [param title], [param category], [param author],
## [param license] have the same meaning as in
## [method AssetListing.init_asset_listing].  [param projects] is the
## root node for the local projects tab.
func init_asset_listing_interactible(id: int, title: String,
		category: String, author: String, license: String,
		projects: Control):
	init_asset_listing(title, category, author, license)
	_id = id
	_projects = projects
	return self


func _open_popup():
	_asset_dialog.popup_centered()
