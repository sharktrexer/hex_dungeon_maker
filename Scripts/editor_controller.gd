extends Node

#region Controllers
@onready var editor = %EditingController as RoomEditor
@onready var UI = %UI_Controller as UI_Controller
@onready var data_manager = null

#region Input
const ACTION_TILE_PAINT = 'tile_paint'
const ACTION_TILE_ERASE = 'tile_remove'

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	init_geometry()
	init_UI()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

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
const LAYER_NAMES :Array[String] = [
	'Ground',
	'Walls',
	'Placeables',
]
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
	editor.floor_layers = floor_layers
	editor.initialize()

func create_variant():
	print('now editing a new variant')
	

func create_blank_room():
	print('now editing a blank room')
	

func delete_room():
	#get selected room
	print('deleted room')
	

func load_room():
	#get selected room
	print('loaded a room')
	UI.switch_tab(UI_Controller.MenuTab.Editing)
	
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

func save_room():
	editor._save_room()
	print('saved!')
	UI.switch_tab(UI_Controller.MenuTab.Editing)

func open_info_menu():
	# set Ui to stored data
	UI.switch_tab(UI_Controller.MenuTab.RoomInfo)

func apply_info():
	#updates vars but doesn't save
	print('applied filters')
	UI.switch_tab(UI_Controller.MenuTab.Options)

#region User Interface Logic

@onready var BUTTS : Dictionary[String, Callable] = {

	# Editing Overlay
	'EditFiltersBtn' : open_filters_menu,

	# Filter Menu
	'ApplyFilterBtn' : apply_filters,

	'SelectAllFiltersBtn' : UI.press_all_filter_btns,

	'CancelFilterBtn' : UI.switch_tab.bind(UI_Controller.MenuTab.Editing),

	# Option Menu
	'SaveBtn' : save_room,

	'SelectRoomBtn' : check_for_unsaved_progress.bind(
		UI_Controller.MenuTab.Options,
		UI_Controller.MenuTab.RoomSelect),

	'NewRoomBtn' : check_for_unsaved_progress.bind(
		UI_Controller.MenuTab.Options, 
		UI_Controller.MenuTab.Editing,
		create_blank_room),

	'DeriveBtn' : check_for_unsaved_progress.bind(
		UI_Controller.MenuTab.Options, 
		UI_Controller.MenuTab.Editing,
		create_variant),

	'InfoEditBtn' : open_info_menu,

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
	bind_btns()

func bind_btns():
	for btn_name in BUTTS:
		var butt = UI.main_switcher.find_child(btn_name) as Button
		butt.button_up.connect(BUTTS[btn_name])


func check_for_unsaved_progress(from_tab:UI_Controller.MenuTab, to_tab:UI_Controller.MenuTab, confirm_func:Callable=Callable()):

	if not editor.is_there_unsaved_progress():
		UI.switch_tab(to_tab)
		return

	var confirm_obj := UI_Controller.Confirmation.new(UI.switch_tab.bind(to_tab), UI.switch_tab.bind(from_tab), confirm_func)
	confirm_obj.msg = 'If you continue, you will lose unsaved progress. Are you sure?'
	UI.confirm_before_switch(confirm_obj)

func confirm_deletion(cur_tab:UI_Controller.MenuTab, confirm_func:Callable=Callable()):

	var confirm_obj := UI_Controller.Confirmation.new(UI.switch_tab.bind(cur_tab), UI.switch_tab.bind(cur_tab), confirm_func)
	confirm_obj.msg = 'Are you sure you want to delete this room?'
	UI.confirm_before_switch(confirm_obj)
