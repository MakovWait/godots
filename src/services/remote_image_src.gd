class_name RemoteImageSrc


class I:
	func async_load_img(url: String, callback: Callable) -> void:
		pass


class AlwaysBroken:
	extends I
	var _theme_src: Control

	func _init(theme_src: Control) -> void:
		_theme_src = theme_src

	func async_load_img(url: String, callback: Callable) -> void:
		var texture := _theme_src.get_theme_icon("FileBrokenBigThumb", "EditorIcons")
		callback.call(texture)


class LoadFileBuffer:
	extends I
	var _file_src: FileByUrlSrc
	var _fallback_texture: Texture2D

	func _init(file_src: FileByUrlSrc, fallback_texture: Texture2D) -> void:
		_fallback_texture = fallback_texture
		_file_src = file_src

	func async_load_img(url: String, callback: Callable) -> void:
		@warning_ignore("redundant_await")
		var file_path := await _file_src.async_load(url)

		if file_path.is_empty():
			return

		if not callback.is_valid():
			return

		# some weird additional check is required due to:
		# 'Trying to call a lambda with an invalid instance.'
		# https://github.com/godotengine/godot/blob/c7fb0645af400a1859154bcee9394e63bdabd198/modules/gdscript/gdscript_lambda_callable.cpp#L195
		if callback.get_object().get_script() == null:
			return

		var file := FileAccess.open(file_path, FileAccess.READ)
		if file == null:
			callback.call(_fallback_texture)
			return

		var file_buffer := file.get_buffer(file.get_length())
		var img := Image.new()
		var load_err := _load_img_from_buffer(img, file_buffer)
		if load_err:
			callback.call(_fallback_texture)
		else:
			var tex := ImageTexture.create_from_image(img)
			callback.call(tex)

	func _load_img_from_buffer(img: Image, buffer: PackedByteArray) -> int:
		var png_signature := PackedByteArray([137, 80, 78, 71, 13, 10, 26, 10])
		var jpg_signature := PackedByteArray([255, 216, 255])
		var webp_signature := PackedByteArray([82, 73, 70, 70])
		var bmp_signature := PackedByteArray([66, 77])

		var load_err := ERR_PARAMETER_RANGE_ERROR
		if png_signature == buffer.slice(0, 8):
			load_err = img.load_png_from_buffer(buffer)
		elif jpg_signature == buffer.slice(0, 3):
			load_err = img.load_jpg_from_buffer(buffer)
		elif webp_signature == buffer.slice(0, 4):
			load_err = img.load_webp_from_buffer(buffer)
		elif bmp_signature == buffer.slice(0, 2):
			load_err = img.load_bmp_from_buffer(buffer)
		# TODO load_svg_from_buffer in Godot 4.2
		return load_err


class FileByUrlSrc:
	func async_load(url: String) -> String:
		return ""


class FileByUrlSrcAsIs:
	extends FileByUrlSrc

	func async_load(url: String) -> String:
		var file_path := (Config.CACHE_DIR_PATH.ret() as String).path_join(url.md5_text())
		var response := HttpClient.Response.new(await HttpClient.async_http_get(url, [], file_path))
		if response.code != 200:
			return ""
		return file_path


class FileByUrlCachedEtag:
	extends FileByUrlSrc

	func async_load(url: String) -> String:
		var file_path_base := (Config.CACHE_DIR_PATH.ret() as String).path_join(
			"assetimage_" + url.md5_text()
		)
		var etag_path := file_path_base + ".etag"
		var data_path := file_path_base + ".data"
		var headers := []
		if FileAccess.file_exists(etag_path) and FileAccess.file_exists(data_path):
			var etag := FileAccess.open(etag_path, FileAccess.READ)
			if etag:
				headers.push_back("If-None-Match: " + etag.get_line())
		var response := HttpClient.Response.new(
			await HttpClient.async_http_get(url, headers, data_path)
		)
		if (
			response.result == HTTPRequest.RESULT_SUCCESS
			and response.result < HTTPClient.RESPONSE_BAD_REQUEST
		):
			if response.code != HTTPClient.RESPONSE_NOT_MODIFIED:
				for header in response.headers:
					header = header as String
					if header.findn("ETag:") == 0:
						var new_etag := (
							header.substr(header.find(":") + 1, header.length()).strip_edges()
						)
						var file := FileAccess.open(etag_path, FileAccess.WRITE)
						if file:
							file.store_line(new_etag)
						break
		return data_path
