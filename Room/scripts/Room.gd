class_name Room extends Node2D

#@export_file_path("*.stb") var data_file : String
#@export var room_name : int = 0
#@onready var data : RoomData = RoomData.from_file(data_file)[0]
@export var data : RoomData


@onready var background = $LevelLayer 
#@onready var doors = $DoorLayer 

func _set_corners(top_left : Vector2i, source_id : int, atlas_coord : Vector2i, dim : Array[int]):
	var bottom_right = Vector2i(dim[0] - top_left.x - 1, dim[1] - top_left.y - 1)
	background.set_cell(top_left, source_id, atlas_coord)
	background.set_cell(bottom_right, source_id, atlas_coord, TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V)
	background.set_cell(Vector2i(top_left.x, bottom_right.y), source_id, atlas_coord, TileSetAtlasSource.TRANSFORM_FLIP_V)
	background.set_cell(Vector2i(bottom_right.x, top_left.y), source_id, atlas_coord, TileSetAtlasSource.TRANSFORM_FLIP_H)

func _set_symetrical(top_left : Vector2i, source_id : int, atlas_coord : Vector2i, line_length : int, vertical : bool):
	background.set_cell(top_left, source_id, atlas_coord)
	if vertical:
		background.set_cell(Vector2i(line_length - 1 - top_left.x, top_left.y), source_id, atlas_coord, TileSetAtlasSource.TRANSFORM_FLIP_H)
	else:
		background.set_cell(Vector2i(top_left.x, line_length - 1 - top_left.y), source_id, atlas_coord, TileSetAtlasSource.TRANSFORM_FLIP_V)

func generate_room(stage_id : int):
	var dimensions := data.get_dimensions()
	
	# outer corners
	_set_corners(Vector2i(0, 0), stage_id, Vector2i(0, 0), dimensions)
	
	# walls
	for x in range(1, dimensions[0]-1):
		var atlas_x := ((x-2) % 7) + 2	# 2, 3, 4, 5, 6, 7, 8, 2, 3, ...
		_set_symetrical(Vector2i(x, 0), stage_id, Vector2i(atlas_x, 0), dimensions[1], false)
		_set_symetrical(Vector2i(x, 1), stage_id, Vector2i(atlas_x, 1), dimensions[1], false)
	for y in range(1, dimensions[1]-1):
		var atlas_y := ((y-2) % 3) + 2
		_set_symetrical(Vector2i(0, y), stage_id, Vector2i(0, atlas_y), dimensions[0], true)
		_set_symetrical(Vector2i(1, y), stage_id, Vector2i(1, atlas_y), dimensions[0], true)
	
	# inner corners
	_set_corners(Vector2i(1, 1), stage_id, Vector2i(1, 1), dimensions)
	
	# floor tiles next to walls
	_set_corners(Vector2i(2, 2), stage_id, Vector2i(2, 2), dimensions)
	for x in range(3, dimensions[0]-3):
		var atlas_x := ((x-3) % 6) + 3	# 3, 4, 5, 6, 7, 8, 3, 4, ...
		_set_symetrical(Vector2i(x, 2), stage_id, Vector2i(atlas_x, 2), dimensions[1], false)
	for y in range(3, dimensions[1]-3):
		var atlas_y := ((y-3) % 3) + 3
		_set_symetrical(Vector2i(2, y), stage_id, Vector2i(2, atlas_y), dimensions[0], true)
	
	# floor
	for x in range(3, dimensions[0]-3):
		for y in range(3, dimensions[1]-3):
			background.set_cell(Vector2i(x, y), stage_id, Vector2i(8, 5))

func _ready() -> void:
	generate_room(1)
