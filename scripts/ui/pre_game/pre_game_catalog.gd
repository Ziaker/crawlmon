class_name PreGameCatalog
extends RefCounted
## 1:1 Pre-Game data source (D-1207 / D-1208).
##
## The Selection, Nature and Menu screens read everything they show from here.
## Move mechanics stay in MoveCatalog / Skill (D-1079); this file keeps the
## presentation copy and the pre-game constants only. English only (D-413 /
## D-1085), static typing throughout, explicit paths (never a folder scan).

const PortraitIcons = preload("res://scripts/ui/portrait_icon.gd")
const MoveIcons = preload("res://scripts/ui/move_icons.gd")

## DQT species have no face crop in PortraitIcons; use the full Sugimori art.
const DQT_PORTRAIT_PATHS: Dictionary = {
	"dqt_slime": "res://sugimori/dqt_web/fandom/DQVIII_Slime.png",
	"dqt_orc": "res://sugimori/dqt_web/fandom/DQVIII_Orc.png",
	"dqt_cyclops": "res://sugimori/dqt_web/fandom/DQVIII_Cyclops.png",
}

const NATURE_ORDER: Array[String] = [
	"hardy", "docile", "brave", "timid", "modest", "calm", "jolly", "adamant",
	"bold", "impish", "relaxed", "hasty", "naive", "rash", "quiet", "careful", "lonely", "quirky",
]

## D-1207 / D-1208: all six protagonists are unlocked from the first screen.
const SPECIES_ORDER: Array[String] = ["abra", "pancham", "gible", "dqt_slime", "dqt_orc", "dqt_cyclops"]

const STAT_ORDER: Array[String] = ["STR", "MAG", "VIT", "WIS", "AGI", "LUK"]

## Skill.Kind order (D-1079): 0 melee, 1 projectile, 2 cast, 3 status.
const MOVE_RANGE_KEYS: Array[String] = ["melee", "projectile", "cast", "status"]

const PURE_NATURES: Array[String] = ["hardy", "docile"]

const MENU_IDS: Array[String] = ["play", "settings", "credits", "quit"]

const NATURE_DESCRIPTIONS: Dictionary = {
	"hardy": "Balanced baseline with unaltered attributes and steady tactical weighting.",
	"docile": "Measured discipline that conserves an extra ATB margin before committing.",
	"brave": "Frontline brawl posture favoring heavy Strength and durability over speed.",
	"timid": "Skirmisher instinct maximizing ATB rhythm, luck checks, and spacing.",
	"modest": "Arcane specialization that grows magic at the expense of physical strength.",
	"calm": "Defensive focus that grows the MP pool and magical mitigation, acting with patience.",
	"jolly": "High-tempo physical flanker prioritizing ATB velocity and crit/dodge odds.",
	"adamant": "Pure kinetic striker that grows raw strength at the cost of magic and luck, committed to crushing single targets.",
	"bold": "Holds the line and outlasts the enemy.",
	"impish": "Takes the hit on purpose and grins about it.",
	"relaxed": "Never rushes; acts late and stays standing.",
	"hasty": "Acts first and thinks later.",
	"naive": "Charges in with no fear of tricks.",
	"rash": "Casts the moment it can, whatever the cost.",
	"quiet": "Waits, stores power and answers once.",
	"careful": "Leaves nothing to chance.",
	"lonely": "Fights alone, hits hard, guards nothing.",
	"quirky": "Bets everything on the lucky hit.",
}

## Species sheet used by the Selection cards, the Nature preview and the 3D Hub.
## `elements` and `affinities` use the Element.Type / Affinity.Type ints.
static var SPECIES_META: Dictionary = {
	"abra": {
		"height": 2.00,
		"glb_path": "res://assets/modelos/abra/abra.glb",
		"origin": "Pokemon Z-up (2.5x)",
		"color": Color("dfc980"),
		"accent": Color("ff746c"),
		"elements": [4],
		"starter_moves": ["tackle", "confusao", "raio_psiquico"],
		"raw_stats": {"STR": 20, "MAG": 105, "VIT": 15, "WIS": 55, "AGI": 90, "LUK": 57},
		"affinities": {3: 1, 4: 2, 6: 1, 10: 1, 11: 1},
		"learn_tree": [
			{"level": 1, "move": "tackle", "tag": "Basic"},
			{"level": 1, "move": "confusao", "tag": "Starter"},
			{"level": 1, "move": "raio_psiquico", "tag": "Starter"},
			{"level": 10, "move": "onda_choque", "tag": "Coverage"},
			{"level": 10, "move": "teleporte_rapido", "tag": "Mobility"},
			{"level": 20, "move": "media", "tag": "Support"},
			{"level": 20, "move": "sukunda", "tag": "Control"},
			{"level": 20, "move": "megido", "tag": "Signature"},
		],
		"passive_summary": "Arcane Glass Cannon — prioritizes elemental weakness hits, rapid ATB cycles & MP conservation.",
		"pending_ability": "PENDING SPECIES ABILITY: Psychic Surge / Synchronize scaling awaiting creator balancing.",
	},
	"pancham": {
		"height": 1.85,
		"glb_path": "res://assets/modelos/pancham/pancham.glb",
		"origin": "Pokemon Z-up (2.5x)",
		"color": Color("f4eee1"),
		"accent": Color("d6fa66"),
		"elements": [0, 10],
		"starter_moves": ["tackle", "soco_rapido", "golpe_carate"],
		"raw_stats": {"STR": 82, "MAG": 46, "VIT": 62, "WIS": 48, "AGI": 43, "LUK": 56},
		"affinities": {4: 1, 5: 2, 10: 2},
		"learn_tree": [
			{"level": 1, "move": "tackle", "tag": "Basic"},
			{"level": 1, "move": "soco_rapido", "tag": "Starter"},
			{"level": 1, "move": "golpe_carate", "tag": "Starter"},
			{"level": 10, "move": "quebra_telha", "tag": "Guard Break"},
			{"level": 10, "move": "provocacao", "tag": "Control"},
			{"level": 20, "move": "tarukaja", "tag": "Buff"},
			{"level": 20, "move": "hassou_tobi", "tag": "Signature"},
		],
		"passive_summary": "Pocket Brawler — excels at close-range pressure, Guard shattering & physical tempo.",
		"pending_ability": "PENDING SPECIES ABILITY: Iron Fist / Mold Breaker strike passive awaiting creator approval.",
	},
	"gible": {
		"height": 1.70,
		"glb_path": "res://assets/modelos/gible/gible.glb",
		"origin": "Pokemon Z-up (2.5x)",
		"color": Color("38bdf8"),
		"accent": Color("ff746c"),
		"elements": [7],
		"starter_moves": ["tackle", "mordida", "tiro_areia"],
		"raw_stats": {"STR": 70, "MAG": 40, "VIT": 45, "WIS": 45, "AGI": 42, "LUK": 48},
		"affinities": {0: 2, 2: 1, 5: 2, 10: 2},
		"learn_tree": [
			{"level": 1, "move": "tackle", "tag": "Basic"},
			{"level": 1, "move": "mordida", "tag": "Starter"},
			{"level": 1, "move": "tiro_areia", "tag": "Starter"},
			{"level": 10, "move": "investida_escavadora", "tag": "Lunge"},
			{"level": 10, "move": "garra_dragao", "tag": "Melee"},
			{"level": 10, "move": "rakunda", "tag": "Debuff"},
			{"level": 20, "move": "furia_dragao", "tag": "AoE"},
			{"level": 20, "move": "mabufula", "tag": "Coverage"},
			{"level": 20, "move": "titanomachia", "tag": "Signature"},
		],
		"passive_summary": "Ambush Hunter — combines Sand Attack blind openings with subterranean lunges & AoE finishes.",
		"pending_ability": "PENDING SPECIES ABILITY: Sand Veil evasion boost & Rough Skin tick awaiting creator sign-off.",
	},
	"dqt_slime": {
		"name": "Slime",
		"height": 1.40,
		"glb_path": "res://assets/modelos/dqt_slime/dqt_slime.glb",
		"origin": "DQT Y-up (1.40m)",
		"color": Color("63d9ec"),
		"accent": Color("d6fa66"),
		"elements": [2],
		"starter_moves": ["tackle", "bubble_shot", "heal"],
		"raw_stats": {"STR": 25, "MAG": 25, "VIT": 25, "WIS": 20, "AGI": 35, "LUK": 26},
		"affinities": {1: 1, 2: 2, 3: 1, 5: 2},
		"learn_tree": [
			{"level": 1, "move": "tackle", "tag": "Basic"},
			{"level": 1, "move": "bubble_shot", "tag": "Starter"},
			{"level": 1, "move": "heal", "tag": "Starter"},
			{"level": 10, "move": "electric_beam", "tag": "Coverage"},
			{"level": 10, "move": "tidal_surge", "tag": "Water Art"},
			{"level": 20, "move": "bubble_shield", "tag": "Team Shield"},
		],
		"passive_summary": "Compact Hydro Support — starts with Bubble Shot + Heal to skirmish & sustain allies early.",
		"pending_ability": "PENDING SPECIES ABILITY: Elastic Body knockback dampener awaiting creator spec.",
	},
	"dqt_orc": {
		"name": "Orc",
		"height": 2.10,
		"glb_path": "res://assets/modelos/dqt_orc/dqt_orc.glb",
		"origin": "DQT Y-up (2.10m)",
		"color": Color("4ade80"),
		"accent": Color("f97316"),
		"elements": [0],
		"starter_moves": ["tackle", "spear_thrust", "drain_spear"],
		"raw_stats": {"STR": 95, "MAG": 30, "VIT": 85, "WIS": 35, "AGI": 60, "LUK": 61},
		"affinities": {0: 2, 3: 1, 4: 1, 6: 1, 7: 2, 10: 2},
		"learn_tree": [
			{"level": 1, "move": "tackle", "tag": "Basic"},
			{"level": 1, "move": "spear_thrust", "tag": "Starter"},
			{"level": 1, "move": "drain_spear", "tag": "Starter"},
			{"level": 10, "move": "javelin_throw", "tag": "Ranged"},
			{"level": 10, "move": "armored_bulk", "tag": "Defense"},
			{"level": 20, "move": "war_cry", "tag": "Interrupt"},
		],
		"passive_summary": "Spear Warden — (+0.45m reach), steals positive badges/shields with Drain Spear and anchors the line.",
		"pending_ability": "PENDING SPECIES ABILITY: Spear Reach & War-Horn poise threshold awaiting creator confirmation.",
	},
	"dqt_cyclops": {
		"name": "Cyclops",
		"height": 3.22,
		"glb_path": "res://assets/modelos/dqt_cyclops/dqt_cyclops.glb",
		"origin": "DQT Y-up (3.22m)",
		"color": Color("f97316"),
		"accent": Color("ff746c"),
		"elements": [0, 7],
		"starter_moves": ["tackle", "boulder_smash", "rock_throw"],
		"raw_stats": {"STR": 110, "MAG": 20, "VIT": 75, "WIS": 25, "AGI": 40, "LUK": 54},
		"affinities": {0: 2, 4: 1, 7: 2, 9: 1, 10: 2},
		"learn_tree": [
			{"level": 1, "move": "tackle", "tag": "Basic"},
			{"level": 1, "move": "boulder_smash", "tag": "Starter"},
			{"level": 1, "move": "rock_throw", "tag": "Starter"},
			{"level": 10, "move": "glare", "tag": "Status"},
			{"level": 20, "move": "armored_bulk", "tag": "Defense"},
		],
		"passive_summary": "Siege Titan — (+0.80m reach) delivers crushing physical blows with massive frame presence.",
		"pending_ability": "PENDING SPECIES ABILITY: Titan Stride & Unflinching Slam multipliers awaiting creator approval.",
	},
}

