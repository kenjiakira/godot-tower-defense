extends Area2D

@export var bullet_scene: PackedScene

var level := 1
var max_level := 3

var damage := 25
var fire_rate := 0.6
var upgrade_cost := 80

var enemies = []

func _ready():
	apply_level_stats()
	
	$ShootTimer.timeout.connect(shoot)
	$ShootTimer.start()
	
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func apply_level_stats():
	if level == 1:
		damage = 25
		fire_rate = 0.6
		upgrade_cost = 80
		set_body_color(Color.BLUE)
		set_range(150)
	elif level == 2:
		damage = 45
		fire_rate = 0.45
		upgrade_cost = 140
		set_body_color(Color.CYAN)
		set_range(180)
	elif level == 3:
		damage = 75
		fire_rate = 0.3
		upgrade_cost = 0
		set_body_color(Color.PURPLE)
		set_range(220)
	
	if has_node("ShootTimer"):
		$ShootTimer.wait_time = fire_rate

func set_body_color(color):
	if has_node("Body"):
		$Body.color = color

func set_range(radius):
	if has_node("CollisionShape2D"):
		var shape = $CollisionShape2D.shape
		if shape is CircleShape2D:
			shape.radius = radius

func can_upgrade():
	return level < max_level

func upgrade():
	if not can_upgrade():
		return false
	
	level += 1
	apply_level_stats()
	print("Tower upgraded to level:", level)
	return true

func get_upgrade_cost():
	return upgrade_cost

func get_info_text():
	if can_upgrade():
		return "Tower Lv" + str(level) + "\nDamage: " + str(damage) + "\nUpgrade: " + str(upgrade_cost)
	else:
		return "Tower Lv" + str(level) + "\nDamage: " + str(damage) + "\nMAX LEVEL"

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
	
	if bullet_scene == null:
		print("Chưa gán bullet_scene")
		return
	
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.get_node("Bullets").add_child(bullet)
	bullet.global_position = global_position
	bullet.setup(target, damage)
