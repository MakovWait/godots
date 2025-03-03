class_name GodotsDownloads


class I:
	func download(url: String, callback: Callable) -> void:
		pass


class Default extends I:
	var _downloads_container: DownloadsContainer
	var _asset_download_scene: PackedScene
	
	func _init(
		downloads_container: DownloadsContainer, 
		asset_download_scene: PackedScene
	) -> void:
		_downloads_container = downloads_container
		_asset_download_scene = asset_download_scene

	func download(url: String, callback: Callable) -> void:
		var asset_download := _asset_download_scene.instantiate() as AssetDownload
		_downloads_container.add_download_item(asset_download)
		asset_download.icon.texture = preload("res://icon.svg")
		asset_download.start(url, (Config.DOWNLOADS_PATH.ret() as String) + "/", "Godots.zip")
		asset_download.downloaded.connect(func(abs_zip_path: String) -> void:
			callback.call(abs_zip_path)
		)
