extends Node

const TOWER_BASIC := 0
const TOWER_AOE := 1
const TOWER_SNIPER := 2
const TOWER_SLOW := 3

const TOWER_COSTS := {
	TOWER_BASIC: 50,
	TOWER_AOE: 70,
	TOWER_SNIPER: 100,
	TOWER_SLOW: 60,
}

const TOWER_NAMES := {
	TOWER_BASIC: "Basic",
	TOWER_AOE: "AOE",
	TOWER_SNIPER: "Sniper",
	TOWER_SLOW: "Slow",
}

const TOWER_DESCRIPTIONS := {
	TOWER_BASIC: "Basic tower",
	TOWER_AOE: "Hits multiple targets",
	TOWER_SNIPER: "High damage, slow attack speed",
	TOWER_SLOW: "Slows enemies",
}

const TOWER_STATS := {
	TOWER_BASIC: {
		"range": [150, 180, 220],
		"damage": [40, 65, 100],
		"fire_rate": [0.6, 0.45, 0.3],
		"upgrade_cost": [80, 150, 0],
		"range_color": Color(0.65, 0.943, 1.0, 0.85),
		"fire_color": Color.WHITE,
	},
	TOWER_AOE: {
		"range": [140, 160, 180],
		"damage": [35, 55, 80],
		"fire_rate": [0.9, 0.75, 0.6],
		"upgrade_cost": [100, 180, 0],
		"range_color": Color(1.0, 0.5, 0.0, 0.85),
		"fire_color": Color.ORANGE,
	},
	TOWER_SNIPER: {
		"range": [300, 340, 380],
		"damage": [100, 150, 220],
		"fire_rate": [2.0, 1.6, 1.2],
		"upgrade_cost": [160, 280, 0],
		"range_color": Color(0.2, 0.4, 1.0, 0.85),
		"fire_color": Color.BLUE,
	},
	TOWER_SLOW: {
		"range": [140, 160, 180],
		"damage": [15, 25, 40],
		"fire_rate": [0.5, 0.4, 0.3],
		"upgrade_cost": [90, 170, 0],
		"range_color": Color(0.0, 1.0, 1.0, 0.85),
		"fire_color": Color.CYAN,
	},
}

func get_tower_cost(tower_type: int) -> int:
	return TOWER_COSTS.get(tower_type, TOWER_COSTS[TOWER_BASIC])


func get_tower_name(tower_type: int) -> String:
	return TOWER_NAMES.get(tower_type, TOWER_NAMES[TOWER_BASIC])


func get_tower_description(tower_type: int) -> String:
	return TOWER_DESCRIPTIONS.get(tower_type, TOWER_DESCRIPTIONS[TOWER_BASIC])


func get_tower_stats(tower_type: int, level: int) -> Dictionary:
	var tower_stats: Dictionary = TOWER_STATS.get(tower_type, TOWER_STATS[TOWER_BASIC])
	var level_index: int = clamp(level - 1, 0, 2)

	return {
		"range": tower_stats["range"][level_index],
		"damage": tower_stats["damage"][level_index],
		"fire_rate": tower_stats["fire_rate"][level_index],
		"upgrade_cost": tower_stats["upgrade_cost"][level_index],
		"range_color": tower_stats["range_color"],
		"fire_color": tower_stats["fire_color"],
		"name": get_tower_name(tower_type),
		"description": get_tower_description(tower_type),
	}
