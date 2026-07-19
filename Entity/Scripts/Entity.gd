class_name Entity extends CharacterBody2D

static var data : Dictionary = {}
static var template : PackedScene = preload("res://Entity/Entity.tscn")

@export var id : int		= 1
@export var variant : int	= 0
@export var subtype : int	= 0

var general_data : EntityXML:
	get():
		return data[id][variant][subtype]

var anim_lib_name := &"lib"
func _load_animation_library(library : AnimationLibrary) -> void:
	if $AnimationPlayer.has_animation_library(anim_lib_name):
		$AnimationPlayer.remove_animation_library(anim_lib_name)
	$AnimationPlayer.add_animation_library(anim_lib_name, library)

func _load_spritesheets(paths : Dictionary[int, String]) -> void:
		var used_layers : Array[int] = paths.keys()
		for layer_id in used_layers:
			var sprite_name := str(layer_id)
			if not has_node(sprite_name):
				var new_sprite := $Sprites/template.duplicate()
				new_sprite.name = sprite_name
				new_sprite.visible = true
				$Sprites.add_child(new_sprite)
			
			$Sprites.get_node(sprite_name).texture.atlas = load("res://resources/gfx/" + paths[layer_id]) 
		
		# Hide unused layers
		# Last .filter() serves as an equivalent to a .forEach() since Godot doesn't provide one
		$Sprites.get_children()														\
			.map(func(node : Node2D): return node.name)								\
			.filter(func(node_name : String): return node_name != "template")		\
			.filter(func(node_name : String): return int(node_name) not in used_layers)	\
			.filter(func(node_name : String): $Sprites.get_node(node_name).visible = false)

static func _static_init() -> void:
	data = XML._parse_entities()

static func spawn(pos : Vector2) -> Entity:
	var res := preload("res://Entity/Entity.tscn").instantiate().duplicate()
	res.position = pos
	return res

func _ready() -> void:
	var anim_data = XML.parse_anm2("res://resources/gfx/" + general_data.anm2path)
	_load_animation_library(anim_data[0])
	_load_spritesheets(anim_data[2])
	
	$AnimationPlayer.play(anim_lib_name + '/' + anim_data[1])
	
	$Hitbox.scale.x = 1.0 / general_data.hitbox_radius_x_multi
	$Hitbox.scale.y = 1.0 / general_data.hitbox_radius_y_multi
