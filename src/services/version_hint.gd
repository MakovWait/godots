class_name VersionHint


static func are_equal(a: String, b: String, ignore_mono:=false) -> bool:
	if a == b:
		return true
	return parse(a).eq(parse(b), ignore_mono)


static func version_or_nothing(hint: String) -> String:
	var parsed := parse(hint)
	if parsed.is_valid:
		return parsed.version
	else:
		return hint


static func similarity(a: String, b: String) -> int:
	if a == b:
		return 100
	
	var parsed_a := parse(a)
	var parsed_b := parse(b)
	var score := 0
	
	if not parsed_a.is_valid or not parsed_b.is_valid:
		return 0
	
	if parsed_a.major_version == parsed_b.major_version:
		score += 6
	if parsed_a.minor_version == parsed_b.minor_version:
		score += 6
	if parsed_a.version == parsed_b.version:
		score += 6
	if parsed_a.is_mono == parsed_b.is_mono:
		score += 2
	if parsed_a.stage == parsed_b.stage:
		score += 2
	elif parsed_a.stage.begins_with(parsed_b.stage):
		score += 1
	elif parsed_b.stage.begins_with(parsed_a.stage):
		score += 1
	return score


static func same_version(a: String, b: String) -> bool:
	return parse(a).version == parse(b).version


static func parse(version_hint: String) -> Item:
	var tags: Array
	version_hint = version_hint.to_lower().strip_edges()
	if " " in version_hint:
		tags = version_hint.split(" ")
	else:
		tags = version_hint.split("-")
	var item := Item.new()
	var parsers := [
		_ParsedVersion.new(),
		_ParsedIsMono.new(),
		_ParsedStage.new(PackedStringArray([
			"stable",
			"dev",
			"rc",
			"alpha",
			"beta",
			"pre-alpha"
		]))
	]
	for parser: Object in parsers:
		parser.call("fill", item, tags)
	return item


static func _as_version(tag: String) -> String:
	if tag.begins_with("v") and tag.substr(1, 3).is_valid_float():
		return tag.substr(1)
	elif tag.substr(0, 3).is_valid_float():
		return tag
	else:
		return ""


static func _is_version(tag: String) -> bool:
	return _as_version(tag) != ""


class Item:
	var version := ""
	var major_version := ""
	var minor_version := ""
	var stage := 'stable'
	var is_mono := false
	var is_valid := false
	
	func eq(other: Item, ignore_mono:=false) -> bool:
		if not self.is_valid:
			return false
		if not other.is_valid:
			return false
		var result := self.version == other.version and self.stage == other.stage
		if not ignore_mono:
			return result and self.is_mono == other.is_mono
		else:
			return result
	
	func _to_string() -> String:
		if not is_valid:
			return 'unknown version'
		else:
			var base := '%s-%s' % [version, stage]
			if is_mono:
				base += '-%s' % 'mono'
			return base


class _ParsedVersion:
	func fill(item: Item, tags: PackedStringArray) -> void:
		for tag in tags:
			var version := VersionHint._as_version(tag)
			if version != null:
				item.version = version
				item.major_version = version.substr(0, 1)
				item.minor_version = version.substr(0, 3)
				item.is_valid = true
				return
		item.is_valid = false


class _ParsedStage:
	var _known_stages: PackedStringArray

	func _init(known_stages: PackedStringArray) -> void:
		_known_stages = known_stages

	func fill(item: Item, tags: PackedStringArray) -> void:
		for tag in tags:
			if VersionHint._is_version(tag):
				continue
			if tag == 'mono':
				continue
			for stage in _known_stages:
				if tag.begins_with(stage):
					item.stage = tag


class _ParsedIsMono:
	func fill(item: Item, tags: PackedStringArray) -> void:
		for tag in tags:
			if tag == 'mono':
				item.is_mono = true
				return
		item.is_mono = false
