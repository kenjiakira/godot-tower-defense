extends Area2D

var target = null
var damage := 25
var speed := 450.0

func setup(new_target, new_damage):
	target = new_target
	damage = new_damage

func _process(delta):
	if not is_instance_valid(target):
		queue_free()
		return
	
	var direction = (target.global_position - global_position).normalized()
	global_position += direction * speed * delta
	
	if global_position.distance_to(target.global_position) < 10:
		if target.has_method("take_damage"):
			target.take_damage(damage)
		queue_free()
