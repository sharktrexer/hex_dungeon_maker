extends Node
class_name RoomEditor

# TODO: move into a shared class, man
#region STOLEN
const LAYER_NAMES :Array[String] = [
	'Ground',
	'Walls',
	'Placeables',
]
var floor_layers : Dictionary[String, HexagonTileMapLayer]

func grab_layer_names() -> Array[String]:
	return LAYER_NAMES as Array[String]

func grab_floor_layers() -> Dictionary[String, HexagonTileMapLayer]:

	var layers: Dictionary[String, HexagonTileMapLayer] = {}
	for layer_name in grab_layer_names():
		layers[layer_name] = find_child(layer_name)

		if layers[layer_name] == null:
			push_error('Could not find layer_name {0} inside Node {1} '.format([layer_name, self]))

	return layers

#endregion

#region Editing

# File Stuff
const SAVE_ROOM_PATH = 'res://RoomSaveData//'

# input stuff
const ACTION_TILE_PAINT = 'tile_paint'
const ACTION_TILE_ERASE = 'tile_remove'

# atlas stuff
const TILE_DATA_KEY_NAME = 'tile_name'

const WALL_IDENTIFIER_STRING = 'wall_'

const TILE_SOURCE_ID = 0

class AtlasTile:
	var atlas_coord: Vector2i = Vector2i.ZERO
	var layer: LayerName
	var id_alt := 0
	var id_source := 0

# UI 
@onready var tile_list:ItemList = $TileMenu/TileList

# prob should get from not this script
enum LayerName {
	Ground,
	Wall,
	Placeables
}


# editing data
var selected_tile: AtlasTile = AtlasTile.new()
var is_painting = false
var painting_layer: HexagonTileMapLayer

signal on_save(path:String)
signal on_clear
signal on_load(path:String)
signal failed_file_access(err_msg:String)

## contains info of every atlas tile and their associated layer
var available_tiles: Array[AtlasTile] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	tile_list.clear()

	floor_layers = grab_floor_layers()

	grab_tiles()

	# item list init
	tile_list.item_selected.connect(_new_tile_selected)
	tile_list.select(0)
	_new_tile_selected(0)

	_save_room()
	


func _unhandled_input(event: InputEvent) -> void:

	var mouse_to_map_pos := get_mouse_pos_as_map()

	# start continuous painting if unhandled input
	if event.is_action_pressed(ACTION_TILE_PAINT):

		paint_tile(selected_tile, mouse_to_map_pos)
		is_painting = true

	if event.is_action_pressed(ACTION_TILE_ERASE):
		
		remove_tile(mouse_to_map_pos)
		is_painting = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	var mouse_to_map_pos := get_mouse_pos_as_map()

	if is_painting:
		if Input.is_action_pressed(ACTION_TILE_PAINT) :
			paint_tile(selected_tile, mouse_to_map_pos)

		if Input.is_action_pressed(ACTION_TILE_ERASE):
			remove_tile(mouse_to_map_pos)


	if Input.is_action_just_released(ACTION_TILE_PAINT) or Input.is_action_just_released(ACTION_TILE_ERASE):
		is_painting = false

## using the atlas of each layer, get the tile info of every tile and then propogate in lists (ui and literal)
func grab_tiles():

	# what layer a tile is associated with (convert to layer name enum)
	var layer_ind = -1
	# in each layer
	for fl_lyr_key in floor_layers:
		layer_ind += 1
		# walls has same tileset as ground 
		if fl_lyr_key == 'Walls':
			continue

		var cur_layer := floor_layers[fl_lyr_key]
		# get atlas info for the layer
		var atlas_source: TileSetAtlasSource = cur_layer.tile_set.get_source(TILE_SOURCE_ID)
		var atlas_tile_count := atlas_source.get_tiles_count()
		var atlas_texture := atlas_source.texture
		# loop thru all valid atlas coords
		for tile_ind in range(0, atlas_tile_count):
			var atlas_coord := atlas_source.get_tile_id(tile_ind)
			
			# get text display for ui list
			var tile_data := atlas_source.get_tile_data(atlas_coord, TILE_SOURCE_ID)

			var tile_name := 'null'
			if tile_data.has_custom_data(TILE_DATA_KEY_NAME):
				tile_name = tile_data.get_custom_data(TILE_DATA_KEY_NAME)

			# crop atlas texture to just the tile
			var tile_region := atlas_source.get_tile_texture_region(atlas_coord)
			var tile_img := AtlasTexture.new()
			tile_img.atlas = atlas_texture
			tile_img.region = tile_region

			# UI 
			tile_list.add_item(tile_name, tile_img)

			# store tile data
			var tile_info = AtlasTile.new()
			tile_info.atlas_coord = atlas_coord
			tile_info.layer = layer_ind as LayerName

			# internal tile info
			available_tiles.append(tile_info)