## Presentation copy for all 35 Moves. Numbers here are the sheet numbers the
## Menu/Selection cards show; mechanics still come from MoveData (D-1079).
## `elem`, `kind` and `dmg_type` use Element.Type, Skill.Kind and MoveData.DamageType.
static var MOVE_PRESENTATION: Dictionary = {
	"tackle": {
		"name": "Tackle", "elem": 0, "kind": 0, "dmg_type": 0, "power": 1.0,
		"atb": 2, "mp": 0, "aoe": false, "windup": 0.65,
		"visuals": "Crisp linear kinetic impact burst.",
		"motion": "Direct body check forward.",
		"text": "Reliable basic physical strike. Single Target.",
	},
	"confusao": {
		"name": "Confusion", "elem": 4, "kind": 1, "dmg_type": 1, "power": 1.4,
		"atb": 2, "mp": 3, "aoe": false, "windup": 1.50,
		"visuals": "Swirling violet distortions and concentric telekinetic ripples warp the surrounding air before condensing into an erratic orb.",
		"motion": "Stationary cast. Attacker channels spatial energy and launches an erratic curved homing bolt.",
		"text": "Disrupts mental focus with erratic psychic pressure. Single Target burst.",
	},
	"raio_psiquico": {
		"name": "Psybeam", "elem": 4, "kind": 1, "dmg_type": 1, "power": 1.7,
		"atb": 3, "mp": 5, "aoe": false, "windup": 1.65,
		"visuals": "Refracted magenta-cyan rings stack ahead of the caster before firing a chromatic beam.",
		"motion": "Linear beam anchored between caster and target AABB center.",
		"text": "High-velocity psychic laser that pierces barriers. Single Target.",
	},
	"onda_choque": {
		"name": "Shock Wave", "elem": 3, "kind": 2, "dmg_type": 1, "power": 1.3,
		"atb": 2, "mp": 3, "aoe": false, "windup": 1.10,
		"visuals": "Jagged golden arcs discharge across the arena floor.",
		"motion": "Fast mid-range electrical sweep tracking target lane.",
		"text": "Electrical discharge arcing into the opponent. Single Target.",
	},
	"teleporte_rapido": {
		"name": "Teleport", "elem": 4, "kind": 0, "dmg_type": 1, "power": 0.7,
		"atb": 1, "mp": 3, "aoe": false, "windup": 0.45, "type_override": "dodge",
		"visuals": "Afterimage smear fades in cyan/magenta as caster blinks.",
		"motion": "Instant spatial warp placing caster behind opponent.",
		"text": "User becomes untargetable during execution, striking safely. Single Target.",
	},
	"media": {
		"name": "Media", "elem": 9, "kind": 3, "dmg_type": 0, "power": 0.0,
		"atb": 2, "mp": 4, "aoe": true, "windup": 1.25,
		"visuals": "Soft golden light pillars descend on all allied positions.",
		"motion": "Radial team sanctuary halo.",
		"text": "Restores missing HP to all living allies based on Wisdom (WIS). Team AoE.",
	},
	"sukunda": {
		"name": "Sukunda", "elem": 11, "kind": 3, "dmg_type": 0, "power": 0.0,
		"atb": 1, "mp": 7, "aoe": false, "windup": 0.90,
		"visuals": "Teal glyph lock contracts around enemy limbs.",
		"motion": "Sigil projection under target feet.",
		"text": "Reduces target Speed (-1 SPD stage), slowing ATB accumulation. Single Target.",
	},
	"megido": {
		"name": "Megido", "elem": 11, "kind": 1, "dmg_type": 1, "power": 1.6,
		"atb": 3, "mp": 6, "aoe": true, "windup": 2.00,
		"visuals": "Transcendent mystic sigils bloom across the sky before nuclear flash.",
		"motion": "Arena-wide vertical detonation.",
		"text": "Transcendent explosion hitting all enemies, bypassing resistances. Full AoE.",
	},
	"soco_rapido": {
		"name": "Mach Punch", "elem": 0, "kind": 0, "dmg_type": 0, "power": 0.5,
		"atb": 1, "mp": 1, "aoe": false, "windup": 0.40,
		"visuals": "White shock-cone bursts around the striking fist.",
		"motion": "Instant close-range dash jab.",
		"text": "Lightning jab designed to interrupt enemy wind-ups. Single Target.",
	},
	"golpe_carate": {
		"name": "Karate Chop", "elem": 0, "kind": 0, "dmg_type": 0, "power": 1.5,
		"atb": 2, "mp": 3, "aoe": false, "windup": 1.00,
		"visuals": "Sharp red-trailed vertical slash cleanly cleaves target.",
		"motion": "Forward melee sprint with sharp vertical chop.",
		"text": "Direct martial chop with elevated critical strike chance. Single Target.",
	},
	"quebra_telha": {
		"name": "Brick Break", "elem": 0, "kind": 0, "dmg_type": 0, "power": 1.8,
		"atb": 3, "mp": 4, "aoe": false, "windup": 1.35,
		"visuals": "Amber shockwave shatters hexagonal guard barriers on impact.",
		"motion": "Heavy overhead lunge breaking guard stance.",
		"text": "Shatters Guard stances and refunds 1 ATB upon success. Single Target.",
	},
	"provocacao": {
		"name": "Taunt", "elem": 0, "kind": 3, "dmg_type": 0, "power": 0.0,
		"atb": 1, "mp": 1, "aoe": false, "windup": 0.60,
		"visuals": "Coral aggro chevron locks onto target.",
		"motion": "Stationary stance command.",
		"text": "Forces target to focus next attack exclusively on user. Single Target.",
	},
	"tarukaja": {
		"name": "Tarukaja", "elem": 11, "kind": 3, "dmg_type": 0, "power": 0.0,
		"atb": 2, "mp": 10, "aoe": true, "windup": 1.15,
		"visuals": "Rising amber embers circle all allies.",
		"motion": "Stationary party buff wave.",
		"text": "Increases Attack (+1 ATK stage) for all allies until battle ends. Team AoE.",
	},
	"hassou_tobi": {
		"name": "Hassou Tobi", "elem": 0, "kind": 0, "dmg_type": 0, "power": 1.4,
		"atb": 3, "mp": 6, "aoe": true, "windup": 1.70,
		"visuals": "Eight crisscrossed silver arcs slice through the whole enemy line.",
		"motion": "Aerial multi-target dash sequence.",
		"text": "Flurry of rapid leaping slashes striking all enemies. Full AoE.",
	},
	"mordida": {
		"name": "Bite", "elem": 10, "kind": 0, "dmg_type": 0, "power": 1.3,
		"atb": 2, "mp": 3, "aoe": false, "windup": 0.85,
		"visuals": "Violet shadowy jaws snap shut around target center.",
		"motion": "Close lunge clamp.",
		"text": "Vicious dark clamp destabilizing enemy morale. Single Target.",
	},
	"tiro_areia": {
		"name": "Sand Attack", "elem": 7, "kind": 1, "dmg_type": 0, "power": 0.0,
		"atb": 1, "mp": 2, "aoe": false, "windup": 0.70,
		"visuals": "Conical ochre sand spray billows across target eye level.",
		"motion": "Low directional dust jet.",
		"text": "Blinds target for 4s, imposing a 35% miss chance. Single Target.",
	},
	"furia_dragao": {
		"name": "Dragon Rage", "elem": 0, "kind": 1, "dmg_type": 0, "power": 1.6,
		"atb": 3, "mp": 5, "aoe": false, "windup": 1.45,
		"visuals": "Roaring crimson-blue draconic sphere erupts across the field.",
		"motion": "Projectile detonation with splash ring.",
		"text": "Explosive dragon breath detonating into team-wide splash damage.",
	},
	"investida_escavadora": {
		"name": "Dig", "elem": 7, "kind": 0, "dmg_type": 0, "power": 1.5,
		"atb": 2, "mp": 3, "aoe": false, "windup": 1.40,
		"visuals": "Debris eruption + vertical seismic dust column beneath target.",
		"motion": "Subterranean approach and eruptive uppercut.",
		"text": "Direct strike on single target with seismic knock-up.",
	},
	"garra_dragao": {
		"name": "Dragon Claw", "elem": 0, "kind": 0, "dmg_type": 0, "power": 1.6,
		"atb": 3, "mp": 4, "aoe": false, "windup": 1.15,
		"visuals": "Twin teal energy claws tear forward in X-pattern.",
		"motion": "Fast diagonal cleave.",
		"text": "Twin draconic energy claws rending enemy armor. Single Target.",
	},
	"rakunda": {
		"name": "Rakunda", "elem": 11, "kind": 3, "dmg_type": 0, "power": 0.0,
		"atb": 1, "mp": 7, "aoe": false, "windup": 0.90,
		"visuals": "Inverted coral armor crack glyph.",
		"motion": "Remote debuff mark.",
		"text": "Reduces target Defense (-1 DEF stage) until battle ends. Single Target.",
	},
	"mabufula": {
		"name": "Mabufula", "elem": 2, "kind": 2, "dmg_type": 0, "power": 1.35,
		"atb": 2, "mp": 5, "aoe": true, "windup": 1.35,
		"visuals": "Crystalline frost needles erupt under all foes.",
		"motion": "Multi-lane glacial crystal burst.",
		"text": "Glacial ice storm summoning blizzards beneath all opponents. Full AoE.",
	},
	"titanomachia": {
		"name": "Titanomachia", "elem": 7, "kind": 0, "dmg_type": 0, "power": 1.5,
		"atb": 3, "mp": 6, "aoe": true, "windup": 1.80,
		"visuals": "Massive basalt monoliths shatter upward across the floor.",
		"motion": "Full-ground tectonic upheaval.",
		"text": "Cataclysmic ground eruption shattering floor under all enemies. Full AoE.",
	},
	"bubble_shot": {
		"name": "Bubble Shot", "elem": 2, "kind": 1, "dmg_type": 1, "power": 1.0,
		"atb": 2, "mp": 3, "aoe": false, "windup": 0.75,
		"visuals": "Refractive cyan sphere pops into mist droplets.",
		"motion": "Arced water projectile.",
		"text": "Fast, cheap single-target Water damage.",
	},
	"heal": {
		"name": "Heal", "elem": 11, "kind": 3, "dmg_type": 0, "power": 0.0,
		"atb": 2, "mp": 3, "aoe": false, "windup": 0.95,
		"visuals": "Warm upward chime motes around selected ally.",
		"motion": "Single-ally mend.",
		"text": "Restores missing HP to a selected friendly target. Single Target.",
	},
	"electric_beam": {
		"name": "Electric Beam", "elem": 3, "kind": 1, "dmg_type": 1, "power": 1.0,
		"atb": 2, "mp": 6, "aoe": false, "windup": 1.15,
		"visuals": "Linear yellow plasma arc crackling cleanly.",
		"motion": "Instant bolt line.",
		"text": "Single-target magical strike. 20% + LUK chance to STUN for 4s.",
	},
	"tidal_surge": {
		"name": "Tidal Surge", "elem": 2, "kind": 1, "dmg_type": 1, "power": 1.0,
		"atb": 2, "mp": 5, "aoe": false, "windup": 1.10,
		"visuals": "Ricocheting crest wave chains across enemy formation.",
		"motion": "Chain-bouncing surge.",
		"text": "Bounces up to two more living enemies (75% / 50%) on hit.",
	},
	"bubble_shield": {
		"name": "Bubble Shield", "elem": 2, "kind": 3, "dmg_type": 0, "power": 0.0,
		"atb": 3, "mp": 4, "aoe": true, "windup": 1.10,
		"visuals": "Fresnel cyan dome absorbs incoming force before bursting.",
		"motion": "Team-wide barrier cast.",
		"text": "Untyped shield on all allies absorbing damage before HP for 8s.",
	},
	"spear_thrust": {
		"name": "Spear Thrust", "elem": 0, "kind": 0, "dmg_type": 0, "power": 1.3,
		"atb": 2, "mp": 3, "aoe": false, "windup": 0.90,
		"visuals": "White wind-cone piercing along spear vector.",
		"motion": "Extended linear lunge.",
		"text": "Direct linear thrust with extended melee reach. Single Target.",
	},
	"drain_spear": {
		"name": "Drain Spear", "elem": 0, "kind": 0, "dmg_type": 0, "power": 1.0,
		"atb": 2, "mp": 3, "aoe": false, "windup": 1.05,
		"visuals": "Siphoning ribbon returns energy back to attacker.",
		"motion": "Piercing strike with return drain arc.",
		"text": "Steals shields and buffs before dealing piercing damage.",
	},
	"javelin_throw": {
		"name": "Javelin Throw", "elem": 0, "kind": 1, "dmg_type": 0, "power": 1.2,
		"atb": 2, "mp": 5, "aoe": false, "windup": 1.00,
		"visuals": "High-velocity steel trail piercing through air.",
		"motion": "Ballistic thrown spear.",
		"text": "Long-range throw; crit chance rises as the target loses HP.",
	},
	"war_cry": {
		"name": "War Cry", "elem": 0, "kind": 3, "dmg_type": 0, "power": 0.0,
		"atb": 3, "mp": 3, "aoe": true, "windup": 0.90,
		"visuals": "Expanding circular sonic shockwave rings.",
		"motion": "Radial roar blast.",
		"text": "Interrupts enemies in wind-up; +1 Burst if at least one is broken.",
	},
	"armored_bulk": {
		"name": "Armored Bulk", "elem": 7, "kind": 3, "dmg_type": 0, "power": 0.0,
		"atb": 1, "mp": 10, "aoe": false, "windup": 0.70,
		"visuals": "Amber metallic plates flash across posture.",
		"motion": "Stationary brace stance.",
		"text": "Gains ARMOR (8 s): first Move hit causes no interruption or knockback.",
	},
	"boulder_smash": {
		"name": "Boulder Smash", "elem": 0, "kind": 0, "dmg_type": 0, "power": 1.2,
		"atb": 2, "mp": 4, "aoe": false, "windup": 1.30,
		"visuals": "Earth fragments scatter radially on impact.",
		"motion": "Heavy overhead clubbing smash.",
		"text": "Crushing seismic strike with staggering impact. Single Target.",
	},
	"rock_throw": {
		"name": "Rock Throw", "elem": 7, "kind": 1, "dmg_type": 0, "power": 1.3,
		"atb": 2, "mp": 3, "aoe": false, "windup": 1.00,
		"visuals": "Tumbling boulder slab skims low ground dust.",
		"motion": "Low projectile toss.",
		"text": "Ground-skimming rock projectile striking low-profile defenses.",
	},
	"glare": {
		"name": "Glare", "elem": 10, "kind": 3, "dmg_type": 0, "power": 0.0,
		"atb": 1, "mp": 3, "aoe": false, "windup": 0.75,
		"visuals": "Sharp violet eye-flash beams lock target posture.",
		"motion": "Instant gaze line.",
		"text": "Hypnotic serpentine gaze that paralyzes target momentum.",
	},
}

