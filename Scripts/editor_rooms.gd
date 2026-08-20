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

	return layers

#endregion

#region Editing

const ACTION_TILE_PAINT = 'tile_paint'
const ACTION_TILE_ERASE = 'tile_remove'

enum LayerName {
	Ground,
	Wall,
	Placeables
}

class SelectedTile:
	var atlas_coord: Vector2i = Vector2i.ZERO
	var layer: HexagonTileMapLayer

var selected_tile: SelectedTile = SelectedTile.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	floor_layers = grab_floor_layers()

	selected_tile.layer = floor_layers[LAYER_NAMES[LayerName.Ground]]


func _input(event: InputEvent) -> void:

	var mouse_to_map_pos := selected_tile.layer.local_to_map(selected_tile.layer.get_local_mouse_position())

	if event.is_action_released(ACTION_TILE_PAINT):

		paint_tile(selected_tile.layer, mouse_to_map_pos)

	if event.is_action_released(ACTION_TILE_ERASE):
		
		remove_tile(selected_tile.layer, mouse_to_map_pos)


func paint_tile(layer:HexagonTileMapLayer, mouse_map_pos:Vector2i):

	layer.set_cell(mouse_map_pos, 0, selected_tile.atlas_coord, 0)


func remove_tile(layer:HexagonTileMapLayer, mouse_map_pos:Vector2i):

	layer.erase_cell(mouse_map_pos)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var mouse_to_map_pos := selected_tile.layer.local_to_map(selected_tile.layer.get_local_mouse_position())
	
	if Input.is_action_pressed(ACTION_TILE_PAINT):
		paint_tile(selected_tile.layer, mouse_to_map_pos)

	if Input.is_action_pressed(ACTION_TILE_ERASE):
		remove_tile(selected_tile.layer, mouse_to_map_pos)
