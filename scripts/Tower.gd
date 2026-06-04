extends Area2D

@export var bullet_scene: PackedScene

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


func _ready():
	apply_level_stats()
	
	if has_node("ShootTimer"):
		$ShootTimer.timeout.connect(shoot)
		$ShootTimer.start()
	
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	# Nếu vẫn còn node RangePreview cũ thì ẩn nó đi
	if has_node("RangePreview"):
		$RangePreview.visible = false


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
	if level == 1:
		damage = 25
		fire_rate = 0.6
		upgrade_cost = 80
		set_body_color(Color.WHITE)
		set_range(150)
	elif level == 2:
		damage = 45
		fire_rate = 0.45
		upgrade_cost = 140
		set_body_color(Color(1.1, 1.1, 1.3))
		set_range(180)
	elif level == 3:
		damage = 75
		fire_rate = 0.3
		upgrade_cost = 0
		set_body_color(Color(1.25, 1.15, 1.45))
		set_range(220)
	
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
		"level": level,
		"max_level": max_level,
		"damage": damage,
		"range": get_range(),
		"fire_rate": fire_rate,
		"upgrade_cost": upgrade_cost,
		"sell_value": get_sell_value(),
		"can_upgrade": can_upgrade()
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
	
	if bullet_scene == null:
		print("Chưa gán bullet_scene")
		return
	
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.get_node("Bullets").add_child(bullet)
	bullet.global_position = global_position
	bullet.setup(target, damage, 0)
	
	var audio_manager = get_tree().current_scene.get_node("Managers/AudioManager")
	audio_manager.play_sfx("ShootSound")
