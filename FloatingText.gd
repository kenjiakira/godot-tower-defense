extends Label

var velocity := Vector2(0, -40)
var lifetime := 0.6

func setup(text_value, start_pos):
	text = str(text_value)
	global_position = start_pos

func _process(delta):
	global_position += velocity * delta
	lifetime -= delta
	
	modulate.a = lifetime / 0.6
	
	if lifetime <= 0:
		queue_free()
