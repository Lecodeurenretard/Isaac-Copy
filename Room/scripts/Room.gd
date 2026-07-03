class_name Room extends Node2D

@export_file_path("*.stb") var data_file : String
@export var room_index : int = 0
@onready var data : RoomData = RoomData.from_file(data_file)[room_index]
#@export var data : RoomData

@onready var background = $LevelLayer 

enum Direction {
	NONE  = -1,
	RIGHT = 0,
	DOWN  = 1,
	LEFT  = 2,
	UP    = 3,
}

func _set_corners(top_left : Vector2i, source_id : int, atlas_coord : Vector2i, dim : Vector2i):
	var bottom_right = dim - Vector2i(1, 1) - top_left
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

# TODO: Add support for L and r rooms
func generate_tilemap(stage_id : int):
	var dimensions := data.get_dimensions()
	
	# outer corners
	_set_corners(Vector2i(0, 0), stage_id, Vector2i(0, 0), dimensions)
	
	# walls
	for x in range(1, dimensions.x-1):
		var atlas_x := ((x-2) % 7) + 2	# 2, 3, 4, 5, 6, 7, 8, 2, 3, ...
		_set_symetrical(Vector2i(x, 0), stage_id, Vector2i(atlas_x, 0), dimensions.y, false)
		_set_symetrical(Vector2i(x, 1), stage_id, Vector2i(atlas_x, 1), dimensions.y, false)
	for y in range(1, dimensions.y-1):
		var atlas_y := ((y-2) % 3) + 2
		_set_symetrical(Vector2i(0, y), stage_id, Vector2i(0, atlas_y), dimensions.x, true)
		_set_symetrical(Vector2i(1, y), stage_id, Vector2i(1, atlas_y), dimensions.x, true)
	
	# inner corners
	_set_corners(Vector2i(1, 1), stage_id, Vector2i(1, 1), dimensions)
	
	# floor tiles next to walls
	_set_corners(Vector2i(2, 2), stage_id, Vector2i(2, 2), dimensions)
	for x in range(3, dimensions.x-3):
		var atlas_x := ((x-3) % 6) + 3	# 3, 4, 5, 6, 7, 8, 3, 4, ...
		_set_symetrical(Vector2i(x, 2), stage_id, Vector2i(atlas_x, 2), dimensions.y, false)
	for y in range(3, dimensions.y-3):
		var atlas_y := ((y-3) % 3) + 3
		_set_symetrical(Vector2i(2, y), stage_id, Vector2i(2, atlas_y), dimensions.x, true)
	
	# floor
	for x in range(3, dimensions.x-3):
		for y in range(3, dimensions.y-3):
			background.set_cell(Vector2i(x, y), stage_id, Vector2i(8, 5))

# Door parsing code: https://github.com/Basement-Renovator/basement-renovator/blob/main/BasementRenovator.py#L2177
func generate_doors(_stage_id : int):
	for door in data.doors:
		if not door.exists:
			continue
		
		var sprite := Sprite2D.new()
		var door_pos := Vector2(door.x, door.y) + Vector2(2, 2)	# Accounting for walls
		if data.shape == RoomData.Shape.SMALL_MED || data.shape == RoomData.Shape.SMALL_LARGE:
			door_pos.x -= 4 
		if data.shape == RoomData.Shape.MED_SMALL || data.shape == RoomData.Shape.LARGE_SMALL:
			door_pos.y -= 2		# the first tile is at (0, 2) for some reasons 
		sprite.position = $LevelLayer.map_to_local(door_pos)
		
		var door_dir := _get_door_dir(door)
		if door_dir == Direction.NONE:
			printerr("Invalid door position: (%d, %d)" % [door.x, door.y])
		sprite.rotation_degrees = -90 + int(door_dir) * 90	
		sprite.texture = load("uid://ufu3ohqbtdah")	# TODO: Add level specific doors
		
		var sprite_background := Sprite2D.new()
		sprite_background.texture = load("uid://ufu3ohqbtdah").duplicate()
		sprite_background.texture.region.position.x = 71.8
		sprite.add_child(sprite_background)
		
		$LevelLayer.add_child(sprite)

func _get_door_dir(door : DoorRoomData) -> Direction:
	if !door.exists:
		return Direction.NONE
	# first row
	if door.y <= -1: #and data.shape not in [RoomData.Shape.SMALL_MED, RoomData.Shape.SMALL_LARGE]:
		return Direction.DOWN
	# last row
	if door.y >= 14: #and data.shape not in [RoomData.Shape.MED_MED, RoomData.Shape.MED_SMALL, RoomData.Shape.SMALL_MED, RoomData.Shape.MED_LARGE, RoomData.Shape.LARGE_MED, RoomData.Shape.LARGE_SMALL]:
		return Direction.UP
	# first column
	if door.x <= -1: #and data.shape not in [RoomData.Shape.MED_SMALL, RoomData.Shape.LARGE_SMALL]:
		return Direction.RIGHT
	# last column
	if door.x >= 26: #and data.shape not in [RoomData.Shape.MED_MED, RoomData.Shape.MED_SMALL, RoomData.Shape.SMALL_MED, RoomData.Shape.MED_LARGE, RoomData.Shape.LARGE_MED, RoomData.Shape.LARGE_MED, RoomData.Shape.LARGE_SMALL]:
		return Direction.LEFT
	
	# TODO: Modify so L and r rooms are supported
	# middle row
	if door.y == 7:
		return Direction.UP
	# middle column
	if door.x == 13:
		return Direction.LEFT
	
	return Direction.NONE

func _ready() -> void:
	var stage_id := 1
	generate_tilemap(stage_id)
	generate_doors(stage_id)
