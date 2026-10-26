extends Node

# Controllers
@onready var editor := %EditingController as RoomEditor
@onready var UI := %UI_Controller as UI_Controller
@onready var file_manager := %FileController as FileController

# consts
const LAYER_NAMES :Array[String] = [
	'Ground',
	'Walls',
	'Placeables',
]

enum Stages {
	Test,
	General,
	Lodge,
	Fog,
	# Dungeon
	Basement,
	Void,
	Plains,
	Tree,
	Heaven,
	Desert,
	Beach,
	Suzano,
	Vaporwave,
	Volcano
}

enum RoomTypes {
	Regular,
	Treasure,
	Secret,
	Boss,
	Challenge
}

# Input keys
const ACTION_TILE_PAINT = 'tile_paint'
const ACTION_TILE_ERASE = 'tile_remove'

#region Node Funcs

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	init_file_manager()
	init_geometry()
	init_UI()
	create_blank_room()

#region Input
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:

	if editor.is_painting:
		if Input.is_action_pressed(ACTION_TILE_PAINT) :
			editor.paint_tile()

		if Input.is_action_pressed(ACTION_TILE_ERASE):
			editor.remove_tile()


	if Input.is_action_just_released(ACTION_TILE_PAINT) or Input.is_action_just_released(ACTION_TILE_ERASE):
		editor.is_painting = false

func _unhandled_input(event: InputEvent) -> void:

	# start continuous painting if unhandled input
	if event.is_action_pressed(ACTION_TILE_PAINT):

		editor.paint_tile()
		editor.is_painting = true

	if event.is_action_pressed(ACTION_TILE_ERASE):
		
		editor.remove_tile()
		editor.is_painting = true




#region File Mangement


func init_file_manager():
	# create room folders for each group
	file_manager.create_room_folders(Stages.keys())

	file_manager.grab_saved_rooms_names()

	print(file_manager.saved_room_names_by_folder)

	print(file_manager.get_all_room_names())


#region Editing & Geometry
var floor_layers : Dictionary[String, HexagonTileMapLayer]

@onready var room_floor_parent = %RoomNodes

func grab_floor_layers():

	var layers: Dictionary[String, HexagonTileMapLayer] = {}
	for layer_name in LAYER_NAMES:
		layers[layer_name] = room_floor_parent.find_child(layer_name)

		if layers[layer_name] == null:
			push_error('Could not find layer_name {0} inside Node {1} '.format([layer_name, self]))

	floor_layers = layers

func init_geometry():
	grab_floor_layers()

	# init editor
	editor.LAYER_NAMES = LAYER_NAMES
	editor.room_layers = floor_layers
	editor.initialize()

#region User Interface 

@onready var BUTTS : Dictionary[String, Callable] = {

	# Editing Overlay
	'EditFiltersBtn' : open_filters_menu,

	# Filter Menu
	'ApplyFilterBtn' : apply_filters,

	'SelectAllFiltersBtn' : UI.press_all_filter_btns,

	'CancelFilterBtn' : UI.switch_tab.bind(UI_Controller.MenuTab.Editing),

	# Option Menu
	'SaveBtn' : save_room,

	'InfoEditBtn' : UI.switch_tab.bind(UI_Controller.MenuTab.RoomInfo),

	'SelectRoomBtn' : open_room_select_menu,

	'NewRoomBtn' : confirm_unsaved_progress.bind(
		UI_Controller.MenuTab.Options, 
		UI_Controller.MenuTab.Editing,
		create_blank_room),

	'DeriveBtn' : confirm_unsaved_progress.bind(
		UI_Controller.MenuTab.Options, 
		UI_Controller.MenuTab.Editing,
		create_variant),

	'ResumeBtn' : UI.switch_tab.bind(UI_Controller.MenuTab.Editing),

	# Room Select Menu
	'DeleteBtn' : confirm_deletion.bind(UI_Controller.MenuTab.RoomSelect, delete_room),

	'DupeBtn' : dupe_room,

	'LoadBtn' : load_room_from_select,
 
	'LeaveSelectingBtn' : UI.switch_tab.bind(UI_Controller.MenuTab.Editing),

	# Room Info Edit Menu
	'ApplyInfoBtn' : UI.switch_tab.bind(UI_Controller.MenuTab.Options),

	'CancelInfoBtn' : UI.switch_tab.bind(UI_Controller.MenuTab.Options)

}

func init_UI():
	#Pass constants to UI
	UI.bind_btns(BUTTS)
	UI.set_dropdown_items(Stages.keys(), UI.room_group)
	UI.set_dropdown_items(RoomTypes.keys(), UI.room_type)

	update_displayed_saved_rooms()
	connect_UI_signals()
	
func connect_UI_signals():
	UI.saved_rooms_list.item_selected.connect(selected_a_saved_room)


