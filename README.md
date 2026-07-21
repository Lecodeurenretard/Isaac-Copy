# The copying of the Saac
[The Binding of Isaac](https://store.steampowered.com/app/250900/The_Binding_of_Isaac_Rebirth/) is my favorite game and since it's summer break, I wanted to recreate it. Every asset (graphic, SFX, music) is taken from the game's files.

## Completion
I'm currently working on implementing room layouts. Next will be Isaac and his tears.

## Goals
### Main goals
The project is not completed until they are all reached.

+ Pickups
	- Keys (basic & golden)
	- Coins (pennies, lucky pennies, nickels, dimes)
+ Floor generation
	- The only special rooms implemented will be the Treasure room, the Shop and Libraries.
+ Seed system (except special ones)
+ Basic enemy AI
+ A few bosses
	- Monstro
	- Larry Jr.
	- Duke of Flies
	- Lokii
+ Basic items
	- Stat ups
	- Dice: D4, Eternal D6, D6, Spindown
+ The first three chapters (excluding Mom bossfight)
+ SFX

The general rule is "it has to _feel_ the same as in the base game".

### Auxiliary goals
If I have time, I might implement those.

+ Add bombs.
+ Music layering system
+ Some shaders
+ Curses
+ Lua API for
	- items
	- Bosses
+ The Alternative Path
+ More characters
	- The Lost
	- Magladene
	- Eve
	- Eden

## Sources
There is surprisingly little documentation on some features. If you want to do the same as me, this section can spare you some research.

### Room layout files
In [rooms](resources/rooms/) there is .stb files, those are room layouts. You can avoid parsing them yourself by using [Basement Renovator]() to convert them to XML, just import them and the corresponding XML will be automatically generated next to the original file.  
If you are willing to spend a little more time, said project provides [a specification](https://github.com/Basement-Renovator/basement-renovator/blob/main/resources/Notes/Room%20Format.txt).

<!--
```Rust
struct STBFile {
	magic_bytes : [char; 4],		// always set to "STB1"
	room_count : u32	// length of rooms[]
	rooms : Vec<Room>
}

struct Room {
	type_room : u32,
	variant : u32, 		// also called ID
	sub_type : u32,
	difficulty : u8,	// the only observed values are 1, 5, 10, 15, 20
	room_name_len : u16,
	room_name : String,
	weight : f32,		// typically set to 1.0
	
	// in tiles excluding walls
	// have to match the shape
	width : u8,			// 5 for thin, 13 for regular and 26 for large
	height : u8,		// 3 for thin, 7 for regular and 14 for large
	shape : Shape,
	
	door_count : u8,	// length of doors[]
	entity_count : u16,	// length of entites[]
	doors : Vec<Door>,
	entities : Vec<Entity>
}

enum Shape {
	REG_REG = 1,
	REG_THIN = 2,
	THIN_MED = 3,
	REG_LARGE = 4,
	THIN_LARGE = 5,
	LARGE_REG = 6,
	LARGE_THIN = 7,
	LARGE_LARGE = 8,
	L_MIRRORED = 9,
	L = 10,
	R_MIRRORED = 11,	# r shaped
	R = 12,
}

struct Door {
	x : i16,
	y : i16,
	exists : u8,	// this field is a boolean. 0 = false any other value is true
}

struct Entity {
	x : i16,
	y : i16,
	count : u8, 	// length of at_pos[]
	at_pos : Vec<SingularEntity>
}

// If multiple entities are stacked, pick one at random.
struct SingularEntity {
	type : u16,
	variant : u16,
	subtype : u16,
	weight : float,
}
```
-->

Entities with no animations are not listed in [entities2.xml](resources/entities2.xml).
Here are the most common:
- Rocks
- Pits
- Blocks
- Pots
- Skulls
- Poops
- Spikes
- Floor decorations (listed as Props in [id_list.md](doc/id_list.md))

### Entity ID list
I made [a script](doc/generate_ID_list) that generate the list from [Basement Renovator](https://github.com/Basement-Renovator/basement-renovator/blob/main/resources/)'s internal XML files: [doc/id_list.md](doc/id_list.md).