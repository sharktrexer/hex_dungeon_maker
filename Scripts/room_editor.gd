extends Node
class_name RoomEditor

var LAYER_NAMES :Array[String] = []
var room_layers : Dictionary[String, HexagonTileMapLayer]

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
@onready var tile_list:ItemList = %TestTiles

# editing data
var selected_tile: AtlasTile = AtlasTile.new()
var is_painting = false
var painting_layer: HexagonTileMapLayer


## contains info of every atlas tile and their associated layer
var AVAIL_TILES: Array[AtlasTile] = []

## contains the room names and their file data as string
var ROOM_LIBRARY: Dictionary[String, String]

# Called when the node enters the scene tree for the first time.
func initialize() -> void:

	tile_list.clear()

	grab_tiles()

	# item list init
	tile_list.item_selected.connect(_new_tile_selected)
	tile_list.select(0)
	_new_tile_selected(0)

	

## using the atlas of each layer, get the tile info of every tile and then propogate in lists (ui and literal)
func grab_tiles():

	# what layer a tile is associated with (convert to layer name enum)
	var layer_ind = -1
	# in each layer
	for r_lyr_key in room_layers:
		layer_ind += 1
		 
		# if fl_lyr_key == 'Walls':
		# 	continue

		var cur_layer := room_layers[r_lyr_key]
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
				if r_lyr_key == 'Ground' and not FLOOR_IDENTIFIER_STRING in tile_name:
					continue

				if r_lyr_key == 'Walls' and not WALL_IDENTIFIER_STRING in tile_name:
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
	painting_layer = room_layers[LAYER_NAMES[selected_tile.layer]]

func paint_tile():

	painting_layer.set_cell(
		get_mouse_pos_as_map(), 
		selected_tile.id_source, 
		selected_tile.atlas_coord,
		selected_tile.id_alt)

func remove_tile():

	painting_layer.erase_cell(get_mouse_pos_as_map())

func clear_canvas():
	for layer_name in room_layers:
		room_layers[layer_name].clear()
	

## updates this layer display with the data from load
func set_layer_details(coords_dict: Dictionary):

	clear_canvas()

	for coord in coords_dict:
		var pos_vect: Vector2i = str_to_var('Vector2i'+coord)

		var layer_info = coords_dict[coord]
		for layer_name in layer_info:
			if layer_info[layer_name] == null:
				continue

			var layer_to_copy_to = room_layers[layer_name]
			layer_to_copy_to.set_cell(
				pos_vect,
				int(layer_info[layer_name]['source_id']),
				str_to_var('Vector2i' + layer_info[layer_name]['atlas_coord']) as Vector2i,
				int(layer_info[layer_name]['alt_id']),
			)
				
