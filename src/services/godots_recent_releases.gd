class_name GodotsRecentReleases


class I:
	func async_has_updates() -> bool:
		return utils.not_implemeted()


class Default extends I:
	var _releases: GodotsReleases.I
	
	func _init(releases: GodotsReleases.I) -> void:
		_releases = releases

	func async_has_updates() -> bool:
		var has_updates := await _releases.async_has_newest_version()
		return has_updates


class Cached extends I:
	const HOUR = 60 * 60
	const UPDATES_CACHE_LIFETIME_SEC = 8 * HOUR

	var _origin: I
	
	func _init(origin: I) -> void:
		_origin = origin
	
	func async_has_updates() -> bool:
		await _actualize_cache()
		return Cache.get_value("has_update", "value", false)
	
	func _actualize_cache() -> void:
		var last_checked_unix:int = Cache.get_value("has_update", "last_checked", 0)
		if int(Time.get_unix_time_from_system()) - last_checked_unix > UPDATES_CACHE_LIFETIME_SEC:
			await _update_cache()
		elif Cache.get_value("has_update", "current_version", Config.VERSION) != Config.VERSION:
			await _update_cache() 
	
	func _update_cache() -> bool:
		var has_updates := await _origin.async_has_updates()
		Cache.set_value("has_update", "value", has_updates)
		Cache.set_value("has_update", "current_version", Config.VERSION)
		Cache.set_value("has_update", "last_checked", int(Time.get_unix_time_from_system()))
		Cache.save()
		return has_updates


class MockHasUpdates extends I:
	func async_has_updates() -> bool:
		return true