func confirm_unsaved_progress(from_tab:UI_Controller.MenuTab, to_tab:UI_Controller.MenuTab, confirm_func:Callable=Callable()):

	# call confirm func and switch tab if there is no progress to lose
	if not check_for_unsaved_progress():
		if confirm_func.is_valid():
			confirm_func.call()
		UI.switch_tab(to_tab)
		return

	# confirm losing progress before continuing
	var confirm_obj := UI_Controller.Confirmation.new(
		UI.switch_tab.bind(to_tab), 
		UI.switch_tab.bind(from_tab), 
		confirm_func)

	confirm_obj.msg = 'If you continue, you will lose unsaved progress. Are you sure?'
	UI.confirm_before_switch(confirm_obj)

func confirm_deletion(cur_tab:UI_Controller.MenuTab, confirm_func:Callable=Callable()):

	var confirm_obj := UI_Controller.Confirmation.new(
		UI.switch_tab.bind(cur_tab), 
		UI.switch_tab.bind(cur_tab), 
		confirm_func)

	confirm_obj.msg = 'Are you sure you want to delete this room?'
	UI.confirm_before_switch(confirm_obj)


func open_room_select_menu():
	update_displayed_saved_rooms()

	UI.set_visiblity_selected_room_panel(false)

	confirm_unsaved_progress(
		UI_Controller.MenuTab.Options,
		UI_Controller.MenuTab.RoomSelect)


#region Funcs

## updates saved rooms list UI
func update_displayed_saved_rooms():
	var saved_room_names := file_manager.get_all_room_names()	

	var saved_rooms_imgs

	var rooms_as_items = {}
	for _name in saved_room_names:

		rooms_as_items[_name] = load('uid://0462ner2ujw6')

	UI.set_item_list_items(rooms_as_items, UI.saved_rooms_list)

## called from the saved rooms itemlist selected signal
func selected_a_saved_room(_item_index:int):
	# get name from item list
	var selected_room_name = UI.get_selected_room_name()
	# update selected room display

	var room_data = file_manager.get_room_data_and_img(selected_room_name)

	var room_info_dict = JSON.parse_string(room_data['data'])['room_details']
	# TODO: get variants
	UI.set_selected_room_display(room_info_dict, room_data['img'], {})


func check_for_unsaved_progress():

	# if not blank, check if file exists
	# in case cur progress doesn't have a file in file sys, despite having cur file data in code
	var current_editing_name = UI.get_room_info()['name']
	if current_editing_name != '' and not file_manager.check_if_room_exists(current_editing_name):
		return true


	var cur_progress_data_str = file_manager.stringify_raw_room_data(
		UI.get_room_info(),
		editor.room_layers
	)

	return cur_progress_data_str != file_manager.cur_file_data_str

func save_room():
	var room_info = UI.get_room_info()
	
	file_manager.save_room_to_file(
		room_info,
		editor.room_layers,
	)

	print('saved!')
	UI.switch_tab(UI_Controller.MenuTab.Editing)

func load_room_from_select():
	var select_room_name = UI.get_selected_room_name()
	load_room(select_room_name)

func load_room(r_name:String):

	if not file_manager.load_room(r_name):
		push_error('failed to load room')
		return

	print('loaded a room')

	UI.set_room_info(file_manager.cur_room_info_data_as_dict())
	editor.set_layer_details(file_manager.cur_room_tile_data_as_dict())
	UI.switch_tab(UI_Controller.MenuTab.Editing)

func create_variant():
	print('now editing a new variant')

func create_blank_room():
	UI.clear_room_info()
	editor.clear_canvas()

	var blank_room_data = file_manager.stringify_raw_room_data(
		UI.get_room_info(),
		editor.room_layers
	)
	file_manager.set_blank_data(blank_room_data)
	print('now editing a blank room')
	

func delete_room():
	#get selected room
	var selected_room_name = UI.get_selected_room_name()

	file_manager.delete_room(selected_room_name)

	print('deleted room')
	update_displayed_saved_rooms()
	
func dupe_room():
	
	#TODO: edit room info name to have '_copy' appended
	var selected_room_name = UI.get_selected_room_name()
	'''
	load room json into var using its name
	convert to dict
	change name to name_copy
	save changes to file of name_copy
	'''

	file_manager.duplicate_room(selected_room_name)
	update_displayed_saved_rooms()

	print('duped the room')

func apply_filters():
	# update filter list var
	print("applied filters")
	UI.switch_tab(UI_Controller.MenuTab.Editing)

func open_filters_menu():
	# set buttons pressed in UI to be what the filter list var is
	UI.switch_tab(UI_Controller.MenuTab.Filtering)

# set UI room info to current room data
# func open_info_menu():
# 	var curret_room_info := file_manager.cur_room_info_data_as_dict()
# 	UI.set_room_info(curret_room_info)
# 	UI.switch_tab(UI_Controller.MenuTab.RoomInfo)

# func save_room_info():
# 	var prev_room_info := file_manager.cur_room_info_data_as_dict()
# 	file_manager.only_save_room_info_changes(UI.get_room_info())
# 	var cur_room_info := file_manager.cur_room_info_data_as_dict()

# 	print('saved room info changes from \n' + str(prev_room_info) + '\n to \n' + str(cur_room_info))
# 	UI.switch_tab(UI_Controller.MenuTab.Options)
