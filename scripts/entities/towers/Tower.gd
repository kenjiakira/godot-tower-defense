extends Area2D

enum TowerType {
	BASIC = 0,
	AOE = 1,
	SNIPER = 2,
	SLOW = 3
}

@export var bullet_scene: PackedScene
@export var tower_type: TowerType = TowerType.BASIC

var level := 1
var max_level := 3

var damage := 25
var fire_rate := 0.6
var upgrade_cost := 80

var base_cost := 50
var total_spent := 50

var enemies = []

var is_selected := false
var range_rotation := 0.0
var range_rotate_speed := 0.3

var dash_count := 48
var dash_ratio := 0.55
var range_line_width := 3.0
var range_color := Color(0.65, 0.943, 1.0, 0.85)

var tower_name := "Basic"
var tower_description := "Basic tower"
var fire_color := Color.WHITE

var build_manager = null
var projectiles_root: Node = null
var audio_manager: Node = null


func _ready():
	apply_level_stats()

	if has_node("ShootTimer"):
		$ShootTimer.timeout.connect(shoot)
		$ShootTimer.start()

	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

	if has_node("RangePreview"):
		$RangePreview.visible = false


func setup_dependencies(manager, bullets_root: Node, audio):
	build_manager = manager
	projectiles_root = bullets_root
	audio_manager = audio


func _process(delta):
	if is_selected:
		range_rotation += delta * range_rotate_speed
		queue_redraw()


func _draw():
	if not is_selected:
		return

	var radius := float(get_range())

	if radius <= 0:
		return

	draw_dashed_circle(radius)


func draw_dashed_circle(radius: float):
	for i in range(dash_count):
		var start_angle := TAU * float(i) / float(dash_count) + range_rotation
		var end_angle := TAU * (float(i) + dash_ratio) / float(dash_count) + range_rotation

		var start_pos := Vector2(
			cos(start_angle),
			sin(start_angle)
		) * radius

		var end_pos := Vector2(
			cos(end_angle),
			sin(end_angle)
		) * radius

		draw_line(
			start_pos,
			end_pos,
			range_color,
			range_line_width,
			true
		)


func setup_cost(cost: int):
	base_cost = cost
	total_spent = cost


func apply_level_stats():
	var stats = GameConfig.get_tower_stats(tower_type, level)
	tower_name = stats["name"]
	tower_description = stats["description"]
	fire_color = stats["fire_color"]
	damage = stats["damage"]
	fire_rate = stats["fire_rate"]
	upgrade_cost = stats["upgrade_cost"]
	range_color = stats["range_color"]
	set_range(stats["range"])

	set_body_color(Color.WHITE)

	if has_node("ShootTimer"):
		$ShootTimer.wait_time = fire_rate

	queue_redraw()


func upgrade():
	if not can_upgrade():
		return false

	total_spent += upgrade_cost
	level += 1
	apply_level_stats()
	return true


func get_sell_value():
	return int(total_spent * 0.7)


func get_town_data():
	return {
		"type": tower_type,
		"type_name": tower_name,
		"level": level,
		"max_level": max_level,
		"damage": damage,
		"range": get_range(),
		"fire_rate": fire_rate,
		"upgrade_cost": upgrade_cost,
		"sell_value": get_sell_value(),
		"can_upgrade": can_upgrade(),
		"description": tower_description
	}


func get_range():
	if has_node("CollisionShape2D"):
		var shape = $CollisionShape2D.shape
		if shape is CircleShape2D:
			return int(shape.radius)
	return 0


func can_upgrade():
	return level < max_level


func get_upgrade_cost():
	return upgrade_cost


func set_body_color(color: Color):
	if has_node("Body"):
		$Body.modulate = color


func set_range(radius):
	if has_node("CollisionShape2D"):
		var shape = $CollisionShape2D.shape
		if shape is CircleShape2D:
			shape.radius = radius

	queue_redraw()


func set_selected(value):
	is_selected = value
	queue_redraw()


func _on_area_entered(area):
	if area.is_in_group("enemy"):
		enemies.append(area.get_parent())


func _on_area_exited(area):
	if area.is_in_group("enemy"):
		enemies.erase(area.get_parent())


func shoot():
	enemies = enemies.filter(func(e): return is_instance_valid(e))

	if enemies.is_empty():
		return

	var target = enemies[0]

	if tower_type == TowerType.SNIPER and enemies.size() > 1:
		target = get_strongest_enemy()

	if tower_type == TowerType.SLOW and enemies.size() > 1:
		target = get_fastest_enemy()

	var bullet_scene_to_use: PackedScene = bullet_scene
	if build_manager and build_manager.has_method("get_bullet_scene_for_type"):
		bullet_scene_to_use = build_manager.get_bullet_scene_for_type(tower_type)
	if bullet_scene_to_use == null:
		print("Bullet scene is not assigned")
		return

	var bullet = bullet_scene_to_use.instantiate()
	if projectiles_root != null:
		projectiles_root.add_child(bullet)
	else:
		get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position
	bullet.setup(target, damage, tower_type, level)

	if audio_manager and audio_manager.has_method("play_sfx"):
		audio_manager.play_sfx("ShootSound")


func get_strongest_enemy() -> Node:
	var strongest = enemies[0]
	var max_hp = 0

	for enemy in enemies:
		if enemy.has_method("get_hp"):
			var hp = enemy.get_hp()
			if hp > max_hp:
				max_hp = hp
				strongest = enemy

	return strongest


func get_fastest_enemy() -> Node:
	var fastest = enemies[0]
	var max_speed = fastest.speed if fastest.has_method("get") else 100.0

	for enemy in enemies:
		var enemy_speed = enemy.speed if enemy.has_method("get") else 100.0
		if enemy_speed > max_speed:
			max_speed = enemy_speed
			fastest = enemy

	return fastest
