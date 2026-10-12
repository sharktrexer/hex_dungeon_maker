extends Node
class_name UI_Controller

#region Tab Management

enum MenuTab {
	Confirmation,
	Hud,
	RoomSelect,
	Filtering,
	Options,
	RoomInfo,
}

# contains all menus to switch between
@onready var main_switcher := %UI_Switcher as TabContainer

## change tab to the index. 
func switch_tab(tab:MenuTab):
	main_switcher.current_tab = tab

func confirm_before_switch(agree:Confirmation):
	switch_tab(MenuTab.Confirmation)
	confirm_btn.button_up.connect(switch_tab(agree.to_tab), CONNECT_ONE_SHOT)
	abort_btn.button_up.connect(switch_tab(agree.from_tab), CONNECT_ONE_SHOT)
	msg_display.text = agree.msg
  

class Confirmation:
	var to_tab: MenuTab
	var from_tab: MenuTab
	var msg: String

#region Editing Overlay UI

@onready var tile_select_ui := %TileSelectUI as Panel

@onready var tile_tab_btn : Button = %TileTabBtn
# hide tile UI 

@onready var tile_list_tabs : TabContainer = %TileListTabs as TabContainer

var tile_list_names := [
	'Geometry',
	'Enemy',
	'Object',
	'Doors',
]
var tile_tab_list := []

## add and manage icons relating to tile groups to include in the tile lists
@onready var included_tile_icons : HBoxContainer = %IncludedIcons as HBoxContainer
''' 
When all are included, just display one icon: all
General can't be unselected
'''

@onready var editFiltersBttn : Button = %EditFiltersBttn as Button
''' press to open menu to modify what tiles will be in the lists '''


@onready var layer_dropdown_display := %SelectedLayerDropdown as OptionButton
'''
lets user change and display the current painting layer
'''

func toggle_control_visibility(ui_part:Control):
	if ui_part.visible:
		ui_part.hide()
	else:
		ui_part.show()

# Tool Bar

@onready var toolbar_ui := %ToolBarPanel as Panel

## add buttons that trigger switch to painting tools
@onready var tool_bttn_container : VBoxContainer= %ToolButtsPanel

## connect to hide tool bar ui
@onready var tab_bar_btn : Button = %ToolBarTabBtn

func toggle_show_tool_bar():
	pass

#endregion

#region Confirm UI

@onready var msg_display = %ConfirmMsg as RichTextLabel
@onready var confirm_btn = %ConfirmBtn as Button
@onready var abort_btn = %AbortBtn as Button

#endregion

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	tile_tab_btn.button_up.connect(toggle_control_visibility.bind(tile_select_ui))
	tab_bar_btn.button_up.connect(toggle_control_visibility.bind(toolbar_ui))

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

'''
-----------Main Editing UI-----------

-fill each tab with appropriate tiles
- fill toolbar with tool btns

-close/open left UI
-ditto for right UI
-change to tool btn
-change layer btn??
-open filters menu
-open option menu trigger

-----------Room Select Menu-----------

-populate avial rooms list
-change tab trigger (all, ice, fire etc) base on stage group

-create new room trigger (create blank, unsaved room)
-select room trigger (from avail list or variant list)
populates sidebar with info of room

-dupe selected room trigger (does not dupe variants)
	opens editor with transferred room data, then auto calls "save from blank" func
-load selected room trigger
-delete selected room trigger (trigger are you sure pop up) 
deletes file and any variants of it

-----------Filter Menu-----------

-populate filter option grid
-apply btn (take all pressed filters and add to filter list)
-select all btn trigger
-cancel trigger (don't save filter choices)

-----------Options Menu-----------

-save btn trigger
save from blank: 
	choose name if haven't already
		ensure name is unique from any other room
		stage group defaults to "general" if not
	trigger new save 
		create new file

save from established room data:
	trigger save on current file
		if has variants, update variants with any updated info

	? If user wants to overwrite a save ?


create variant (must be established room with data)
	act like "choose existing room to be variant of" func

edit info:
	open edit info menu	

resume:
	go back to editing

new room:
	create blank room

load:
	open Room Select Menu

Additionally, if there are unsaved changes, ask for confirmation before pursuing affects from:
	load
	new room
	create variant

-----------Edit Info menu-----------
- desc text box
locked if variant, must be same as parent:
- stage group dropdown 
-tags?
-room type (secret, regular, treasure, challenge)

-cancel btn disregard changes
-ok btn, will keep info to be saved when save trigged


-----------Confrimation Menu-----------

-msg
-accept button
-cancel btn

'''
