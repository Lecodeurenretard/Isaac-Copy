class_name Rock extends Entity

static func spawn(pos : Vector2) -> Rock:
	var res := preload("res://Entity/Rock.tscn").instantiate().duplicate()
	res.position = pos
	res.get_node("Sprites/0").texture.region.position.x = (randi() % 3) * 32
	return res

func _ready() -> void:
	pass	# overriding Entity._ready()
