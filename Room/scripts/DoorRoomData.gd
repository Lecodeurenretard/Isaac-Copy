class_name DoorRoomData extends Resource
@export var x : int
@export var y : int
@export var exists : bool

## Parse a part of the game's stb file
## Move the file cursor
static func from_file(file_handle : FileAccess) -> DoorRoomData:
	var res = DoorRoomData.new()
	res.x = RoomData.uint_to_sint(file_handle.get_16(), 16)
	res.y = RoomData.uint_to_sint(file_handle.get_16(), 16)
	# TODO: warning is based on the room shape.
	#if [res.x, res.y] not in [[6,-1], [13,3], [6,7], [-1,3]]:
	#	printerr("Unsual door coordinates: (%d, %d)." % [res.x, res.y])
	
	res.exists = bool(file_handle.get_8())
	return res
