extends HBoxContainer
## Container for buttons used for navigating through different pages.


## Emitted whenever the user changes the page by pressing one of these
## buttons.
signal page_selected(page_num: int)

const _MAX_PAGE_BUTTONS = 10

## Curent page.  Setting this changes the button appearing as selected.
var current_page: int = 0:
	set(value):
		if value != current_page:
			current_page = value
			display_navigation()
## Number of pages in existence.  This is not the index of the last page.
var max_pages: int = 0

# Buttons
@onready var _page_buttons: HBoxContainer = $PageButtons
@onready var _first_button: Button = $FirstButton
@onready var _previous_button: Button = $PreviousButton
@onready var _next_button: Button = $NextButton
@onready var _last_button: Button = $LastButton


func _ready():
	# Populate PageButtons
	for i in _MAX_PAGE_BUTTONS:
		var button = Button.new()
		button.name = "PageButton" + str(i)
		_page_buttons.add_child(button)
		button.pressed.connect(func():
				_on_page_button_pressed(button)
		)
	_first_button.pressed.connect(func():
		current_page = 0
		page_selected.emit(current_page)
	)
	_previous_button.pressed.connect(func():
		current_page = max(0, current_page - 1)
		page_selected.emit(current_page)
	)
	_next_button.pressed.connect(func():
		if max_pages > 0:
			current_page = min(max_pages - 1, current_page + 1)
		else:
			current_page = 0
		page_selected.emit(current_page)
	)
	_last_button.pressed.connect(func():
		current_page = max_pages - 1 if max_pages > 0 else 0
		page_selected.emit(current_page)
	)


func _clear_navigation_buttons():
	for button in _page_buttons.get_children():
		button.hide()


## Sets up the navigation buttons, taking into account number of pages
## and current page number.
func display_navigation():
	_clear_navigation_buttons()
	if max_pages == 0:
		hide()
		return
	show()
	var buttons = _page_buttons.get_children()
	@warning_ignore("integer_division")
	var center_offset = _MAX_PAGE_BUTTONS / 2
	var start_page = max(0, current_page - center_offset)
	for i in _MAX_PAGE_BUTTONS:
		var page = start_page + i
		if page > max_pages - 1:
			break
		buttons[i].show()
		buttons[i].text = str(start_page + i + 1)
		buttons[i].disabled = start_page + i == current_page
	
	if current_page == 0:
		_first_button.disabled = true
		_previous_button.disabled = true
		_next_button.disabled = false # Assumes more than one page
		_last_button.disabled = false
	elif current_page == max_pages - 1:
		_first_button.disabled = false
		_previous_button.disabled = false
		_next_button.disabled = true
		_last_button.disabled = true
	else:
		_first_button.disabled = false
		_previous_button.disabled = false
		_next_button.disabled = false
		_last_button.disabled = false


func _on_page_button_pressed(button: Button):
	current_page = int(button.text) - 1
	page_selected.emit(current_page)
