extends Node2D

## Convert string to boolean, support these format:
## - "true"/"false"
## - '0'/'1'
func stob(b : String) -> bool:
	if b.to_lower() == "true":
		return true
	if b.to_lower() == "false":
		return false
	return int(b) != 0

## returns a dictionary like this: 
## Dictionary [
##   id : int,
##   Dictionary [
##     variant : int,
##     Dictionary [
##       subtype : int,
##       EntityXML
##     ]
##   ]
## ]
func _parse_entities() -> Dictionary[int, Dictionary]:
	var parser := XMLParser.new()
	parser.open("res://resources/entities2.xml")
	if parser.read() != OK:
		push_error("Unknown parser error.")
	if parser.get_node_name() != "entities":
		push_error("Expected <entities> as root element of entities2.xml but found <"+ parser.get_node_name() +"> instead.")
		return {}
	
	var res := {}
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NodeType.NODE_ELEMENT_END and parser.get_node_name() == "entities":
			return res
		if parser.get_node_type() != XMLParser.NodeType.NODE_ELEMENT:
			continue
		if parser.get_node_name() != "entity":
			push_warning("Found unknown tag <" + parser.get_node_name() + "> while parsing entities2.xml.")
			continue
		
		var id := int(parser.get_named_attribute_value("id"))
		var variant := int(parser.get_named_attribute_value("variant"))
		
		var subtype_str := parser.get_named_attribute_value_safe("subtype")
		var subtype := 0 if subtype_str.is_empty() else int(subtype_str)
		
		if not res.has(id):
			res[id] = {}
		if not res[id].has(variant):
			res[id][variant] = {}
		
		var entity := EntityXML.new()
		entity.name     = parser.get_named_attribute_value("name")
		entity.id       = id
		entity.variant  = variant
		entity.subtype  = subtype
		entity.anm2path = parser.get_named_attribute_value("anm2path").to_lower()	# wrong capitalization in the XML for some reason
		entity.base_hp            = int(parser.get_named_attribute_value("baseHP"))
		entity.collision_damage   = float(parser.get_named_attribute_value("collisionDamage"))
		entity.collision_mass     = float(parser.get_named_attribute_value("collisionMass"))
		entity.friction           = float(parser.get_named_attribute_value("friction"))
		entity.hitbox_radius      = float(parser.get_named_attribute_value("collisionRadius"))
		entity.is_boss            = stob(parser.get_named_attribute_value("boss"))
		entity.has_champion       = stob(parser.get_named_attribute_value("champion"))
		
		
		var boss_id_str := parser.get_named_attribute_value_safe("bossID")
		entity.boss_id  = -1 if boss_id_str.is_empty() else int(boss_id_str)
		
		var hitbox_str := parser.get_named_attribute_value_safe("collisionRadiusXMulti")
		entity.hitbox_radius_x_multi = 0.0 if hitbox_str.is_empty() else float(hitbox_str)
		
		hitbox_str = parser.get_named_attribute_value_safe("collisionRadiusYMulti")
		entity.hitbox_radius_y_multi = 0.0 if hitbox_str.is_empty() else float(hitbox_str)
		
		var collision_interval_str := parser.get_named_attribute_value_safe("collisionInterval")
		entity.collision_interval = 1 if collision_interval_str.is_empty() else int(collision_interval_str)
		
		# https://www.reddit.com/r/themoddingofisaac/comments/33rusx/comment/cqo3ryy/
		var collision := parser.get_named_attribute_value_safe("gridCollision")
		if collision.is_empty():
			collision = "floor"
		match collision:
			"none": entity.collision_mask = 0b0
			"walls": entity.collision_mask = 0b1
			"nopits": entity.collision_mask = 0b11
			"ground": entity.collision_mask = 0b11
			"floor": entity.collision_mask = 0b111
			_: 
				push_error("Unknown gridCollision value in <entity> tag.")
				return {}
		
		skip_element(parser)
		
		res[id][variant][subtype] = entity
	
	push_error("Unclosed <entity> tag.")
	return res

## Skip the element and its children.
## Has no effect if the parser is not at the begining of a tag.
func skip_element(parser : XMLParser) -> void:
	if parser.get_node_type() != XMLParser.NodeType.NODE_ELEMENT or parser.is_empty():
		return
	
	var node_name = parser.get_node_name()
	while parser.read() != Error.ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NodeType.NODE_ELEMENT_END and parser.get_node_name() == node_name:
			return
		if parser.get_node_type() == XMLParser.NodeType.NODE_ELEMENT and not parser.is_empty():
			skip_element(parser)

