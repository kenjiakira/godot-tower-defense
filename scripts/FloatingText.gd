extends Label

var velocity := Vector2(0, -40)
var lifetime := 0.8
var timer := 0.0
var warning_tween: Tween
var fly_to_target := false
var target_position := Vector2.ZERO
var fly_speed := 500.0

func setup_text(value: String, color: Color):
	text = value
	modulate = color

func fly_to(target: Vector2):
	fly_to_target = true
	target_position = target

func _process(delta):
	timer += delta

	if fly_to_target:
		global_position = global_position.move_toward(target_position, fly_speed * delta)
			
		if global_position.distance_to(target_position) < 10:
			queue_free()
	else:
		position += velocity * delta
		modulate.a = 1.0 - timer / lifetime
		
		if timer >= lifetime:
			queue_free()
