extends Node
class_name UI_Controller

#region Tab Management

enum MenuTab {
	Confirmation,
	Editing,
	RoomSelect,
	Filtering,
	Options,
	RoomInfo,
}

# contains all menus to switch between
@onready var main_switcher := %UI_Switcher as TabContainer

var cur_confirm : Confirmation = null  

class Confirmation:
	var msg: String
	var switch_to_tab: Callable
	var switch_back_tab: Callable
	var on_confirm_func: Callable

	func _init(to: Callable, from: Callable, confirm_func:Callable=Callable()):
		switch_to_tab = to
		switch_back_tab = from

		on_confirm_func = confirm_func

#region Editing Overlay UI

'''---------------------Tile Select UI---------------------'''

## Main control node that the tile select UI is built on
@onready var tile_select_ui := %TileSelectUI as Panel

## used to toggle display
@onready var tile_tab_btn : Button = %TileTabBtn

@onready var tile_list_tabs : TabContainer = %TileListTabs as TabContainer

var tile_list_names := [
	'Geometry',
	'Enemy',
	'Object',
	'Doors',
]
var tile_tab_list := []

## add and manage icons relating to tile groups to include in the tile lists
@onready var included_tile_icons : HBoxContainer = %IncludedIcons as HBoxContainer
''' 
When all are included, just display one icon: all
General can't be unselected
'''


@onready var layer_dropdown_display := %SelectedLayerDropdown as OptionButton
'''
lets user change and display the current painting layer
'''

'''---------------------Tool Bar---------------------'''

## Main control node that the tool bar UI is built on
@onready var toolbar_ui := %ToolBarPanel as Panel

## add buttons that trigger switch to painting tools
@onready var tool_bttn_container : VBoxContainer= %ToolButtsPanel

## connect to hide tool bar ui
@onready var tab_bar_btn : Button = %ToolBarTabBtn

@onready var test_menu_btn := %TempMenuBtn as Button

#endregion

#region Options Menu

@onready var option_menu := %MenuBtns as PanelContainer

@onready var resume_btn = %ResumeBtn as Button


#region Room Select Menu

@onready var back_to_edit_btn = %LeaveSelectingBtn as Button

#region Confirm UI

@onready var msg_display = %ConfirmMsg as RichTextLabel
@onready var confirm_btn = %ConfirmBtn as Button
@onready var abort_btn = %AbortBtn as Button

#endregion

func toggle_control_visibility(ui_part:Control):
	ui_part.visible = not ui_part.visible

func switch_tab(tab:MenuTab):
	main_switcher.current_tab = tab

func press_all_filter_btns():
	print('pressed all filter btns')

func confirm_before_switch(agree:Confirmation):
	switch_tab(MenuTab.Confirmation)
	
	cur_confirm = agree

	confirm_btn.button_up.connect(agree.switch_to_tab)
	abort_btn.button_up.connect(agree.switch_back_tab)
	msg_display.text = agree.msg

	if agree.on_confirm_func.is_valid():
		confirm_btn.button_up.connect(agree.on_confirm_func)



func clean_confirm_btns():
	confirm_btn.button_up.disconnect(cur_confirm.switch_to_tab)
	abort_btn.button_up.disconnect(cur_confirm.switch_back_tab)
	confirm_btn.button_up.disconnect(cur_confirm.on_confirm_func)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	confirm_btn.button_up.connect(clean_confirm_btns)
	abort_btn.button_up.connect(clean_confirm_btns)

	# toggling overlay parts in editing HUD
	tile_tab_btn.button_up.connect(toggle_control_visibility.bind(tile_select_ui))
	tab_bar_btn.button_up.connect(toggle_control_visibility.bind(toolbar_ui))

	test_menu_btn.button_up.connect(switch_tab.bind(MenuTab.Options))

	# options menu
	resume_btn.button_up.connect(switch_tab.bind(MenuTab.Editing))
	

	#load_btn.button_up.connect(switch_tab.bind(MenuTab.RoomSelect))

'''
-----------Main Editing UI-----------

-fill each tab with appropriate tiles
- fill toolbar with tool btns

-close/open left UI
-ditto for right UI
-change to tool btn
-change layer btn??
-open filters menu
-open option menu trigger

-----------Room Select Menu-----------

-populate avial rooms list
-change tab trigger (all, ice, fire etc) base on stage group

-create new room trigger (create blank, unsaved room)
-select room trigger (from avail list or variant list)
populates sidebar with info of room

-dupe selected room trigger (does not dupe variants)
	opens editor with transferred room data, then auto calls "save from blank" func
-load selected room trigger
-delete selected room trigger (trigger are you sure pop up) 
deletes file and any variants of it

-----------Filter Menu-----------

-populate filter option grid
-apply btn (take all pressed filters and add to filter list)
-select all btn trigger
-cancel trigger (don't save filter choices)

-----------Options Menu-----------

-save btn trigger
save from blank: 
	choose name if haven't already
		ensure name is unique from any other room
		stage group defaults to "general" if not
	trigger new save 
		create new file

save from established room data:
	trigger save on current file
		if has variants, update variants with any updated info

	? If user wants to overwrite a save ?


create variant (must be established room with data)
	act like "choose existing room to be variant of" func

edit info:
	open edit info menu	

resume:
	go back to editing

new room:
	create blank room

load:
	open Room Select Menu

Additionally, if there are unsaved changes, ask for confirmation before pursuing affects from:
	load
	new room
	create variant

-----------Edit Info menu-----------
- desc text box
locked if variant, must be same as parent:
- stage group dropdown 
-tags?
-room type (secret, regular, treasure, challenge)

-cancel btn disregard changes
-ok btn, will keep info to be saved when save trigged


-----------Confrimation Menu-----------

-msg
-accept button
-cancel btn

'''