## Read an XML array and returns corresponding attributes in the same order as in attaributes.
## <array>
##   <!-- <== parser must be here when calling-->
##   <elem attrA="1a" attrB="1b" attrC="1c">
##   <elem attrA="2a" attrB="2b" attrC="2c">
##   <elem attrA="3a" attrB="3b" attrC="3c">
## </array>
## <!-- <== parser will be here after function call.-->
## read_array(parser, "elem", ["attrC, "attrA"]) returns:
## [["1c", "1a"], ["2c", "2a"], ["3c", "3a"]]
func read_array(parser : XMLParser, element_name : String, attributes : Array[String]) -> Array[Array]:
	if parser.is_empty():	# for orphans tags
		return []
	
	var container := parser.get_node_name()
	var res : Array[Array] = []
	while parser.read() != Error.ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT_END and parser.get_node_name() == container:
			return res
		if parser.get_node_type() != XMLParser.NODE_ELEMENT or parser.get_node_name() != element_name:
			continue
		var values := []
		for attr in attributes:
			values.append(parser.get_named_attribute_value(attr))
		res.append(values)
	
	push_error("Unclosed <" + container + "> tag.")
	return []

# I couldn't find a spec so it may break
# I do have this though: # https://github.com/ShweetsStuff/anm2ed
## Return an array like this: Array[
##   animations : AnimationLibrary,
##   default_animation : StringName,
##   spritesheets_paths : Dictionary[layer_id : int, path : String],
## ]
## or an empty array on error. 
func parse_anm2(path : String) -> Array:
	var animations := AnimationLibrary.new()
	var spritesheets : Dictionary[int, String] = {}
	var default_animation := &""
	
	var parser := XMLParser.new()
	parser.open(path)
	
	if parser.read() != Error.OK:
		push_error("Error while reading %s." % [path])
		return []
	if parser.get_node_name() != "AnimatedActor":
		push_error("Expected element <AnimatedActor> to be root but found <"+ parser.get_node_name() +"> instead.")
		return []
	
	while parser.read() != Error.ERR_FILE_EOF:
		if parser.get_node_type() != XMLParser.NODE_ELEMENT:
			continue
		
		var node_name = parser.get_node_name()
		if node_name == "Info":
			continue
		if node_name == "Content":
			spritesheets = _parse_anm2_content(parser)
			continue
		if node_name == "Animations":
			default_animation = parser.get_named_attribute_value("DefaultAnimation")
			animations = _parse_anm2_animations(parser)
			continue
		
		push_warning("Unknown tag <", node_name, "> found in <AnimatedActor> of anm2 file at line ",  parser.get_current_line(), ".")
		skip_element(parser)
	return [animations, default_animation, spritesheets]

## Return Dictionary[layer_id : int, spritesheet_path : String]
func _parse_anm2_content(parser : XMLParser) ->  Dictionary[int, String]:
	if parser.get_node_name() != "Content":
		push_error("Expected a <Content> tag.")
		return {}
	
	var paths : Dictionary[int, String] = {}
	var layers : Dictionary[int, int] = {}
	while parser.read() != Error.ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT_END and parser.get_node_name() == "Content":
			var res : Dictionary[int, String] = {}
			for layer_id in layers.keys():
				var spritesheet_id := layers[layer_id]
				res.set(layer_id, paths[spritesheet_id])
			return res
		
		if parser.get_node_type() != XMLParser.NODE_ELEMENT:
			continue
		
		if parser.get_node_name() in ["Nulls", "Events"]:
			skip_element(parser)
			continue
		
		if parser.get_node_name() == "Spritesheets":
			var id_path := read_array(parser, "Spritesheet", ["Id", "Path"])
			for i in range(id_path.size()):
				paths.set(int(id_path[i][0]), id_path[i][1].to_lower())
			continue
		
		if parser.get_node_name() == "Layers":
			var id_id := read_array(parser, "Layer", ["Id", "SpritesheetId"])
			for ids in id_id:
				layers.set(int(ids[0]), int(ids[1]))
			continue
		
		push_warning("Unknown tag <", parser.get_node_name(), "> found while parsing <Content> of anm2 file.")
	push_error("Unclosed <Content> tag.")
	return {}

class _ANM2_Frame:
	var pos : Vector2	# relative to root, if root is (0, 0)
	# var pivot_location : Vector2  # there no native way to do this in Godot
	var image_crop : Rect2i
	var scale : Vector2
	var duration : float		# in seconds, FpS is assumed to be 30
	# var visible : bool	# always visible
	var rotation : int		# in degrees
	# var tint : Color		# unsupported, may be implemented with shaders later
	# var interpolated : bool	# assumed always interpolated

