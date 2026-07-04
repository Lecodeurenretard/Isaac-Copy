class_name Room extends Node2D

@export_file_path("*.stb") var data_file : String
@export var room_index : int = 0
@onready var data : RoomData = RoomData.from_file(data_file)[room_index]
#@export var data : RoomData

@onready var background = $LevelLayer 
var stage_id := 1

enum Direction {
	NONE  = -1,
	RIGHT = 0,
	DOWN  = 1,
	LEFT  = 2,
	UP    = 3,
}

## Return a function that repeats [minimum, maximum) in a circular pattern,
## For example, clamp_loopi(m, M, 0) returns f() such as
## f(0) = m, f(1) = m + 1, ..., f(M-1) = M - 1, f(M) = m, f(M+1) = m + 1, ...
##
## The shift parameter shifts right the sequence. 
func gen_circular_clamp(minimum : int, maximum : int, shift : int) -> Callable:
	# play with this formula: https://www.desmos.com/calculator/lzaffyk71w
	return func(n : int) -> int:
		return (n - shift) % (maximum - minimum) + minimum

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
func generate_tilemap():
	var dimensions := data.get_dimensions()
	
	# outer corners
	_set_corners(Vector2i(0, 0), stage_id, Vector2i(0, 0), dimensions)
	
	# walls
	var gen_wall_x := gen_circular_clamp(2, 9, 2 )
	var gen_wall_y := gen_circular_clamp(2, 6, 2 )
	for x in range(1, dimensions.x-1):
		var atlas_x : int = gen_wall_x.call(x)
		_set_symetrical(Vector2i(x, 0), stage_id, Vector2i(atlas_x, 0), dimensions.y, false)
		_set_symetrical(Vector2i(x, 1), stage_id, Vector2i(atlas_x, 1), dimensions.y, false)
	for y in range(1, dimensions.y-1):
		var atlas_y : int = gen_wall_y.call(y)
		_set_symetrical(Vector2i(0, y), stage_id, Vector2i(0, atlas_y), dimensions.x, true)
		_set_symetrical(Vector2i(1, y), stage_id, Vector2i(1, atlas_y), dimensions.x, true)
	
	# inner corners
	_set_corners(Vector2i(1, 1), stage_id, Vector2i(1, 1), dimensions)
	
	# floor tiles next to walls
	var gen_floor_x := gen_circular_clamp(3, 9, 3)
	var gen_floor_y := gen_circular_clamp(3, 6, 3)
	
	_set_corners(Vector2i(2, 2), stage_id, Vector2i(2, 2), dimensions)
	for x in range(3, dimensions.x-3):
		var atlas_x : int = gen_floor_x.call(x)
		_set_symetrical(Vector2i(x, 2), stage_id, Vector2i(atlas_x, 2), dimensions.y, false)
	for y in range(3, dimensions.y-3):
		var atlas_y : int = gen_floor_y.call(y)
		_set_symetrical(Vector2i(2, y), stage_id, Vector2i(2, atlas_y), dimensions.x, true)
	
	# floor
	for x in range(3, dimensions.x-3):
		for y in range(3, dimensions.y-3):
			var atlas_x : int = gen_floor_x.call(x)
			var atlas_y : int = gen_floor_y.call(y)
			background.set_cell(Vector2i(x, y), stage_id, Vector2i(atlas_x, atlas_y))

# Door parsing code: https://github.com/Basement-Renovator/basement-renovator/blob/main/BasementRenovator.py#L2177
func generate_doors():
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
		sprite.texture = load("uid://ufu3ohqbtdah")
		
		var sprite_background := Sprite2D.new()
		sprite_background.texture = load("uid://ufu3ohqbtdah").duplicate()
		sprite_background.texture.region.position.x = 71.8
		sprite_background.scale = Vector2(1.3, 1.3)
		sprite.add_child(sprite_background)
		
		$LevelLayer.add_child(sprite)
		sprite.z_index = 10
		sprite_background.z_index = -5
		

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


func _change_stage(new_stage : int) -> void:
	stage_id = new_stage
	var tilemap_dim : Rect2i = $LevelLayer.get_used_rect()
	for x in range(tilemap_dim.position.x, tilemap_dim.end.x + 1):
		for y in range(tilemap_dim.position.y, tilemap_dim.end.y + 1):
			var pos := Vector2i(x, y)
			$LevelLayer.set_cell(
				pos,
				stage_id, 
				$LevelLayer.get_cell_atlas_coords(pos),
				$LevelLayer.get_cell_alternative_tile(pos),
			)

func _ready() -> void:
	generate_tilemap()
	generate_doors()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("dbg_next_floor"):
		var new_id := stage_id + 1
		if new_id == 7:	# Necropolis -> Burning Basement 
			new_id = 13
		if new_id == 16:
			new_id = 0
		_change_stage(new_id)
