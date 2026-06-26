class_name RoomData extends Resource
# file specs: https://github.com/Basement-Renovator/basement-renovator/blob/main/resources/Notes/Room%20Format.txt
# actual parser: https://github.com/Basement-Renovator/basement-renovator/blob/main/src/roomconvert.py#L352

static func uint_to_sint(x : int, number_of_bits : int) -> int:
	# bit meth
	var mask = 1 << (number_of_bits - 1)
	var res = x & ~mask
	return res - 2**(number_of_bits-1) if x & mask else res

enum Shape {
	MED_MED = 1,
	MED_SMALL,
	SMALL_MED,
	LARGE_MED,
	LARGE_SMALL,
	MED_LARGE,
	SMALL_LARGE,
	LARGE_LARGE,
	L_MIRRORED,
	L,
	R_MIRRORED,	# r shaped
	R
}

## Return the room dimensions in tiles.
## L and r rooms are treated as LARGE_LARGE
static func _get_shape_dimensions(s : Shape) -> Array[int]:
	const WALL_SIZE := 2
	const MED_H   := 14		# A room is 14x8 tiles if walls are not counted
	const SMALL_H := MED_H / 2
	const LARGE_H := MED_H * 2
	const MED_V   := 8
	const SMALL_V := MED_V / 2
	const LARGE_V := MED_V * 2
	
	match s:
		Shape.MED_MED:     return [WALL_SIZE * 2 + MED_H  , WALL_SIZE * 2 + MED_V] 
		Shape.MED_SMALL:   return [WALL_SIZE * 2 + MED_H  , WALL_SIZE * 2 + SMALL_V] 
		Shape.SMALL_MED:   return [WALL_SIZE * 2 + SMALL_H, WALL_SIZE * 2 + MED_V] 
		Shape.LARGE_MED:   return [WALL_SIZE * 2 + LARGE_H, WALL_SIZE * 2 + MED_V] 
		Shape.LARGE_SMALL: return [WALL_SIZE * 2 + LARGE_H, WALL_SIZE * 2 + SMALL_V] 
		Shape.MED_LARGE:   return [WALL_SIZE * 2 + MED_H  , WALL_SIZE * 2 + LARGE_V] 
		Shape.SMALL_LARGE: return [WALL_SIZE * 2 + SMALL_H, WALL_SIZE * 2 + LARGE_V] 
		
		Shape.L_MIRRORED, Shape.R_MIRRORED, Shape.L, Shape.R, Shape.LARGE_LARGE:
			return [WALL_SIZE * 2 + LARGE_H, WALL_SIZE * 2 + LARGE_V]
		_:
			printerr("Unknown shape encountered.")
			return []

@export var room_type : int
@export var variant : int
@export var subtype : int
@export var difficulty : int
@export var name : String
@export var weight : float
@export var _width : int
@export var _height : int
@export var shape : Shape = Shape.MED_MED
@export var doors : Array[DoorRoomData]
@export var entities : Array[EntityRoomData]


static func from_file(filename : StringName) -> Array:
	"""returns an array of the rooms contained in the file or [null] if failure to read the file."""
	if not FileAccess.file_exists(filename):
		printerr("Failed to read ", filename, ": file not found.")
		return [null]
	
	var res := Array()
	var file := FileAccess.open(filename, FileAccess.READ)
	
	var signature := file.get_32()
	if signature != 826430547:	# file signature: STB1
		printerr("Failed to read ", filename, ": incorrect file signature (", signature,").")
		return [null]
	
	var room_count = file.get_32()
	for u in range(room_count):
		var room := RoomData.new()
		room.room_type = file.get_32()
		room.variant = file.get_32()
		room.subtype = file.get_32()
		
		room.difficulty = file.get_8()
		if room.difficulty not in [1, 5, 10, 15, 20]:
			printerr("Unusual difficulty value: ", room.difficulty)
		
		var name_length := file.get_16()
		var name_bytes := PackedByteArray()
		for i in range(name_length):
			name_bytes.append(file.get_8())
		room.name = name_bytes.get_string_from_utf8()
		
		room.weight = file.get_float()
		room._width = file.get_8()
		if room._width not in [13, 26]:
			printerr("Invalid room width: ", room.width, " (must be 13 or 26)")
			return [null]
		
		room._height = file.get_8()
		if room._height not in [7, 14]:
			printerr("Invalid room height: ", room.height, " (must be 7 or 14)") 
			return [null]
		
		room.shape = file.get_8() as Shape
		
		var door_entry_count = file.get_8()  
		var entity_entry_count = file.get_16()
		for v in range(door_entry_count):
			# also advance the file cursor (implicit reference)
			room.doors.append(DoorRoomData.from_file(file))
		for v in range(entity_entry_count):
			room.entities.append_array(EntityRoomData.from_file(file))
		
		res.append(room)
	return res

func get_dimensions() -> Array[int]:
	return _get_shape_dimensions(shape)
