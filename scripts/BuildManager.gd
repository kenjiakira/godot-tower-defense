extends Node

@export var towers_root: Node2D
@export var build_spots_root: Node2D

@export var tower_basic_scene: PackedScene
@export var tower_aoe_scene: PackedScene
@export var tower_sniper_scene: PackedScene
@export var tower_slow_scene: PackedScene

@export var bullet_basic_scene: PackedScene
@export var bullet_aoe_scene: PackedScene
@export var bullet_sniper_scene: PackedScene
@export var bullet_slow_scene: PackedScene

const TOWER_COSTS = {
	0: 50,   # BASIC
	1: 70,   # AOE
	2: 100,  # SNIPER
	3: 60    # SLOW
}

const TOWER_SCENES = {
	0: "tower_basic_scene",
	1: "tower_aoe_scene",
	2: "tower_sniper_scene",
	3: "tower_slow_scene"
}

func get_tower_at(mouse_pos: Vector2):
	for tower in towers_root.get_children():
		if tower.global_position.distance_to(mouse_pos) <= 30:
			return tower

	return null


func get_build_spot_at(mouse_pos: Vector2):
	for spot in build_spots_root.get_children():
		if spot is Area2D:
			var collision = spot.get_node_or_null("CollisionShape2D")
			if collision == null:
				continue

			var shape = collision.shape
			var local_pos = spot.to_local(mouse_pos)

			if shape is RectangleShape2D:
				var half_size = shape.size / 2

				if abs(local_pos.x) <= half_size.x and abs(local_pos.y) <= half_size.y:
					return spot

	return null


func can_build_at(mouse_pos: Vector2) -> bool:
	var spot = get_build_spot_at(mouse_pos)

	if spot == null:
		return false

	if spot.occupied:
		return false

	return true


func get_scene_for_type(tower_type: int) -> PackedScene:
	match tower_type:
		0: return tower_basic_scene
		1: return tower_aoe_scene
		2: return tower_sniper_scene
		3: return tower_slow_scene
	return tower_basic_scene


func get_bullet_scene_for_type(tower_type: int) -> PackedScene:
	match tower_type:
		0: return bullet_basic_scene
		1: return bullet_aoe_scene
		2: return bullet_sniper_scene
		3: return bullet_slow_scene
	return bullet_basic_scene


func get_cost_for_type(tower_type: int) -> int:
	return TOWER_COSTS.get(tower_type, 50)


func build_at(mouse_pos: Vector2, cost: int, tower_type: int = 0):
	var spot = get_build_spot_at(mouse_pos)

	if spot == null:
		print("Khong the dat tower o day")
		return null

	if spot.occupied:
		print("O nay da co tower")
		return null

	var scene = get_scene_for_type(tower_type)
	if scene == null:
		print("Chua gan tower_scene cho type: ", tower_type)
		return null

	var tower = scene.instantiate()
	towers_root.add_child(tower)
	tower.global_position = spot.global_position

	if tower.has_method("setup_cost"):
		tower.setup_cost(cost)

	spot.set_occupied(tower)

	return tower


func clear_tower(tower):
	for spot in build_spots_root.get_children():
		if spot.has_method("clear_occupied") and spot.tower == tower:
			spot.clear_occupied()
			return