## Layer 3 combo table, verbatim: 6 species x 18 Natures = 108 entries.
## Format: "base combos / EV combos [min..max]".
static var COMBO_EV_TABLE: Dictionary = {
	"abra": {
		"hardy": "15 / 16.75 [7..33]",
		"docile": "15 / 16.75 [7..33]",
		"brave": "15 / 16.44 [7..33]",
		"timid": "18 / 18.94 [9..33]",
		"modest": "17 / 18.25 [10..33]",
		"calm": "18 / 18.50 [7..33]",
		"jolly": "15 / 16.81 [8..33]",
		"adamant": "15 / 16.56 [6..33]",
		"bold": "17 / 17.62 [7..33]",
		"impish": "15 / 16.25 [6..33]",
		"relaxed": "15 / 16.62 [7..33]",
		"hasty": "17 / 18.56 [10..33]",
		"naive": "17 / 18.19 [9..33]",
		"rash": "17 / 18.56 [10..33]",
		"quiet": "15 / 17.19 [9..33]",
		"careful": "15 / 16.94 [7..33]",
		"lonely": "17 / 17.94 [7..33]",
		"quirky": "18 / 18.56 [8..33]",
	},
	"pancham": {
		"hardy": "15 / 16.06 [6..33]",
		"docile": "15 / 16.06 [6..33]",
		"brave": "17 / 17.81 [8..33]",
		"timid": "15 / 16.25 [6..33]",
		"modest": "15 / 16.44 [7..33]",
		"calm": "15 / 16.38 [6..33]",
		"jolly": "17 / 17.44 [6..33]",
		"adamant": "16 / 17.44 [9..33]",
		"bold": "15 / 16.62 [8..33]",
		"impish": "17 / 17.62 [7..33]",
		"relaxed": "17 / 17.62 [7..33]",
		"hasty": "15 / 16.75 [7..33]",
		"naive": "17 / 17.62 [7..33]",
		"rash": "17 / 17.44 [6..33]",
		"quiet": "17 / 17.44 [6..33]",
		"careful": "16 / 17.19 [7..33]",
		"lonely": "15 / 17.00 [9..33]",
		"quirky": "15 / 16.44 [7..33]",
	},
	"gible": {
		"hardy": "15 / 16.06 [6..33]",
		"docile": "15 / 16.06 [6..33]",
		"brave": "17 / 17.69 [8..33]",
		"timid": "15 / 16.38 [6..33]",
		"modest": "15 / 16.44 [7..33]",
		"calm": "15 / 16.25 [6..33]",
		"jolly": "17 / 17.56 [6..33]",
		"adamant": "16 / 17.25 [9..33]",
		"bold": "15 / 16.44 [7..33]",
		"impish": "17 / 17.56 [6..33]",
		"relaxed": "17 / 17.44 [6..33]",
		"hasty": "16 / 17.19 [7..33]",
		"naive": "17 / 17.62 [7..33]",
		"rash": "17 / 17.44 [6..33]",
		"quiet": "17 / 17.44 [6..33]",
		"careful": "16 / 17.00 [7..33]",
		"lonely": "16 / 17.44 [9..33]",
		"quirky": "16 / 17.06 [8..33]",
	},
	"dqt_slime": {
		"hardy": "15 / 15.94 [6..33]",
		"docile": "15 / 15.94 [6..33]",
		"brave": "16 / 16.88 [7..33]",
		"timid": "16 / 17.00 [7..33]",
		"modest": "15 / 16.44 [7..33]",
		"calm": "16 / 16.69 [6..33]",
		"jolly": "17 / 17.62 [7..33]",
		"adamant": "16 / 17.06 [8..33]",
		"bold": "15 / 16.44 [7..33]",
		"impish": "17 / 17.44 [6..33]",
		"relaxed": "16 / 16.69 [6..33]",
		"hasty": "16 / 17.25 [8..33]",
		"naive": "17 / 17.62 [7..33]",
		"rash": "17 / 17.44 [6..33]",
		"quiet": "16 / 16.69 [6..33]",
		"careful": "16 / 16.88 [7..33]",
		"lonely": "16 / 17.25 [8..33]",
		"quirky": "16 / 17.06 [8..33]",
	},
	"dqt_orc": {
		"hardy": "15 / 16.56 [6..33]",
		"docile": "15 / 16.56 [6..33]",
		"brave": "17 / 18.38 [9..33]",
		"timid": "15 / 16.88 [6..33]",
		"modest": "15 / 16.56 [6..33]",
		"calm": "15 / 16.62 [7..33]",
		"jolly": "18 / 18.62 [6..33]",
		"adamant": "17 / 18.19 [9..33]",
		"bold": "15 / 17.19 [9..33]",
		"impish": "18 / 18.88 [8..33]",
		"relaxed": "17 / 18.00 [8..33]",
		"hasty": "16 / 17.19 [7..33]",
		"naive": "18 / 18.69 [7..33]",
		"rash": "18 / 18.19 [6..33]",
		"quiet": "17 / 17.44 [6..33]",
		"careful": "17 / 17.56 [6..33]",
		"lonely": "16 / 17.44 [9..33]",
		"quirky": "15 / 16.81 [8..33]",
	},
	"dqt_cyclops": {
		"hardy": "15 / 16.62 [7..33]",
		"docile": "15 / 16.62 [7..33]",
		"brave": "17 / 18.38 [9..33]",
		"timid": "15 / 16.56 [6..33]",
		"modest": "15 / 16.44 [6..33]",
		"calm": "15 / 16.25 [6..33]",
		"jolly": "18 / 18.69 [7..33]",
		"adamant": "17 / 18.25 [10..33]",
		"bold": "15 / 17.00 [8..33]",
		"impish": "18 / 18.88 [8..33]",
		"relaxed": "17 / 18.00 [8..33]",
		"hasty": "16 / 17.56 [8..33]",
		"naive": "18 / 18.75 [8..33]",
		"rash": "18 / 18.25 [7..33]",
		"quiet": "17 / 17.50 [7..33]",
		"careful": "17 / 17.62 [7..33]",
		"lonely": "16 / 17.81 [10..33]",
		"quirky": "15 / 17.12 [8..33]",
	},
}

