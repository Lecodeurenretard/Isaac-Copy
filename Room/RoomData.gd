class_name RoomData extends Resource
# file specs: https://github.com/Basement-Renovator/basement-renovator/blob/main/resources/Notes/Room%20Format.txt
# actual parser: https://github.com/Basement-Renovator/basement-renovator/blob/main/src/roomconvert.py#L352

enum _Shape {
	MED_MED = 1,
	MED_SMALL,
	SMALL_MED,
	LARGE_MED,
	LARGE_SMALL,
	MED_LARGE,
	SMALL_LARGE,
	LARGE_LARGE,
	CORNER1,
	CORNER2,
	CORNER3,
	CORNER4
}

static func uint_to_sint(x : int, number_of_bits : int) -> int:
	# bit meth
	var mask = 1 << (number_of_bits - 1)
	var res = x & ~mask
	return res - 2**(number_of_bits-1) if x & mask else res

class Door extends Resource:
	var x : int
	var y : int
	var exists : bool
	
	static func from_file(file_handle : FileAccess) -> Door:
		var res = Door.new()
		res.x = Room.uint_to_sint(file_handle.get_16(), 16)
		res.y = Room.uint_to_sint(file_handle.get_16(), 16)
		if [res.x, res.y] not in [[6,-1], [13,3], [6,7], [-1,3]]:
			printerr("Unsual door coordinates: (%d, %d)." % [res.x, res.y])
		
		res.exists = bool(file_handle.get_8())
		return res
	
	func _to_string() -> String:
		return "(%d, %d) %s" % [x, y, str(exists)]

class Entity extends Resource: 
	var x : int
	var y : int
	var type : int
	var variant : int
	var subvariant : int
	func _to_string() -> String:
		return "(%d, %d) %d %d" % [x, y, type, variant]
	
	static func from_file(file_handle : FileAccess) -> Array:
		var x = Room.uint_to_sint(file_handle.get_16(), 16)
		var y = Room.uint_to_sint(file_handle.get_16(), 16)
		var entity_count = file_handle.get_8()
		
		var res = Array()
		for i in range(entity_count):
			var entity := Entity.new()
			entity.x = x
			entity.y = y
			entity.type = file_handle.get_16()
			entity.variant = file_handle.get_16()
			entity.subvariant = file_handle.get_16()
			res.append(entity)
			
			if file_handle.get_float() != 1.0:
				printerr("The file might not be correctly formatted (last entity entry should be 1.0).") 
		
		return res

@export var room_type : int
@export var variant : int
@export var subvariant : int
#@export var difficulty : int	## THIS SHOULD NOT BE USED. Not sure if that's difficulty.
@export var name : String
@export var width : int
@export var height : int
@export var shape : _Shape = _Shape.MED_MED
@export var doors : Array[Door]
@export var entities : Array[Entity]


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
		print_debug(u)
		var room := RoomData.new()
		room.room_type = file.get_32()
		if room.room_type not in [1, 18]:
			printerr("Unusual room type: ", room.room_type)
		
		room.variant = file.get_32()
		if room.variant not in [0, 1, 6]:
			printerr("Unusual room variant: ", room.variant)
		
		room.subvariant = file.get_32()
		if room.subvariant > 64:
			printerr("Unusual room subvariant: ", room.subvariant)
		
		file.get_8()	# difficulty?
		
		var name_length := file.get_16()
		var name_bytes := PackedByteArray()
		for i in range(name_length):
			name_bytes.append(file.get_8())
		room.name = name_bytes.get_string_from_utf8()
		
		if file.get_float() != 1.0:
			printerr("The file might not be correctly formatted (a float representing 1.0 should be after the room name).")
		
		room.width = file.get_8()
		if room.width not in [13, 26]:
			printerr("Invalid room width: ", room.width, " (must be 13 or 26)")
			return [null]
		
		room.height = file.get_8()
		if room.height not in [7, 14]:
			printerr("Invalid room height: ", room.height, " (must be 7 or 14)") 
			return [null]
		
		room.shape = file.get_8() as _Shape
		
		var door_entry_count = file.get_8()  
		var entity_entry_count = file.get_16()
		for v in range(door_entry_count):
			# also advance the file cursor (implicit reference)
			room.doors.append(Door.from_file(file))
		for v in range(entity_entry_count):
			room.entities.append_array(Entity.from_file(file))
		
		res.append(room)
	return res
