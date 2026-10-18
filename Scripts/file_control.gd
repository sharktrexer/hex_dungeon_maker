extends Node
class_name FileController

const SAVE_ROOM_PATH = 'res://RoomSaveData//'

signal on_save(path:String)
signal on_load(path:String)
signal failed_file_access(err_msg:String)

var cur_file_data_str: String

func cur_file_data_as_dict():
	return JSON.parse_string(cur_file_data_str)

func get_data_as_string(
	room_info:Dictionary[String,String], 
	layers: Dictionary[String, HexagonTileMapLayer]
	):

	var room_tile_data = dictify_room_data(layers)

	var room_data = {
		'room_details' = room_info,
		'room_tile_data' = room_tile_data
	}

	return JSON.stringify(room_data, '\t')

func save_room_to_file(
	room_info:Dictionary[String,String], 
	layers: Dictionary[String, HexagonTileMapLayer]
	):

	# get path and data
	var room_file_path = convert_to_room_path(room_info['group'], room_info['name'])
	
	var data_as_json = get_data_as_string(room_info, layers)

	# attempt save
	var success_msg = access_room_data_from_file(room_file_path, FileAccess.WRITE, data_as_json)
	if success_msg == '':
		return

	# manage file movement if applicable
	manage_path_change(data_as_json)

	# update data pointer
	cur_file_data_str = data_as_json

	on_save.emit(room_file_path)
	print("Canvas SAVED to ", room_file_path)

## if the name or grouping of a stage is changed, delete old data and save in new place
func manage_path_change(new_path:String):
	if not cur_file_data_str:
		return
		
	var old_path = get_file_path_from_room_dict(cur_file_data_as_dict())
	if new_path == old_path:
		return
	# delete old path file if diff
	pass

func load_room(room_folder:String, room_name:String) -> bool:

	var room_path = convert_to_room_path(room_folder, room_name)

	print("cleared current canvas")

	var loaded_data = access_room_data_from_file(room_path, FileAccess.READ) 
	if loaded_data == '':
		return false

	cur_file_data_str = loaded_data 

	on_load.emit(room_path)
	print('LOADING complete from ', room_path)
	return true

## get absolute path of file 
func convert_to_room_path(room_folder:String, room_name:String, extension:='.json') -> String:
	return SAVE_ROOM_PATH + room_folder + '//' + room_name + extension

func access_room_data_from_file(file_path: String, mode:FileAccess.ModeFlags, room_data_string='') -> String:

	if mode == FileAccess.WRITE and room_data_string == '':
		failed_file_access.emit("Attempted to save no data to ", file_path)
		return ''

	var room_file = FileAccess.open(file_path, mode)

	if room_file == null:
		failed_file_access.emit(error_string(FileAccess.get_open_error()))
		print(error_string(FileAccess.get_open_error()))
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

func get_file_path_from_room_str(room_data_string:String) -> String:

	var parsed_data = JSON.parse_string(room_data_string)
	return get_file_path_from_room_dict(parsed_data)

func get_file_path_from_room_dict(room_data_dict:Dictionary) -> String:

	var folder_name = str(room_data_dict['room_details']['group'])
	var file_name = str(room_data_dict['room_details']['name'])

	return convert_to_room_path(folder_name, file_name)

## converts the tile data of each layer into a dictionary 
## that groups each tile per layer by their shared coord
static func dictify_room_data(layers: Dictionary) -> Dictionary:

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
					'atlas_coord' : layers[key].get_cell_atlas_coords(coord),
					'source_id' : layers[key].get_cell_source_id(coord),
					'alt_id' : layers[key].get_cell_alternative_tile(coord),
				}
			
		map_data[str(coord)] = layer_coord_data

	return map_data


## call after user tries to load or save, so launching doesnt have long load time?
func grab_saved_rooms():
	var files: PackedStringArray = []
	var folders = DirAccess.get_directories_at(SAVE_ROOM_PATH)
	for dir in folders:
		print(dir)
		for file in DirAccess.get_files_at(SAVE_ROOM_PATH + dir):
			files.append(dir + '//' + file)
	print(files)