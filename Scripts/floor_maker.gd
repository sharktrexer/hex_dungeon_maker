extends Node
class_name FloorMaker


@onready var room_scenes := [preload('uid://cnwv0lqiq42hv'), preload('uid://tlgb586s82vb')]

var floor_layers : Dictionary[String, HexagonTileMapLayer]
var rooms: Array[Room]

const LAYER_NAMES :Array[String] = [
	'Ground',
	'Walls',
	'Placeables',
]

const PLACEABLES_TILES: Dictionary[String, Vector2i] = {
	'DOORWAY' : Vector2i(0, 1),
	'ENTRANCE' : Vector2i(1, 1),
	'EXIT' : Vector2i(2, 1),
	'SECRET_DOOR' : Vector2i(3, 1),
	'TREASURE_DOOR' : Vector2i(4, 1),
}

class Room:
	var root_node : Node
	var name: String
	var desc: String
	var layers: Dictionary[String, LayerInfo]

class LayerInfo:
	var name: String 
	var hex_layer: HexagonTileMapLayer
	var cells: Array[Cell] 

class Cell:
	var vector: Vector2i
	var atlas_coord: Vector2i
	var id_source: int
	var id_alt: int


# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	floor_layers = grab_floor_layers()
	rooms = init_rooms( grab_rooms_scenes() )

	place_rooms(rooms)


func find_hex_layer_child_in_node(root:Node, l_name:String) -> HexagonTileMapLayer:
	var layer:HexagonTileMapLayer = root.find_child(l_name)

	if layer == null:
		push_error('Could not find layer_name {0} inside Node {1} '.format([l_name, root]))

	return layer

func grab_floor_layers() -> Dictionary[String, HexagonTileMapLayer]:

	var layers: Dictionary[String, HexagonTileMapLayer] = {}
	for layer_name in grab_layer_names():
		layers[layer_name] = find_child(layer_name)

	return layers


func grab_layer_names() -> Array[String]:
	return LAYER_NAMES as Array[String]

func grab_rooms_scenes() -> Array:
	return room_scenes

func init_rooms(room_scene_list: Array) -> Array[Room]:

	var inited_rooms: Array[Room] = []

	for r in room_scene_list:
		var room = Room.new()
		room.root_node = r.instantiate()

		store_room_layers(room)

		inited_rooms.append(room)

	return inited_rooms


func store_room_layers(room:Room):

	for layer_name in grab_layer_names():
		var layer:HexagonTileMapLayer = find_hex_layer_child_in_node(room.root_node, layer_name)

		if layer == null:
			continue

		var layer_info = LayerInfo.new()
		layer_info.name = layer_name
		layer_info.hex_layer = layer
		store_layer_cell_info(layer_info)
	
		room.layers[layer_name] = layer_info

func store_layer_cell_info(layer:LayerInfo):
	var cell_vects := layer.hex_layer.get_used_cells()
	var hex_layer := layer.hex_layer

	for vect in cell_vects:
		var cell_info = Cell.new()
		cell_info.vector = vect
		cell_info.atlas_coord = hex_layer.get_cell_atlas_coords(vect)
		cell_info.id_source = hex_layer.get_cell_source_id(vect)
		cell_info.id_alt = hex_layer.get_cell_alternative_tile(vect)

		layer.cells.append(cell_info)

func place_rooms(placeable_rooms:Array[Room]):

	var anchor := Vector3i.ZERO

	for room in placeable_rooms:
		
		# align room to a certain vect
		var transform := anchor - get_entrance_cube(room.layers['Placeables'])


		for layer_name in room.layers:

			var cur_layer: LayerInfo = room.layers[layer_name]
			#var cur_hex_lay := cur_layer.hex_layer

			for cell in cur_layer.cells:
				cell = cell as Cell

				cell.vector = floor_layers['Placeables'].cube_to_map(
					floor_layers['Placeables'].map_to_cube(cell.vector) + transform
				)

				floor_layers[layer_name].set_cell(cell.vector, cell.id_source, cell.atlas_coord, cell.id_alt)

		anchor = get_exit_cube(room.layers['Placeables'])

## returns first instance of a cell that can be an entrance
func get_entrance_cube(ground_layer:LayerInfo) -> Vector3i:
	var entrances = []
	for cell in ground_layer.cells:
		if cell.atlas_coord == PLACEABLES_TILES['DOORWAY'] or cell.atlas_coord == PLACEABLES_TILES['ENTRANCE']:
			entrances.append( floor_layers['Ground'].map_to_cube(cell.vector))

	if entrances.size() < 1:		
		push_error('Could not find an entrance')
		return Vector3i.ZERO

	return entrances[0]

## returns first instance of a cell that can be an exit
func get_exit_cube(ground_layer:LayerInfo) -> Vector3i:
	var exits = []
	for cell in ground_layer.cells:
		if cell.atlas_coord == PLACEABLES_TILES['DOORWAY'] or cell.atlas_coord == PLACEABLES_TILES['EXIT']:
			exits.append( floor_layers['Ground'].map_to_cube(cell.vector) )

	if exits.size() < 1:	
		push_error('Could not find an exit')
		return Vector3i.ZERO

	return exits[0]
