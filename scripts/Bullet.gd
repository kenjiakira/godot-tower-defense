extends Area2D

var speed := 500
var target = null
var damage := 10
var tower_type := 0

func setup(_target, _damage, _tower_type):
	target = _target
	damage = _damage
	tower_type = _tower_type

func _process(delta):
	if target == null or not is_instance_valid(target):
		queue_free()
		return

	var dir = (target.global_position - global_position).normalized()
	global_position += dir * speed * delta

	rotation = dir.angle()

	if global_position.distance_to(target.global_position) < 10:
		hit_target()
		
func hit_target():
	if target == null or not is_instance_valid(target):
		queue_free()
		return

	target.take_damage(damage)

	match tower_type:
		2:
			explode()
		4:
			target.apply_slow(0.5, 2.0)

	queue_free()

func explode():
	var enemies = get_tree().get_nodes_in_group("enemies")

	for enemy in enemies:
		if enemy == target:
			continue

		if global_position.distance_to(enemy.global_position) <= 70:
			enemy.take_damage(damage * 0.5)