static var MENU_ITEMS: Array[Dictionary] = [
	{"id": "play", "label": "PLAY", "tag": "CAMPAIGN", "kicker": "EXPEDITION ENTRY", "desc": "Start a new expedition or continue from valid persistence.", "enabled": true},
	{"id": "settings", "label": "SETTINGS", "tag": "5 TABS", "kicker": "SYSTEM CONFIGURATION", "desc": "Video, audio, controls, gameplay, and accessibility preferences.", "enabled": true},
	{"id": "credits", "label": "CREDITS", "tag": "INFO", "kicker": "PRODUCTION & INPUTS", "desc": "Engine specification, HUD heritage, and input bindings.", "enabled": true},
	{"id": "quit", "label": "QUIT GAME", "tag": "EXIT", "kicker": "DESKTOP", "desc": "Close the application safely with confirmation.", "enabled": true},
]

## Settings rows rendered 1:1 by the Settings view (tab -> ordered row array).
## `type` is "cycle" (opts + idx), "slider" (val + unit) or "key" (val).
const SETTINGS_TAB_ORDER: Array[String] = ["VIDEO", "AUDIO", "CONTROLS", "GAMEPLAY", "ACCESSIBILITY"]

const DEFAULT_SETTINGS: Dictionary = {
	"VIDEO": [
		{"key": "mode", "name": "Window Mode", "sub": "DisplayServer presentation", "type": "cycle", "opts": ["Windowed", "Borderless", "Fullscreen"], "idx": 0},
		{"key": "res", "name": "Resolution", "sub": "Target viewport size", "type": "cycle", "opts": ["1280x720", "1600x900", "1920x1080"], "idx": 0},
		{"key": "vsync", "name": "VSync", "sub": "Synchronize frames with monitor", "type": "cycle", "opts": ["Enabled", "Disabled"], "idx": 0},
		{"key": "fps", "name": "FPS Cap", "sub": "Engine.max_fps ceiling", "type": "cycle", "opts": ["60 FPS", "120 FPS", "Unlimited"], "idx": 0},
		{"key": "scale", "name": "3D Render Scale", "sub": "GL Compatibility viewport scaling", "type": "slider", "val": 100, "unit": "%"},
	],
	"AUDIO": [
		{"key": "master", "name": "Master Volume", "sub": "Requires AudioServer bus layout", "badge": "PROPOSAL", "type": "slider", "val": 80, "unit": "%"},
		{"key": "bgm", "name": "Music (BGM)", "sub": "Exploration & battle tracks", "badge": "PROPOSAL", "type": "slider", "val": 70, "unit": "%"},
		{"key": "sfx", "name": "Sound Effects (SFX)", "sub": "Combat impacts & evades", "badge": "PROPOSAL", "type": "slider", "val": 90, "unit": "%"},
		{"key": "ui", "name": "UI Audio", "sub": "Menu focus & transitions", "badge": "PROPOSAL", "type": "slider", "val": 85, "unit": "%"},
	],
	"CONTROLS": [
		{"key": "confirm", "name": "Confirm / Interact", "sub": "Mouse Left-Click or Key", "type": "key", "val": "Z"},
		{"key": "menu", "name": "Menu / Back", "sub": "Mouse Right-Click or Key", "type": "key", "val": "X"},
		{"key": "settings", "name": "Settings Shortcut", "sub": "Action: settings", "type": "key", "val": "C"},
		{"key": "evade", "name": "Evade / Dodge", "sub": "Action: evade", "type": "key", "val": "SPACE"},
		{"key": "guard", "name": "Guard", "sub": "Action: guard", "type": "key", "val": "SHIFT"},
	],
	"GAMEPLAY": [
		{"key": "text", "name": "Dialogue Text Speed", "sub": "GameState.text_speed (Slow 28 / Normal 46 / Fast 80)", "type": "cycle", "opts": ["Slow", "Normal", "Fast"], "idx": 1},
		{"key": "tactics", "name": "Persist Tactics Between Dungeons", "sub": "Preserve AI tactic choices across expeditions", "badge": "PROPOSAL", "type": "cycle", "opts": ["On", "Off"], "idx": 0},
	],
	"ACCESSIBILITY": [
		{"key": "motion", "name": "Reduce Camera Motion", "sub": "Stops 3D dolly/orbit sweeps across menus", "badge": "PROPOSAL", "type": "cycle", "opts": ["Off", "On"], "idx": 0},
		{"key": "textscale", "name": "UI Text Scale", "sub": "Scale HUD labels for readability", "badge": "PROPOSAL", "type": "cycle", "opts": ["100%", "115%", "130%"], "idx": 0},
		{"key": "contrast", "name": "High Contrast Mode", "sub": "Boosts card borders and foreground contrast", "badge": "PROPOSAL", "type": "cycle", "opts": ["Off", "On"], "idx": 0},
		{"key": "colorcue", "name": "Non-Color Cue Labels", "sub": "Always pair colors with text/SVG icons", "badge": "PROPOSAL", "type": "cycle", "opts": ["On", "Off"], "idx": 0},
	],
}


