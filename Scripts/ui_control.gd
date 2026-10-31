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

const DEFAULT_ROOM_INFO := {
	'name' : '',
	'desc' : '',
	'group' : 'general',
	'type' : 'regular',
	'variant_of' : ''
} as Dictionary[String, String]

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



#region Editor UI
@onready var tile_list:ItemList = %TestTiles


#endregion



#region Room Select UI
@onready var saved_rooms_list := %AvailRoomsList as ItemList

# selected room section
@onready var selected_room_panel := %SelectedRoomPanel as Panel

@onready var room_name_label := %RoomNameLabel as Label
@onready var room_type_label := %RoomTypeLabel as Label
@onready var room_group_label := %RoomGroupLabel as Label
@onready var room_desc_label := %RoomDescLabel as RichTextLabel

@onready var room_preview := %RoomPreviewPic as TextureRect
@onready var variant_list := %VariantList as ItemList

# btns in this UI are handled by editor controller
#endregion



#region Room Info UI

@onready var room_title := %TitleEdit as LineEdit
@onready var room_desc := %DescEdit as TextEdit
@onready var room_group := %StageGroupDrop as OptionButton
@onready var room_type := %RoomTypeDrop as OptionButton



#region Confirm UI
## confirm data being used
var cur_confirm : Confirmation = null  

@onready var msg_display = %ConfirmMsg as RichTextLabel
@onready var confirm_btn = %ConfirmBtn as Button
@onready var abort_btn = %AbortBtn as Button

@onready var set_dupe_name_popup := %SetDupeNameMenu as ConfirmNewName

#endregion

#region Funcs

func toggle_control_visibility(ui_part:Control):
	ui_part.visible = not ui_part.visible

func set_visiblity_selected_room_panel(is_visible:bool):
	selected_room_panel.visible = is_visible

func set_dropdown_items(list:Array, dropdown:OptionButton):
	dropdown.clear()
	for elem in list:
		dropdown.add_item(elem)

func set_item_list_items(items:Dictionary, list:ItemList):
	# Dictionary[String, Texture2D]
	list.clear()
	for item_name in items.keys():
		list.add_item(item_name, items[item_name])

func set_dropdown_select_by_value(value:String, dropdown:OptionButton):
	value = value.capitalize()
	for i in dropdown.item_count:
		if dropdown.get_item_text(i) == value:
			dropdown.select(i)
			return

	push_error("Could not find " + value + " in dropdown " + dropdown.name)

func switch_tab(tab:MenuTab):
	UI_Parent.current_tab = tab

## gets the values of the room info UI
func get_room_info() -> Dictionary[String,String]:
	var stage_group := room_group.get_item_text(room_group.selected).to_lower()
	var room_t := room_type.get_item_text(room_type.selected).to_lower()

	var room_info : Dictionary[String, String] = {
		'name' : room_title.text,
		'desc' : room_desc.text,
		'group' : stage_group,
		'type' : room_t,
		'variant_of' : ''
	}
	return room_info

## sets the UI values of the room info
func set_room_info(room_info:Dictionary[String,String]):
	# Dictionary[String, String]
	room_title.text = room_info['name']
	room_desc.text = room_info['desc']
	set_dropdown_select_by_value(room_info['group'], room_group)
	set_dropdown_select_by_value(room_info['type'], room_type)
	# set variant info?!

func clear_room_info():
	set_room_info(DEFAULT_ROOM_INFO)

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

func get_selected_room_name() -> String:
	return saved_rooms_list.get_item_text(saved_rooms_list.get_selected_items()[0])

func set_selected_room_display(
	selected_room:Dictionary, 
	room_img:Texture2D, 
	variants:Dictionary[String, Texture2D]):

	# set labels
	room_name_label.text = selected_room['name']
	room_type_label.text = selected_room['type']
	room_group_label.text = selected_room['group']
	room_desc_label.text = selected_room['desc']

	# set img preview
	room_preview

	# set variant item list
	variant_list

	set_visiblity_selected_room_panel(true)

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
