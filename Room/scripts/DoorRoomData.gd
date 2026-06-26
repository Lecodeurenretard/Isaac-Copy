class_name DoorRoomData extends Resource
var x : int
var y : int
var exists : bool

## Parse a part of the game's stb file
## Move the file cursor
static func from_file(file_handle : FileAccess) -> DoorRoomData:
	var res = DoorRoomData.new()
	res.x = RoomData.uint_to_sint(file_handle.get_16(), 16)
	res.y = RoomData.uint_to_sint(file_handle.get_16(), 16)
	if [res.x, res.y] not in [[6,-1], [13,3], [6,7], [-1,3]]:
		printerr("Unsual door coordinates: (%d, %d)." % [res.x, res.y])
	
	res.exists = bool(file_handle.get_8())
	return res
