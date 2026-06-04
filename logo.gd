extends TextureRect

var t := 0.0

func _process(delta):
	t += delta
	scale = Vector2.ONE * (1.0 + sin(t * 2.0) * 0.02)