## The 18 Natures in canonical order, merged from NatureData (D-393).
static func NATURES_LIST() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for nature_id in NATURE_ORDER:
		if not NatureData.NATURES.has(nature_id):
			continue
		var entry: Dictionary = NatureData.get_nature(nature_id).duplicate(true)
		entry["id"] = nature_id
		entry["name"] = str(entry.get("name", nature_id.capitalize()))
		entry["pure"] = nature_id in PURE_NATURES
		entry["desc"] = str(NATURE_DESCRIPTIONS.get(nature_id, ""))
		entry["mods_text"] = _mods_text(entry.get("mods", {}))
		out.append(entry)
	return out


## Portrait for Selection / Dossier / Confirm: normalized PortraitIcons (D-1093) first.
static func species_portrait(species_id: String) -> Texture2D:
	var portrait_key: String = species_id.trim_prefix("dqt_")
	var icon: Texture2D = PortraitIcons.get_icon(portrait_key)
	if icon != null:
		return icon
	var path: String = str(DQT_PORTRAIT_PATHS.get(species_id, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


## One entry per protagonist for the Selection screen (D-1207: all unlocked).
## No Nature is locked and no combat HP/MP is exposed here.
static func build_protagonist_list() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for species in SPECIES_ORDER:
		if not SPECIES_META.has(species):
			continue
		var meta_v: Variant = SPECIES_META[species]
		if meta_v is not Dictionary:
			continue
		out.append(_build_protagonist_entry(species, meta_v))
	return out


static func get_protagonist_by_index(index: int) -> Dictionary:
	var list := build_protagonist_list()
	if list.is_empty():
		return {}
	return list[clampi(index, 0, list.size() - 1)]


static func get_nature_by_id(nature_id: String) -> Dictionary:
	var target := nature_id.to_lower()
	for entry in NATURES_LIST():
		if str(entry.get("id", "")).to_lower() == target:
			return entry
	return {}


static func get_species_meta(species_id: String) -> Dictionary:
	var key := species_id.to_lower()
	if SPECIES_META.has(key) and SPECIES_META[key] is Dictionary:
		return (SPECIES_META[key] as Dictionary).duplicate(true)
	return {}


## Move sheet used by the Menu detail panel. Presentation copy comes from
## MOVE_PRESENTATION; mechanics are merged from MoveData/Skill (D-1079).
static func get_move_spec(move_id: String) -> Dictionary:
	var key := move_id.to_lower()
	var spec: Dictionary = {}
	if MOVE_PRESENTATION.has(key) and MOVE_PRESENTATION[key] is Dictionary:
		spec = (MOVE_PRESENTATION[key] as Dictionary).duplicate(true)
	if spec.is_empty():
		spec = _fallback_move_spec(key)

	var move := MoveCatalog.get_move(StringName(key))
	var skill := Skill.from_id(StringName(key))
	if move != null:
		spec["move"] = move
		spec["move_id"] = String(move.id)
		if str(spec.get("name", "")).is_empty():
			spec["name"] = move.display_name
		spec["kind"] = int(move.kind)
		spec["dmg_type"] = int(move.damage_type)
		spec["element"] = int(move.element)
		spec["power"] = move.power
		spec["atb"] = int(move.atb_cost)
		spec["mp"] = int(move.mp_cost)
		spec["aoe"] = move.is_aoe
		if move.windup >= 0.0:
			spec["windup"] = move.windup
		spec["ground"] = move.ground
		spec["is_friendly"] = move.is_friendly
		spec["aoe_on_contact"] = move.aoe_on_contact
		spec["status_pause"] = move.status_pause
		spec["visual_push"] = move.visual_push
		spec["target_mode"] = int(move.target_mode)
		spec["primary_side"] = int(move.primary_side)
		spec["secondary_side"] = int(move.secondary_side)
		spec["tags"] = move.tags.duplicate()
		spec["mechanics"] = {
			"kind": int(move.kind),
			"damage_type": int(move.damage_type),
			"power": move.power,
			"atb": int(move.atb_cost),
			"mp": int(move.mp_cost),
			"windup": move.windup,
			"aoe": move.is_aoe,
			"ground": move.ground,
			"is_friendly": move.is_friendly,
		}
	else:
		spec["move"] = null
		spec["move_id"] = key
		spec["kind"] = int(spec.get("kind", 0))
		spec["dmg_type"] = int(spec.get("dmg_type", 0))
		spec["element"] = int(spec.get("elem", Element.Type.FISICO))
		spec["ground"] = false
		spec["is_friendly"] = false
		spec["aoe_on_contact"] = false
		spec["status_pause"] = -1.0
		spec["visual_push"] = -1
		spec["target_mode"] = int(MoveData.TargetMode.AUTO)
		spec["primary_side"] = int(MoveData.TargetSide.ANY)
		spec["secondary_side"] = int(MoveData.TargetSide.ANY)
		spec["tags"] = []
		spec["mechanics"] = {}

	var elem := int(spec.get("element", spec.get("elem", Element.Type.FISICO)))
	var kind := int(spec.get("kind", 0))
	spec["elem"] = elem
	spec["element"] = elem
	spec["element_name"] = Element.name_of(elem)
	spec["range_key"] = _range_key(kind, bool(spec.get("aoe", false)))
	spec["kind_name"] = _kind_name(kind)
	spec["type_key"] = skill.type_icon_name() if skill != null else _type_key(key, kind, int(spec.get("dmg_type", 0)))
	spec["skill"] = skill
	spec["custom_icon_tex"] = MoveIcons.for_move(StringName(key))
	spec["windup_text"] = "%.2fs" % float(spec.get("windup", 0.0))
	return spec


## In-memory CharacterData for the 3D Hub preview. No Nature is baked in
## (D-1207): the Selection keeps every species Nature-agnostic.
static func build_character_data_for_3d(spec: Dictionary) -> CharacterData:
	var id := _spec_id(spec)
	var base_stats := _base_stats_of(spec)
	var neutral := CrawlmonAttributeMath.consolidate_innate_attributes(base_stats, {}, {})

	var data := CharacterData.new()
	data.id = StringName(id)
	data.species_id = id
	data.display_name = _spec_name(spec)
	data.raw_stats = _raw_stats_of(spec)
	data.hp = calc_max_hp(1, int(neutral.get("VIT", 1)))
	data.attack = int(neutral.get("STR", 1))
	data.speed = calc_atb_speed(int(neutral.get("AGI", 1)))
	data.nature_id = ""
	data.travel_extra = float(spec.get("travel_extra", 0.0))
	data.base_experience = int(spec.get("base_experience", 30))
	data.affinities = _affinities_of(spec)
	data.weaknesses = _elements_with(data.affinities, Affinity.Type.WEAK)
	data.loadout = _build_loadout(spec)
	data.model_profile = _build_model_profile(spec)
	return data


## Combatant for the 3D Hub. Valid for CharacterModelLoader.create_character_model():
## `species_id` and `name` resolve the GLB and the profile.
static func build_combatant_for_3d(spec: Dictionary) -> Combatant:
	var data := build_character_data_for_3d(spec)
	var nature_id := str(spec.get("nature_id", "")).to_lower()
	if not NatureData.NATURES.has(nature_id):
		nature_id = _roll_nature_id()
	var offsets: Dictionary = {}
	if spec.get("individual_offsets") is Dictionary:
		offsets = (spec["individual_offsets"] as Dictionary).duplicate(true)
	if offsets.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		offsets = CrawlmonAttributeMath.roll_individual_offsets(rng)
	var nature_mods: Dictionary = NatureData.get_nature(nature_id).get("mods", {})
	var innate := CrawlmonAttributeMath.consolidate_innate_attributes(
		CrawlmonAttributeMath.convert_species_stats_to_15_points(data.raw_stats),
		offsets,
		nature_mods
	)
	var level := maxi(int(spec.get("level", 1)), 1)

	var combatant := Combatant.new(
		data.display_name,
		data.hp,
		data.attack,
		data.speed,
		bool(spec.get("is_player", true))
	)
	combatant.species_id = data.species_id
	combatant.base_experience = data.base_experience
	combatant.nature_id = nature_id
	combatant.individual_offsets = offsets
	combatant.innate_stats = innate
	combatant.level = level
	combatant.uses_effective_strength = true
	combatant.sync_effective_stats()
	combatant.update_resource_maximums()
	combatant.hp = combatant.max_hp
	combatant.mp = combatant.max_mp
	combatant.base_attack = combatant.str

	combatant.weaknesses.clear()
	for element in _elements_with(data.affinities, Affinity.Type.WEAK):
		if not combatant.weaknesses.has(element):
			combatant.weaknesses.append(element)
	combatant.affinities.clear()
	for key in data.affinities.keys():
		combatant.affinities[int(key)] = int(data.affinities[key])
	combatant.travel_extra = data.travel_extra
	combatant.act_policy = int(spec.get("act_policy", Combatant.Act.ATTACK))
	combatant.react_policy = int(spec.get("react_policy", Combatant.React.NONE))

	combatant.skills.clear()
	for move_id in data.skill_ids():
		var skill := Skill.from_id(move_id)
		if skill != null:
			combatant.skills.append(skill)
	combatant.inventory = data.inventory().duplicate(true)
	return combatant


## D-392: HP = 25 + 10*L + 25*floor(L/10) + 2*VIT.
static func calc_max_hp(level: int, vit: int) -> int:
	return CrawlmonAttributeMath.calculate_max_hp(level, vit)


## D-391: MP = 10 + 2*WIS + L.
static func calc_max_mp(level: int, wis: int) -> int:
	return CrawlmonAttributeMath.calculate_max_mp(level, wis)


## D-126 / D-145: blocks per second = 0.35 + max(AGI, 1) * 0.0375.
static func calc_atb_speed(agi: int) -> float:
	return CrawlmonAttributeMath.natural_atb_increment(1.0, float(maxi(agi, 1)))


## D-1225: +3 points at every 5th level, +1 at every other level-up.
static func total_bonus_points_at_level(level: int) -> int:
	var total := 0
	for reached in range(2, maxi(level, 1) + 1):
		total += CrawlmonAttributeMath.get_stat_points_for_level(reached)
	return total


## D-390 / D-393 / D-394: 15-point base + individual offsets + Nature mods,
## with the HP/MP/ATB preview derived from the consolidated attributes.
static func consolidate_stats(spec: Dictionary, nature_id: String = "hardy", offsets: Dictionary = {}, level: int = 1) -> Dictionary:
	var base_stats := _base_stats_of(spec)
	var nat_id := nature_id.to_lower()
	if not NatureData.NATURES.has(nat_id):
		nat_id = "hardy"
	var nature := NatureData.get_nature(nat_id)
	var mods: Dictionary = nature.get("mods", {})
	var innate := CrawlmonAttributeMath.consolidate_innate_attributes(base_stats, offsets, mods)
	var lvl := maxi(level, 1)
	return {
		"nature_id": nat_id,
		"nature_name": str(nature.get("name", "Hardy")),
		"level": lvl,
		"base_stats": base_stats,
		"base_stats_total": _sum_stats(base_stats),
		"individual_offsets": offsets.duplicate(true),
		"stats": innate,
		"stats_total": _sum_stats(innate),
		"max_hp": calc_max_hp(lvl, int(innate.get("VIT", 1))),
		"max_mp": calc_max_mp(lvl, int(innate.get("WIS", 1))),
		"atb_speed": calc_atb_speed(int(innate.get("AGI", 1))),
		"bonus_points": total_bonus_points_at_level(lvl),
	}


static func clone_default_settings() -> Dictionary:
	return DEFAULT_SETTINGS.duplicate(true)


## Finds a settings row by tab + key, falling back to DEFAULT_SETTINGS.
static func setting_row(settings: Dictionary, tab: String, key: String) -> Dictionary:
	var wanted := key.to_lower()
	var row := _find_row(_rows_for(settings, tab), wanted)
	if not row.is_empty():
		return row
	return _find_row(_rows_for(DEFAULT_SETTINGS, tab), wanted)


static func _find_row(rows: Array, key: String) -> Dictionary:
	for row_v in rows:
		if row_v is Dictionary and str((row_v as Dictionary).get("key", "")).to_lower() == key:
			return (row_v as Dictionary).duplicate(true)
	return {}


static func _rows_for(data: Dictionary, tab: String) -> Array:
	for candidate in [tab, tab.to_upper(), tab.to_lower()]:
		var rows: Variant = data.get(candidate)
		if rows is Array:
			return rows as Array
	return []


static func _cycle_value(settings: Dictionary, tab: String, key: String) -> String:
	var row := setting_row(settings, tab, key)
	var opts: Variant = row.get("opts", [])
	if not (opts is Array) or (opts as Array).is_empty():
		return ""
	var options: Array = opts as Array
	var idx := clampi(int(row.get("idx", 0)), 0, options.size() - 1)
	return str(options[idx])


static func _slider_value(settings: Dictionary, tab: String, key: String) -> float:
	return clampf(float(setting_row(settings, tab, key).get("val", 0.0)), 0.0, 100.0)


static func _ui_text_scale(settings: Dictionary) -> float:
	var text := _cycle_value(settings, "ACCESSIBILITY", "textscale").trim_suffix("%")
	if text.is_empty():
		return 1.0
	return clampf(float(text) / 100.0, 0.5, 2.0)


## Applies the array-schema settings to the engine. Headless runs skip
## DisplayServer and missing audio buses are ignored; GameState.text_speed is
## clamped to 0..2 and accessibility switches are exposed as node metas.
static func apply_settings_to_engine(settings: Dictionary, gs: Node = null) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var root: Window = null
	if tree != null:
		root = tree.root

	if DisplayServer.get_name() != "headless":
		match _cycle_value(settings, "VIDEO", "mode"):
			"Borderless":
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			"Fullscreen":
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			_:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var resolution := _cycle_value(settings, "VIDEO", "res").split("x", false)
		if resolution.size() == 2:
			var width := int(resolution[0])
			var height := int(resolution[1])
			if width > 0 and height > 0:
				DisplayServer.window_set_size(Vector2i(width, height))
		var vsync_off := _cycle_value(settings, "VIDEO", "vsync") == "Disabled"
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_DISABLED if vsync_off else DisplayServer.VSYNC_ENABLED
		)
		var fps_text := _cycle_value(settings, "VIDEO", "fps")
		if fps_text == "Unlimited":
			Engine.max_fps = 0
		elif not fps_text.is_empty():
			Engine.max_fps = clampi(int(fps_text.split(" ")[0]), 0, 1000)

	if root != null:
		root.scaling_3d_scale = clampf(_slider_value(settings, "VIDEO", "scale") / 100.0, 0.1, 1.0)
		root.content_scale_factor = _ui_text_scale(settings)

	_set_bus_volume("Master", _slider_value(settings, "AUDIO", "master") / 100.0)
	_set_bus_volume("Music", _slider_value(settings, "AUDIO", "bgm") / 100.0)
	_set_bus_volume("SFX", _slider_value(settings, "AUDIO", "sfx") / 100.0)
	_set_bus_volume("UI", _slider_value(settings, "AUDIO", "ui") / 100.0)

	var state: Node = gs
	if state == null and tree != null and tree.root != null and tree.root.has_node("GameState"):
		state = tree.root.get_node("GameState")
	if state != null:
		var text_row := setting_row(settings, "GAMEPLAY", "text")
		state.set("text_speed", clampi(int(text_row.get("idx", 1)), 0, 2))
		state.set_meta("reduce_camera_motion", _cycle_value(settings, "ACCESSIBILITY", "motion") == "On")
		state.set_meta("high_contrast", _cycle_value(settings, "ACCESSIBILITY", "contrast") == "On")
		state.set_meta("non_color_cues", _cycle_value(settings, "ACCESSIBILITY", "colorcue") == "On")


static func _build_protagonist_entry(species: String, meta: Dictionary) -> Dictionary:
	var raw_stats := _raw_stats_of(meta)
	var base_stats := CrawlmonAttributeMath.convert_species_stats_to_15_points(raw_stats)
	var elements := _elements_of(meta)
	var element_names: Array[String] = []
	for element in elements:
		element_names.append(Element.name_of(element))
	var affinities := _affinities_of(meta)
	var starter: Array[String] = []
	for move_id in meta.get("starter_moves", []):
		starter.append(str(move_id))
	var learn_tree: Array = []
	if meta.get("learn_tree") is Array:
		learn_tree = (meta["learn_tree"] as Array).duplicate(true)
	var combos := _combo_ev_for(species)
	return {
		"id": species,
		"name": _spec_name(meta, species),
		"unlocked": true,
		"height": float(meta.get("height", 1.0)),
		"glb_path": str(meta.get("glb_path", "")),
		"origin": str(meta.get("origin", "")),
		"color": meta.get("color", Color.WHITE),
		"accent": meta.get("accent", Color.WHITE),
		"elements": elements,
		"element_names": element_names,
		"starter_moves": starter,
		"raw_stats": raw_stats,
		"base_stats": base_stats,
		"stats": base_stats,
		"base_stats_total": _sum_stats(base_stats),
		"affinities": affinities,
		"weaknesses": _elements_with(affinities, Affinity.Type.WEAK),
		"resistances": _elements_with(affinities, Affinity.Type.RESIST),
		"learn_tree": learn_tree,
		"passive_summary": str(meta.get("passive_summary", "")),
		"pending_ability": str(meta.get("pending_ability", "")),
		"portrait_icon": species_portrait(species),
		"combo_ev": combos,
		"combo_ev_count": combos.size(),
	}


static func _combo_ev_for(species: String) -> Dictionary:
	if COMBO_EV_TABLE.has(species) and COMBO_EV_TABLE[species] is Dictionary:
		return (COMBO_EV_TABLE[species] as Dictionary).duplicate(true)
	return {}


static func _elements_of(meta: Dictionary) -> Array[int]:
	var out: Array[int] = []
	for element in meta.get("elements", []):
		out.append(int(element))
	return out


static func _elements_with(affinities: Dictionary, kind: int) -> Array[int]:
	var out: Array[int] = []
	for key in affinities.keys():
		if int(affinities[key]) == kind:
			out.append(int(key))
	out.sort()
	return out


static func _affinities_of(spec: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	if spec.get("affinities") is Dictionary:
		var raw: Dictionary = spec["affinities"]
		for key in raw.keys():
			out[int(key)] = int(raw[key])
	return out


static func _raw_stats_of(spec: Dictionary) -> Dictionary:
	if spec.get("raw_stats") is Dictionary:
		return (spec["raw_stats"] as Dictionary).duplicate(true)
	var direct: Dictionary = {}
	for stat in STAT_ORDER:
		if spec.has(stat):
			direct[stat] = int(spec[stat])
	return direct


static func _base_stats_of(spec: Dictionary) -> Dictionary:
	if spec.get("base_stats") is Dictionary:
		return (spec["base_stats"] as Dictionary).duplicate(true)
	var raw := _raw_stats_of(spec)
	if raw.is_empty():
		return {"STR": 3, "MAG": 3, "VIT": 3, "WIS": 2, "AGI": 2, "LUK": 2}
	return CrawlmonAttributeMath.convert_species_stats_to_15_points(raw)


static func _sum_stats(stats: Dictionary) -> int:
	var total := 0
	for stat in STAT_ORDER:
		total += int(stats.get(stat, 0))
	return total


static func _spec_id(spec: Dictionary) -> String:
	var id := str(spec.get("id", spec.get("species_id", ""))).to_lower()
	if not id.is_empty():
		return id
	var path := str(spec.get("glb_path", ""))
	if not path.is_empty():
		return path.get_file().get_basename().to_lower()
	return ""


static func _spec_name(spec: Dictionary, fallback_id: String = "") -> String:
	var explicit := str(spec.get("name", ""))
	if not explicit.is_empty():
		return explicit
	var id := fallback_id
	if id.is_empty():
		id = _spec_id(spec)
	return id.capitalize()


static func _build_loadout(spec: Dictionary) -> CharacterLoadout:
	var loadout := CharacterLoadout.new()
	var skills: Array[StringName] = []
	for move_id in spec.get("starter_moves", []):
		var skill_id := StringName(str(move_id))
		if skill_id != &"" and not skills.has(skill_id):
			skills.append(skill_id)
	loadout.skills = skills
	loadout.inventory = {}

	var learnset: Dictionary = {}
	for entry_v in spec.get("learn_tree", []):
		if not (entry_v is Dictionary):
			continue
		var entry: Dictionary = entry_v
		var move_id := StringName(str(entry.get("move", entry.get("id", ""))))
		if move_id == &"":
			continue
		var level := maxi(int(entry.get("level", entry.get("lv", 1))), 1)
		var ids: Array[StringName] = []
		if learnset.has(level):
			ids = learnset[level]
		if not ids.has(move_id):
			ids.append(move_id)
		learnset[level] = ids
	loadout.learnset = learnset
	return loadout


static func _build_model_profile(spec: Dictionary) -> CharacterModelProfile:
	var profile := CharacterModelProfile.new()
	var height := float(spec.get("height", 1.0))
	profile.profile = {
		"glb_path": str(spec.get("glb_path", "")),
		"native_height": height,
		"target_height": height,
		"origin": str(spec.get("origin", "")),
		"rotation_y": float(spec.get("rotation_y", 0.0)),
		"clip_prefix": str(spec.get("clip_prefix", "")),
	}
	return profile


static func _roll_nature_id() -> String:
	var ids := NatureData.get_all_nature_ids()
	if ids.is_empty():
		return "hardy"
	return ids[randi_range(0, ids.size() - 1)]


## Range badge key matching PreGameDraw.MOVE_RANGES. Status Moves have no badge.
static func _range_key(kind: int, aoe: bool = false) -> String:
	if kind == int(Skill.Kind.STATUS):
		return ""
	if aoe:
		return "area"
	if kind == int(Skill.Kind.MELEE):
		return "melee"
	if kind == int(Skill.Kind.PROJECTILE):
		return "long"
	return "mid"


## Kind label for the card tag: Skill.Kind order (D-1079).
static func _kind_name(kind: int) -> String:
	if kind < 0 or kind >= MOVE_RANGE_KEYS.size():
		return "melee"
	return MOVE_RANGE_KEYS[kind]


static func _type_key(move_id: String, kind: int, dmg_type: int) -> String:
	if move_id == "teleporte_rapido" or move_id == "evade":
		return "dodge"
	if move_id == "guard":
		return "guard"
	if kind == int(Skill.Kind.STATUS):
		return "status"
	return "magical" if dmg_type == int(MoveData.DamageType.MAGICAL) else "physical"


static func _fallback_move_spec(move_id: String) -> Dictionary:
	return {
		"name": move_id.capitalize(),
		"elem": int(Element.Type.FISICO),
		"kind": int(Skill.Kind.MELEE),
		"dmg_type": int(MoveData.DamageType.PHYSICAL),
		"power": 1.0,
		"atb": 2,
		"mp": 0,
		"aoe": false,
		"windup": 1.0,
		"visuals": "",
		"motion": "",
		"text": "",
	}


static func _mods_text(mods: Dictionary) -> String:
	var parts: PackedStringArray = []
	for stat in STAT_ORDER:
		var value := int(mods.get(stat, 0))
		if value == 0:
			continue
		parts.append("%s%d %s" % ["+" if value > 0 else "", value, stat])
	if parts.is_empty():
		return "No stat changes"
	return "  ·  ".join(parts)


static func _set_bus_volume(bus_name: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	var value := clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_mute(index, value <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.0001)))
