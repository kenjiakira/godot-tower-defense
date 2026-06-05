extends Area2D

var speed := 500
var target = null
var damage := 10
var tower_type := 0
var tower_level := 1

var aoe_radius := 70
var slow_amount := 0.5
var slow_duration := 2.0


func setup(_target, _damage, _tower_type, _tower_level = 1):
	target = _target
	damage = _damage
	tower_type = _tower_type
	tower_level = _tower_level
	
	match tower_type:
		0:  # BASIC
			speed = 500
		1:  # AOE
			speed = 400
			aoe_radius = 85 + tower_level * 15
		2:  # SNIPER
			speed = 800
		3:  # SLOW
			speed = 450
			slow_amount = 0.4 + tower_level * 0.05
			slow_duration = 1.5 + tower_level * 0.5


func _process(delta):
	if target == null or not is_instance_valid(target):
		queue_free()
		return
	
	var dir = (target.global_position - global_position).normalized()
	global_position += dir * speed * delta
	
	rotation = dir.angle()
	
	if global_position.distance_to(target.global_position) < 12:
		hit_target()


func hit_target():
	if target == null or not is_instance_valid(target):
		queue_free()
		return
	
	match tower_type:
		0:  # BASIC
			target.take_damage(damage)
		1:  # AOE
			target.take_damage(damage)
			explode()
		2:  # SNIPER
			target.take_damage(int(damage * 1.5))
		3:  # SLOW
			target.take_damage(damage)
			target.apply_slow(slow_amount, slow_duration)
	
	queue_free()


func explode():
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if enemy == target:
			continue
		
		if global_position.distance_to(enemy.global_position) <= aoe_radius:
			enemy.take_damage(int(damage * 0.7))  # 70% splash
