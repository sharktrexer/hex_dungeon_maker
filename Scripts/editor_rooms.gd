extends Node
class_name RoomEditor

var LAYER_NAMES :Array[String] = []
var floor_layers : Dictionary[String, HexagonTileMapLayer]

#region Editing

# File Stuff
const SAVE_ROOM_PATH = 'res://RoomSaveData//'

# atlas stuff
const TILE_DATA_KEY_NAME = 'tile_name'

const WALL_IDENTIFIER_STRING = 'wall_'
const FLOOR_IDENTIFIER_STRING = 'floor_'

const TILE_SOURCE_ID = 0

class AtlasTile:
	var atlas_coord: Vector2i = Vector2i.ZERO
	var layer: int
	var id_alt := 0
	var id_source := 0

# UI 
@onready var tile_list:ItemList = %TileList2

# prob should get from not this script

# editing data
var selected_tile: AtlasTile = AtlasTile.new()
var is_painting = false
var painting_layer: HexagonTileMapLayer

signal on_save(path:String)
signal on_clear
signal on_load(path:String)
signal failed_file_access(err_msg:String)

## contains info of every atlas tile and their associated layer
var AVAIL_TILES: Array[AtlasTile] = []

## contains the room names and their file data as string
var ROOM_LIBRARY: Dictionary[String, String]

# Called when the node enters the scene tree for the first time.
func initialize() -> void:

	grab_saved_rooms()

	tile_list.clear()

	grab_tiles()

	# item list init
	tile_list.item_selected.connect(_new_tile_selected)
	tile_list.select(0)
	_new_tile_selected(0)

	_save_room()
	

## call after user tries to load or save, so launching doesnt have long load time?
func grab_saved_rooms():
	var files: PackedStringArray = []
	var folders = DirAccess.get_directories_at(SAVE_ROOM_PATH)
	for dir in folders:
		print(dir)
		for file in DirAccess.get_files_at(SAVE_ROOM_PATH + dir):
			files.append(dir + '//' + file)
	print(files)

## using the atlas of each layer, get the tile info of every tile and then propogate in lists (ui and literal)
func grab_tiles():

	# what layer a tile is associated with (convert to layer name enum)
	var layer_ind = -1
	# in each layer
	for fl_lyr_key in floor_layers:
		layer_ind += 1
		 
		# if fl_lyr_key == 'Walls':
		# 	continue

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

				# separate ground and floor tiles into separate layers
				# they share same atlas 
				if fl_lyr_key == 'Ground' and not FLOOR_IDENTIFIER_STRING in tile_name:
					continue

				if fl_lyr_key == 'Walls' and not WALL_IDENTIFIER_STRING in tile_name:
					continue

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
			tile_info.layer = layer_ind

			# internal tile info
			AVAIL_TILES.append(tile_info)

## get map position from the layer being painted on
func get_mouse_pos_as_map() -> Vector2i:
	return painting_layer.local_to_map(painting_layer.get_local_mouse_position())

## when a new item in list ui is selected, update
func _new_tile_selected(index:int):
	selected_tile = AVAIL_TILES[index]
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
 	
	var success_msg = access_room_data_from_file(room_file_path, FileAccess.WRITE, save_data_string)
	if success_msg == '':
		return

	on_save.emit(room_file_path)
	print("Canvas SAVED to ", room_file_path)

func load_room(room_path):

	clear_canvas()
	print("cleared current canvas")

	var loaded_data = access_room_data_from_file(room_path, FileAccess.READ)
	if loaded_data == '':
		return

	copy_load_data_to_canvas( loaded_data )

	on_load.emit(room_path)
	print('LOADING complete from ', room_path)

func paint_tile():

	painting_layer.set_cell(
		get_mouse_pos_as_map(), 
		selected_tile.id_source, 
		selected_tile.atlas_coord,
		selected_tile.id_alt)

func remove_tile():

	painting_layer.erase_cell(get_mouse_pos_as_map())

func clear_canvas():
	for layer_name in floor_layers:
		floor_layers[layer_name].clear()
	on_clear.emit()

func access_room_data_from_file(file_path: String, mode:FileAccess.ModeFlags, room_data_string='') -> String:

	if mode == FileAccess.WRITE and room_data_string == '':
		failed_file_access.emit("Attempted to save no data to ", file_path)
		return ''

	var room_file = FileAccess.open(file_path, mode)

	if room_file == null:
		failed_file_access.emit(FileAccess.get_open_error())
		return ''
	
	# file function
	var file_contents = ''

	if mode == FileAccess.READ:
		file_contents = room_file.get_as_text()
		return JSON.parse_string(file_contents)

	elif mode == FileAccess.WRITE:
		room_file.store_string(room_data_string)
		return 'DONE!'

	return ''

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
				
