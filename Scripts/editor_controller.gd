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
	Challenge
}

# Input keys
const ACTION_TILE_PAINT = 'tile_paint'
const ACTION_TILE_ERASE = 'tile_remove'

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	init_geometry()
	init_UI()

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

	'InfoEditBtn' : open_info_menu,

	'SelectRoomBtn' : confirm_unsaved_progress.bind(
		UI_Controller.MenuTab.Options,
		UI_Controller.MenuTab.RoomSelect),

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

	'LoadBtn' : load_room,
 
	'LeaveSelectingBtn' : UI.switch_tab.bind(UI_Controller.MenuTab.Editing),

	# Room Info Edit Menu
	'ApplyInfoBtn' : apply_info,

	'CancelInfoBtn' : UI.switch_tab.bind(UI_Controller.MenuTab.Options)

}

func init_UI():
	UI.bind_btns(BUTTS)

func confirm_unsaved_progress(from_tab:UI_Controller.MenuTab, to_tab:UI_Controller.MenuTab, confirm_func:Callable=Callable()):

	if not check_for_unsaved_progress():
		UI.switch_tab(to_tab)
		return

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

#region Funcs

func check_for_unsaved_progress():

	var cur_progress_data_str = file_manager.get_data_as_string(
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

func load_room():
	#get selected room
	var r_group = 'test'
	var r_name = 'test'
	if not file_manager.load_room(r_group, r_name):
		print('failed to load room')
		return

	print('loaded a room')

	editor.set_layer_details(file_manager.cur_file_data_as_dict()['room_tile_data'])
	UI.switch_tab(UI_Controller.MenuTab.Editing)

func create_variant():
	print('now editing a new variant')
	

func create_blank_room():
	print('now editing a blank room')
	

func delete_room():
	#get selected room
	print('deleted room')
	


	
func dupe_room():
	#get selected room
	print('duped the room')
	UI.switch_tab(UI_Controller.MenuTab.Editing)

func apply_filters():
	# update filter list var
	print("applied filters")
	UI.switch_tab(UI_Controller.MenuTab.Editing)

func open_filters_menu():
	# set buttons pressed in UI to be what the filter list var is
	UI.switch_tab(UI_Controller.MenuTab.Filtering)



func open_info_menu():
	# set Ui to stored data
	UI.switch_tab(UI_Controller.MenuTab.RoomInfo)

func apply_info():
	#updates vars but doesn't save
	print('applied filters')
	UI.switch_tab(UI_Controller.MenuTab.Options)
