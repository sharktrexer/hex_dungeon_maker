extends Node
class_name RoomEditor

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

# input stuff
const ACTION_TILE_PAINT = 'tile_paint'
const ACTION_TILE_ERASE = 'tile_remove'

# atlas stuff
const TILE_DATA_KEY_NAME = 'tile_name'

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
	for key in floor_layers:
		layer_ind += 1
		# walls has same tileset as ground 
		if key == 'Walls':
			continue

		var cur_layer := floor_layers[key]
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

func paint_tile(tile:AtlasTile, mouse_map_pos:Vector2i):

	painting_layer.set_cell(mouse_map_pos, tile.id_source, selected_tile.atlas_coord, tile.id_alt)

func remove_tile(mouse_map_pos:Vector2i):

	painting_layer.erase_cell(mouse_map_pos)
