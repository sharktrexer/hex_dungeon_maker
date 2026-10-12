extends Node

#region Controllers
@onready var editor = %EditingController as RoomEditor
@onready var UI = %UI_Controller as UI_Controller

#region Input
const ACTION_TILE_PAINT = 'tile_paint'
const ACTION_TILE_ERASE = 'tile_remove'

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	init_geometry()


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

#region Level Geometry
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
