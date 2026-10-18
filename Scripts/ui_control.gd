extends Node
class_name UI_Controller

enum MenuTab {
	Confirmation,
	Editing,
	RoomSelect,
	Filtering,
	Options,
	RoomInfo,
}

class Confirmation:
	var msg: String
	var switch_to_tab: Callable
	var switch_back_tab: Callable
	var on_confirm_func: Callable

	func _init(to: Callable, from: Callable, confirm_func:Callable=Callable()):
		switch_to_tab = to
		switch_back_tab = from

		on_confirm_func = confirm_func

## contains all menus to switch between
@onready var UI_Parent := %UI_Switcher as TabContainer

@onready var tile_select_ui := %TileSelectUI as Panel
@onready var toolbar_ui := %ToolBarPanel as Panel

#region Temp

## temp to toggle tile HUD
@onready var tile_tab_btn : Button = %TileTabBtn

## temp to toggle tool bar
@onready var tab_bar_btn : Button = %ToolBarTabBtn

# temp to go back to editing ui state
@onready var test_menu_btn := %TempMenuBtn as Button

#region Room Info UI

@onready var room_desc := %DescEdit as TextEdit
@onready var room_group := %StageGroupDrop as OptionButton
@onready var room_type := %RoomTypeDrop as OptionButton

#region Confirm UI
## confirm data being used
var cur_confirm : Confirmation = null  

@onready var msg_display = %ConfirmMsg as RichTextLabel
@onready var confirm_btn = %ConfirmBtn as Button
@onready var abort_btn = %AbortBtn as Button

#endregion

func toggle_control_visibility(ui_part:Control):
	ui_part.visible = not ui_part.visible

func switch_tab(tab:MenuTab):
	UI_Parent.current_tab = tab

func get_room_info() -> Dictionary[String,String]:
	var room_name := 'test'
	var stage_group := room_group.get_item_text(room_group.selected).to_lower()
	var room_t := room_type.get_item_text(room_type.selected).to_lower()

	var room_info : Dictionary[String, String] = {
		'name' : room_name,
		'desc' : room_desc.text,
		'group' : stage_group,
		'type' : room_t,
		'variant_of' : ''
	}
	return room_info

func press_all_filter_btns():
	# loop thru filte bttns and press them lmao
	print('pressed all filter btns')

func confirm_before_switch(agree:Confirmation):
	switch_tab(MenuTab.Confirmation)
	
	cur_confirm = agree

	confirm_btn.button_up.connect(agree.switch_to_tab)
	abort_btn.button_up.connect(agree.switch_back_tab)
	msg_display.text = agree.msg

	if agree.on_confirm_func.is_valid():
		confirm_btn.button_up.connect(agree.on_confirm_func)


## disconnect signals from confirm btns so they don't cause bad logic
func clean_confirm_btns():
	confirm_btn.button_up.disconnect(cur_confirm.switch_to_tab)
	abort_btn.button_up.disconnect(cur_confirm.switch_back_tab)
	if cur_confirm.on_confirm_func.is_valid():
		confirm_btn.button_up.disconnect(cur_confirm.on_confirm_func)

func bind_btns(btn_func_dict:Dictionary[String, Callable]):
	for btn_name in btn_func_dict:
		var butt = UI_Parent.find_child(btn_name) as Button
		butt.button_up.connect(btn_func_dict[btn_name])

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# confirmation 
	confirm_btn.button_up.connect(clean_confirm_btns)
	abort_btn.button_up.connect(clean_confirm_btns)
	
	# TEMP

	# toggling overlay parts in editing HUD
	tile_tab_btn.button_up.connect(toggle_control_visibility.bind(tile_select_ui))
	tab_bar_btn.button_up.connect(toggle_control_visibility.bind(toolbar_ui))

	test_menu_btn.button_up.connect(switch_tab.bind(MenuTab.Options))
	# END TEMP


#region Draft
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
