extends Node
class_name FileController

const SAVE_ROOM_PATH = 'res://RoomSaveData//'

# data keys
const ROOM_INFO_KEY = 'room_details'
const ROOM_CANVAS_KEY = 'room_tile_data'

signal on_save(path:String)
signal on_load(path:String)
signal failed_file_access(err_msg:String)

var saved_room_names_by_folder: Dictionary[String, Array]

var cur_file_data_str: String

var loaded_dict_data: Dictionary

## assumes this set of data is blank and not worth saving.
## instead used to compare against blank level data to confirm no changes
func set_blank_data(blank_data:String):
	cur_file_data_str = blank_data

func cur_file_data_as_dict() -> Dictionary:
	return convert_json_to_dict(cur_file_data_str)

# uses JSON parse string
func convert_json_to_dict(json:String)-> Dictionary:
	return JSON.parse_string(json)

func cur_room_info_data_as_dict() -> Dictionary[String, String]:
	var room_info_typed_dict = {} as Dictionary[String, String]
	var untyped_dict_data = cur_file_data_as_dict()[ROOM_INFO_KEY] 

	for key in untyped_dict_data:
		room_info_typed_dict[str(key)] = str(untyped_dict_data[key])

	return room_info_typed_dict

func cur_room_tile_data_as_dict() -> Dictionary:
	return cur_file_data_as_dict()[ROOM_CANVAS_KEY] 

func dupe_room_with_new_name(dupee_name:String, new_name:String):

	'''
	load room json into var using its name
	convert to dict
	change name to name_copy
	save changes to file of name_copy
	'''

	#TODO: copies a lot from save room func. maybe fix

	var dupee_dict_data := convert_json_to_dict(get_room_data_by_name(dupee_name))

	dupee_dict_data[ROOM_INFO_KEY]['name'] = new_name

	var new_file_path = get_file_path_from_room_dict(dupee_dict_data)

	var duped_room_json = JSON.stringify(dupee_dict_data, '\t')	

	# attempt save
	var success_msg = access_room_data_from_file(new_file_path, FileAccess.WRITE, duped_room_json)
	if success_msg == '':
		return

	on_save.emit(new_file_path)
	print("Canvas SAVED to ", new_file_path)

	# update internal list of saved rooms
	update_saved_rooms_names()


## convert raw HexagonTileMapLayer data of room  with its info to string json
func stringify_raw_room_data(
	room_info:Dictionary[String,String], 
	layers: Dictionary[String, HexagonTileMapLayer]
	):

	var room_tile_data = dictify_room_layer_data(layers)
	
	return stringify_room_data(room_info, room_tile_data)

## groups each dict of data under a key and stringifies it
func stringify_room_data(
	room_info:Dictionary[String,String], 
	room_tile_data: Dictionary
	):
	var room_data = {}
	room_data[ROOM_INFO_KEY] = room_info
	room_data[ROOM_CANVAS_KEY] = room_tile_data
	
	return JSON.stringify(room_data, '\t')	

## save to file the changed room info with the unchanged, dictified layer data
# func only_save_room_info_changes(room_info:Dictionary[String,String]):
# 	var prev_saved_layer_data = cur_room_tile_data_as_dict()
# 	save_room_to_file(room_info, prev_saved_layer_data, false)

func save_room_to_file(
	room_info:Dictionary[String,String], 
	layer_data: Dictionary,
	is_layer_data_raw=true
	):

	# get path and data
	var room_file_path = convert_to_room_path(room_info['group'], room_info['name'])
	
	var data_as_json = stringify_raw_room_data(room_info, layer_data) if is_layer_data_raw else stringify_room_data(room_info, layer_data)

	# attempt save
	var success_msg = access_room_data_from_file(room_file_path, FileAccess.WRITE, data_as_json)
	if success_msg == '':
		return

	# manage file movement if applicable
	manage_path_change(room_file_path)

	# update data pointer
	cur_file_data_str = data_as_json

	on_save.emit(room_file_path)
	print("Canvas SAVED to ", room_file_path)

	# update internal list of saved rooms
	update_saved_rooms_names()

## if the name or grouping of a stage is changed, delete old data if applicable
func manage_path_change(new_path:String):
	var old_path = get_file_path_from_room_dict(cur_file_data_as_dict())
	if new_path == old_path:
		return

	if not FileAccess.file_exists(old_path):
		return

	DirAccess.remove_absolute(old_path)


	

## get the string json data of a room without altering the current edit file
func get_room_data(path:String) -> String:
	return access_room_data_from_file(path, FileAccess.READ) 

## get room data and load it to the current editing file
func load_room(room_name:String) -> bool:

	var loaded_data := get_room_data_by_name(room_name)
	if loaded_data == '':
		return false

	cur_file_data_str = loaded_data 

	var room_path = get_file_path_from_room_dict(cur_file_data_as_dict())

	on_load.emit(room_path)
	print('LOADING complete from ', room_path)
	return true

## get absolute path of file 
func convert_to_room_path(room_folder:String, room_name:String, extension:='.json') -> String:
	return SAVE_ROOM_PATH + room_folder + '//' + room_name + extension

func access_room_data_from_file(file_path: String, mode:FileAccess.ModeFlags, room_data_string=''):

	if mode == FileAccess.WRITE and room_data_string == '':
		failed_file_access.emit("Attempted to save no data to ", file_path)
		return ''

	var room_file = FileAccess.open(file_path, mode)

	if room_file == null:
		failed_file_access.emit(error_string(FileAccess.get_open_error()))
		push_error(error_string(FileAccess.get_open_error()))
		return ''

	if mode == FileAccess.READ:
		return room_file.get_as_text()

	elif mode == FileAccess.WRITE:
		room_file.store_string(room_data_string)
		return 'DONE!'

	return ''

