extends Node
class_name UI_Controller


#region Tile UI

@onready var tile_tab_btn : Button = %TileTabBtn

@onready var tile_list_tabs : TabContainer = %TileListTabs

var tile_list_names := [
	'Geometry',
	'Enemy',
	'Object',
	'Doors',
]
var list_of_tile_lists := []

## add and manage icons relating to tile groups to include in the tile lists
@onready var included_tile_icons : HBoxContainer = %IncludedIcons
''' 
When all are included, just display one icon: all
General can't be unselected
'''

@onready var editFiltersBttn : Button = %EditFiltersBttn
''' press to open menu to modify what tiles will be in the lists '''


@onready var layer_dropdown_display : OptionButton = %SelectedLayerDropdown
'''
lets user change the and display the current painting layer
'''


#region Tool Bar UI

## add buttons that trigger switch to painting tools
@onready var tool_bttn_container : VBoxContainer= %ToolButtsPanel

## connect to hide tool bar ui
@onready var bar_tab_btn : Button = %ToolBarTabBtn


#endregion

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