## get map position from the layer being painted on
func get_mouse_pos_as_map() -> Vector2i:
	return painting_layer.local_to_map(painting_layer.get_local_mouse_position())

## when a new item in list ui is selected, update
func _new_tile_selected(index:int):
	selected_tile = available_tiles[index]
	painting_layer = floor_layers[LAYER_NAMES[selected_tile.layer]]

func get_room_info_ui():
	pass

func grab_room_info():

	# from ui, get dict of each var (name, desc, stage group name, variant of room name pointer)
	# the original variant points to itself.
	var info_from_ui = get_room_info_ui()

	# temp dummy vars until UI is set up
	var room_name := 'test1'
	var room_desc := 'omg test who is she'
	var stage_group := 'test'

	var room_info = {
		'name' : room_name,
		'desc' : room_desc,
		'group' : stage_group,
		'variant_of' : room_name
	}
	return room_info


## save the room on btn press
func _save_room():


	var room_info = grab_room_info()
	var room_file_path := convert_to_room_path(room_info['group'], room_info['name'])

	var save_data_string := RoomSaver.save_room_as_json(room_info, floor_layers)
	if save_data_string == '':
		return
 	
	access_room_data_from_file(room_file_path, FileAccess.WRITE, save_data_string)
	on_save.emit(room_file_path)
	print("Canvas SAVED to ", room_file_path)

	await get_tree().create_timer(2.0).timeout

	load_room(room_file_path)

func load_room(room_path):

	clear_canvas()
	print("cleared current canvas")

	await get_tree().create_timer(2.0).timeout

	var loaded_data = access_room_data_from_file(room_path, FileAccess.READ)
	if loaded_data == null:
		return

	copy_load_data_to_canvas( loaded_data )

	on_load.emit(room_path)
	print('LOADING complete from ', room_path)

func paint_tile(tile:AtlasTile, mouse_map_pos:Vector2i):

	painting_layer.set_cell(mouse_map_pos, tile.id_source, tile.atlas_coord, tile.id_alt)

func remove_tile(mouse_map_pos:Vector2i):

	painting_layer.erase_cell(mouse_map_pos)

func clear_canvas():
	for layer_name in floor_layers:
		floor_layers[layer_name].clear()
	on_clear.emit()

func access_room_data_from_file(file_path: String, mode:FileAccess.ModeFlags, room_data_string=''):
	var room_file = FileAccess.open(file_path, mode)

	if room_file == null:
		failed_file_access.emit(FileAccess.get_open_error())
		return null
	
	# file function
	var file_contents = ''
	if mode == FileAccess.READ:
		file_contents = room_file.get_as_text()
		return JSON.parse_string(file_contents)
	elif mode == FileAccess.WRITE:
		room_file.store_string(room_data_string)

	return null

func get_file_path_from_room_data(room_data_string:String) -> String:
	var parsed_data = JSON.parse_string(room_data_string)

	var folder_name = str(parsed_data['room_details']['group'])
	var file_name = str(parsed_data['room_details']['name'])

	return convert_to_room_path(folder_name, file_name)

func convert_to_room_path(room_folder:String, room_name:String, extension:='.json') -> String:
	return SAVE_ROOM_PATH + room_folder + '//' + room_name + extension


func copy_load_data_to_canvas(room_info_dict: Dictionary):
	set_room_info(room_info_dict['room_details'])
	set_layer_details(room_info_dict['room_tile_data'])

## updates this UI with the room's name, desc, from load
func set_room_info(info_dict: Dictionary):
	info_dict.get(1)
	# call Ui func to take info dict to populate ui with
	pass

## updates this layer display with the data from load
func set_layer_details(coords_dict: Dictionary):

	for coord in coords_dict:
		var pos_vect: Vector2i = str_to_var('Vector2i'+coord)

		var layer_info = coords_dict[coord]
		for layer_name in layer_info:
			if layer_info[layer_name] == null:
				continue

			var layer_to_copy_to = floor_layers[layer_name]
			layer_to_copy_to.set_cell(
				pos_vect,
				int(layer_info[layer_name]['source_id']),
				str_to_var('Vector2i' + layer_info[layer_name]['atlas_coord']) as Vector2i,
				int(layer_info[layer_name]['alt_id']),
			)
				
