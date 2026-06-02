extends Label

var velocity := Vector2(0, -40)
var lifetime := 0.6

func setup(text_value, pos, color = Color.WHITE):
	global_position = pos
	text = text_value
	modulate = color
	
func _process(delta):
	global_position += velocity * delta
	lifetime -= delta
	
	modulate.a = lifetime / 0.6
	
	if lifetime <= 0:
		queue_free()
