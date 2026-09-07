class_name RoomSaver

static func save_room_as_json(name: String, desc: String, group:String, layers: Dictionary) -> String:
	var room_info = {
		'name' : name.to_lower(),
		'desc' : desc,
		'group' : group.to_lower()
	}

	var room_tile_data = dictify_room_data(layers)

	var room_data = {
		'room_details' = room_info,
		'room_tile_data' = room_tile_data
	}

	return JSON.stringify(room_data, '\t')


# converts the tile data of each layer into a dictionary that groups each tile per layer by their shared coord
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