## Return an empty fresh AnimationLibrary on error.
## The root layer is assumed to be untransformed so it does not have a layer.
func _parse_anm2_animations(parser : XMLParser) -> AnimationLibrary:
	if parser.get_node_name() != "Animations":
		push_error("Expected an <Animations> tag.")
		return AnimationLibrary.new()
	
	var res := AnimationLibrary.new()
	while parser.read() != Error.ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT_END and parser.get_node_name() == "Animations":
			return res
		if parser.get_node_type() != XMLParser.NODE_ELEMENT:
			continue
		if parser.get_node_name() in ["NullAnimations", "Triggers", "RootAnimation"]:
			skip_element(parser)
			continue
		if parser.get_node_name() != "Animation":
			push_warning("Unknown tag <", parser.get_node_name(), "> found while parsing <Animations> of anm2 file.")
			skip_element(parser)
			continue
		
		var anim_name := parser.get_named_attribute_value("Name")
		var frame_count := int(parser.get_named_attribute_value("FrameNum"))
		var should_loop := stob(parser.get_named_attribute_value("Loop"))
		var animation := _parse_anm2_animation(parser)
		
		res.add_animation(
			anim_name,
			_anm2_parsed_animation_to_animation(
				animation,
				should_loop,
				frame_count,
				anim_name,
			)
		)
	
	push_error("Unclosed <Animations> tag.")
	return AnimationLibrary.new()

## Parse an <Animation> element. Return a dictionary of layers: Dictionary[layer_id : int, frames : Array[_ANM2_Frame]]
## or an empty dictionary on error. 
func _parse_anm2_animation(parser : XMLParser) -> Dictionary[int, Array]:
	if parser.get_node_name() != "Animation":
		push_error("Expected an <Animation> tag.")
		return {}
	
	var res : Dictionary[int, Array] = {}
	while parser.read() != Error.ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT_END and parser.get_node_name() == "Animation":
			return res
		
		if parser.get_node_type() != XMLParser.NODE_ELEMENT:
			continue
		if parser.get_node_name() in ["NullAnimations", "Triggers", "RootAnimation"]:
			skip_element(parser)
			continue
		if parser.get_node_name() == "LayerAnimations":
			continue
		if parser.get_node_name() != "LayerAnimation":
			push_warning("Unknown tag <", parser.get_node_name(), "> found while parsing <Animations> of anm2 file.")
			skip_element(parser)
			continue
		
		var id := int(parser.get_named_attribute_value("LayerId"))
		var frames_data := read_array(parser, "Frame", [
			"XPosition", "YPosition",
			"XCrop", "YCrop", "Width", "Height",
			"XScale", "YScale",
			"Delay",
			"Rotation",
		])
		
		var frames : Array[_ANM2_Frame] = []
		for frame_data in frames_data:
			var frame_obj = _ANM2_Frame.new()
			frame_obj.pos        = Vector2(float(frame_data[0]), float(frame_data[1]))
			frame_obj.image_crop = Rect2i(int(frame_data[2])   , int(frame_data[3])  , int(frame_data[4]), int(frame_data[5]))
			frame_obj.scale      = Vector2(float(frame_data[6]), float(frame_data[7])) / 100		# scales are in porcents in the XML
			frame_obj.duration   = float(frame_data[8]) / 30	# we assume 30 frames = 1 second 
			frame_obj.rotation   = int(frame_data[9])
			frames.append(frame_obj)
		res.set(id, frames)
	
	push_error("Unclosed <Animation> tag.")
	return {}


# parsed: Dictionary[layer_id : int, frames : Array[_ANM2_Frame]]
## Takes whatever _parse_anm2_animation() returns and convert it to an Animation.
func _anm2_parsed_animation_to_animation(
		parsed : Dictionary[int, Array],
		should_loop : bool,
		frame_count : int,
		animation_name : String,
	) -> Animation:
	var expected_duration := frame_count / 30.0
	var res := Animation.new()
	res.loop_mode = int(should_loop) as Animation.LoopMode	# 0: does not loop, 1: does loop
	
	for layer_id in parsed.keys():
		var track_pos        := res.add_track(Animation.TYPE_VALUE)
		var track_image_crop := res.add_track(Animation.TYPE_VALUE)
		var track_scale      := res.add_track(Animation.TYPE_VALUE)
		var track_rotation   := res.add_track(Animation.TYPE_VALUE)
		
		var sprite_node_path :=  "Sprites/" + str(layer_id)
		res.track_set_path(track_pos		, sprite_node_path + ":position")
		res.track_set_path(track_image_crop	, sprite_node_path + ":texture:region")
		res.track_set_path(track_scale		, sprite_node_path + ":scale")
		res.track_set_path(track_rotation	, sprite_node_path + ":rotation")
		
		var time := 0.0
		for frame : _ANM2_Frame in parsed[layer_id]:
			res.track_insert_key(track_pos			, time, frame.pos)
			res.track_insert_key(track_image_crop	, time, frame.image_crop, 0)
			res.track_insert_key(track_scale		, time, frame.scale)
			res.track_insert_key(track_rotation		, time, frame.rotation)
			time += frame.duration
		res.length = time
		
		# there can be orphan <LayerAnimation> if there's no change
		if abs(time - expected_duration) > 0.01 and parsed[layer_id].size() != 0:
			push_warning("Incorrect duration for layer %d of animation '%s': %fs (actual) != %fs (expected)" % [layer_id, animation_name, time, expected_duration])
			# Warning because LostDeath (001.000_player.anm2, l1175) and other
			# have several inconstitencies in animation duration.
	return res
