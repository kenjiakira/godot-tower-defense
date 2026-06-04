extends Node

@export var towers_root: Node2D
@export var build_spots_root: Node2D
@export var tower_scene: PackedScene


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


func build_at(mouse_pos: Vector2, cost: int):
	var spot = get_build_spot_at(mouse_pos)

	if spot == null:
		print("Không thể đặt tower ở đây")
		return null

	if spot.occupied:
		print("Ô này đã có tower")
		return null

	if tower_scene == null:
		print("Chưa gán tower_scene")
		return null

	var tower = tower_scene.instantiate()
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
