class_name PaginationContainer
extends HBoxContainer


signal page_changed(page: int)

var _current_pages: Control


func render(page: int, page_count: int, page_len: int, total_items: int) -> void:
	clear()
	_current_pages = _make_pages(page, page_count, page_len, total_items)
	add_child(_current_pages)


func clear() -> void:
	if is_instance_valid(_current_pages):
		_current_pages.hide()
		_current_pages.queue_free()


func _make_pages(page: int, page_count: int, page_len: int, total_items: int) -> HBoxContainer:
	var hbc := HBoxContainer.new()
	hbc.alignment = HBoxContainer.ALIGNMENT_CENTER

	if page_count < 2:
		return hbc

	var from := page - (5 / Config.EDSCALE)
	if from < 0:
		from = 0
	var to := from + (10 / Config.EDSCALE)
	if to > page_count:
		to = page_count

	hbc.add_spacer(false)
	hbc.add_theme_constant_override("separation", int(5 * Config.EDSCALE))

	var trigger_search := func(btn: Button, p: int) -> void:
		btn.pressed.connect(func() -> void:
			page_changed.emit(p)
		)

	var first := Button.new()
	first.text = tr("First", "Pagination")
	if page != 0:
		trigger_search.call(first, 0)
	else:
		first.set_disabled(true)
		first.set_focus_mode(Control.FOCUS_NONE)
	hbc.add_child(first)

	var prev := Button.new()
	prev.text = tr("Previous", "Pagination")
	if page > 0:
		trigger_search.call(prev, page - 1)
	else:
		prev.set_disabled(true)
		prev.set_focus_mode(Control.FOCUS_NONE)
	hbc.add_child(prev)
	hbc.add_child(VSeparator.new())

	for i in range(from, to):
		if i == page:
			var current := Button.new()
			# Keep the extended padding for the currently active page (see below).
			current.set_text(" %d " % (i + 1))
			current.set_disabled(true)
			current.set_focus_mode(Control.FOCUS_NONE)

			hbc.add_child(current)
		else:
			var current := Button.new()
			# Add padding to make page number buttons easier to click.
			current.set_text(" %d " % (i + 1))
			trigger_search.call(current, i)

			hbc.add_child(current)

	var next := Button.new()
	next.set_text(tr("Next", "Pagination"))
	if page < page_count - 1:
		trigger_search.call(next, page + 1)
	else:
		next.set_disabled(true)
		next.set_focus_mode(Control.FOCUS_NONE)
	hbc.add_child(VSeparator.new())
	hbc.add_child(next)

	var last := Button.new()
	last.set_text(tr("Last", "Pagination"))
	if page != page_count - 1:
		trigger_search.call(last, page_count - 1)
	else:
		last.set_disabled(true)
		last.set_focus_mode(Control.FOCUS_NONE)
	hbc.add_child(last)

	hbc.add_spacer(false)

	return hbc