func get_file_path_from_room_dict(room_data_dict:Dictionary) -> String:

	var folder_name = str(room_data_dict[ROOM_INFO_KEY]['group'])
	var file_name = str(room_data_dict[ROOM_INFO_KEY]['name'])

	return convert_to_room_path(folder_name, file_name)

## converts the tile data of each layer into a dictionary 
## that groups each tile per layer by their shared coord
static func dictify_room_layer_data(layers: Dictionary) -> Dictionary:

	var map_data := {}

	var all_cell_coords: Dictionary[String, Array] = {}
	for key in layers:
		all_cell_coords[key] = layers[key].get_used_cells()

	# since tile data is grouped by the shared coord, the layer with the most coords should be found
	var largest_array_size = 0
	var loop_key = ""
	for key in all_cell_coords.keys():
		if all_cell_coords[key].size() > largest_array_size:
			loop_key = key
			largest_array_size = all_cell_coords[key].size()

	# prevent error on empty layers
	var main_cell_coords = []
	if loop_key:
		main_cell_coords = all_cell_coords[loop_key]

	# start loop with the largest coord array 
	var key_list = all_cell_coords.keys()
	key_list.erase(loop_key)
	key_list.insert(0, loop_key)

	# saving data
	for coord in main_cell_coords:
		var layer_coord_data = {}

		for key in key_list:
			if coord not in all_cell_coords[key]:
				layer_coord_data[key] = null
			else:
				layer_coord_data[key] = {
					'atlas_coord' : str(layers[key].get_cell_atlas_coords(coord)),
					'source_id' : str(layers[key].get_cell_source_id(coord)),
					'alt_id' : str(layers[key].get_cell_alternative_tile(coord)),
				}
			
		map_data[str(coord)] = layer_coord_data

	return map_data


## gets all file paths of rooms
## call anytime a new room file is created or has its path changed
func update_saved_rooms_names():
	var folders := DirAccess.get_directories_at(SAVE_ROOM_PATH)
	for dir in folders:
		var file_names: PackedStringArray = []
		for file_name in DirAccess.get_files_at(SAVE_ROOM_PATH + dir):
			file_names.append(file_name.get_basename())

		saved_room_names_by_folder[dir] = file_names


## create folders for each room group
func create_room_folders(group_names:Array):
	for folder_name in group_names:
		folder_name = folder_name.to_lower()
		DirAccess.make_dir_absolute(SAVE_ROOM_PATH + folder_name)

func get_all_room_names() -> Array:
	var all_names := []
	for name_lists in saved_room_names_by_folder.values():
		all_names.append_array(name_lists)
	return all_names


func get_room_data_by_name(r_name:String) -> String:

	return get_room_data(get_file_path_by_name(r_name))



func get_room_img_as_texture(path:String) -> Texture2D:
	var img = Image.load_from_file(path)

	if img == null:
		push_error("Failed to load image from " + path)
		return load('uid://0462ner2ujw6')

	var texture = ImageTexture.create_from_image(img)
	return texture

## returns a Dictionary containing the room [data] and its [img]
func get_room_data_and_img(r_name:String) -> Dictionary:
	var file_data_path = get_file_path_by_name(r_name)
	var file_img_path = get_img_path_by_room_path(file_data_path)
	return {
		'data' : get_room_data(file_data_path),
		'img' : get_room_img_as_texture(file_img_path)
	}

func delete_room(r_name:String):
	
	var file_data_path := get_file_path_by_name(r_name)
	var file_img_path = get_img_path_by_room_path(file_data_path)
	DirAccess.remove_absolute(file_data_path)
	DirAccess.remove_absolute(file_img_path)

	update_saved_rooms_names()
	return

## duplicate room files, returns name of new file if successful
# func duplicate_room(r_name:String):
# 	var folders := DirAccess.get_directories_at(SAVE_ROOM_PATH)
# 	for dir in folders:
# 		for file_name in DirAccess.get_files_at(SAVE_ROOM_PATH + dir):
# 			if file_name.get_basename() == r_name:
# 				var file_data_path := convert_to_room_path(dir, r_name)
# 				var file_img_path = convert_to_room_path(dir, r_name, '.jpg')

# 				var dupe_name = r_name + '_copy'
				
# 				var new_file_data_path := convert_to_room_path(dir, dupe_name)
# 				var new_file_img_path = convert_to_room_path(dir, dupe_name, '.jpg')
# 				DirAccess.copy_absolute(file_data_path, new_file_data_path)
# 				DirAccess.copy_absolute(file_img_path, new_file_img_path)

# 				update_saved_rooms_names()
# 				return

func check_if_room_exists(r_name:String) -> bool:
	return get_file_path_by_name(r_name) != ''


func get_file_path_by_name(r_name:String) -> String:
	var folders := DirAccess.get_directories_at(SAVE_ROOM_PATH)
	for dir in folders:
		for file_name in DirAccess.get_files_at(SAVE_ROOM_PATH + dir):
			if file_name.get_basename() == r_name:
				return convert_to_room_path(dir, r_name)

	return ''

func get_img_path_by_room_path(path:String) -> String:
	return path.get_basename() + '.jpg'


'''

room data path
room img path
string json data containing its info
split into text info and the cell data

room seelct ui
needs list of room_name, img
-=-----------------------------------------------
read names of all room files, store without extention
get img with name, add to dict
pass dict to item list
on room select, using its name from itemlist get data to display
on load, update ui and room editor

'''
