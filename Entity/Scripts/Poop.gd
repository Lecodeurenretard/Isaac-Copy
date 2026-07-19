class_name Poop extends Entity

static func spawn(pos : Vector2) -> Poop:
	var res := preload("res://Entity/Poop.tscn").instantiate().duplicate()
	res.position = pos
	return res

func _ready() -> void:
	pass	# overriding Entity._ready()
