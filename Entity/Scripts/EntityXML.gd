class_name EntityXML extends Resource

# https://wofsauge.github.io/IsaacDocs/rep/xml/entities2.html
var name : String
var id : int
var variant : int
var subtype : int
var anm2path : String
var base_hp : int
var is_boss : bool
var boss_id : int
var has_champion : bool
var collision_damage : float
var collision_mass : float
var hitbox_radius : float
var hitbox_radius_x_multi : float
var hitbox_radius_y_multi : float
var collision_interval : int    # in frames
# numGridCollisionPoints unused
var friction : float
# shadowSize unused
var stage_hp : int
# tags unused
var collision_mask : int	# gridCollision
# portrait unused
# hasFloorAlts unused
# reroll unused
# shutdoors unused
# shieldStrength unused
# gibAmount unused
# gibFlags unused
# bestiaryAnim unused
# bestiaryOverlay unused


# What no dataclass does to a man
func _init(
	name_ : String = "",
	id_ : int = 0,
	variant_ : int = 0,
	subtype_ : int = 0,
	anm2path_ : String = "",
	base_hp_ : int = 0,
	is_boss_ : bool = false,
	boss_id_ : int = 0,
	has_champion_ : bool = false,
	collision_damage_ : float = 0,
	collision_mass_ : float = 0,
	hitbox_radius_ : float = 0,
	hitbox_radius_x_multi_ : float = 0,
	hitbox_radius_y_multi_ : float = 0,
	collision_interval_ : int = 0,
	friction_ : float = 0,
	stage_hp_ : int = 0,
	collision_mask_ : int = 0
) -> void:
	name 					= name_
	id						= id_
	variant					= variant_
	subtype					= subtype_
	anm2path				= anm2path_
	base_hp					= base_hp_
	is_boss					= is_boss_
	boss_id					= boss_id_
	has_champion			= has_champion_
	collision_damage		= collision_damage_
	collision_mass			= collision_mass_
	hitbox_radius			= hitbox_radius_
	hitbox_radius_x_multi	= hitbox_radius_x_multi_
	hitbox_radius_y_multi	= hitbox_radius_y_multi_
	collision_interval		= collision_interval_ 
	friction				= friction_
	stage_hp				= stage_hp_
	collision_mask			= collision_mask_
