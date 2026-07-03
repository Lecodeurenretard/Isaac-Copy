class_name EntityRoomData extends Resource 
@export var x : int
@export var y : int
@export var type : int
@export var variant : int
@export var subtype : int
@export var weight : float

static func from_file(file_handle : FileAccess) -> Array:
	var x_entities = RoomData.uint_to_sint(file_handle.get_16(), 16)
	var y_entities = RoomData.uint_to_sint(file_handle.get_16(), 16)
	var entity_count = file_handle.get_8()
	
	var res = Array()
	for i in range(entity_count):
		var entity := EntityRoomData.new()
		entity.x = x_entities
		entity.y = y_entities
		entity.type = file_handle.get_16()
		entity.variant = file_handle.get_16()
		entity.subtype = file_handle.get_16()
		entity.weight = file_handle.get_float()
		res.append(entity)
	
	return res
