extends Node2D

var lifetime := 0.3

func _process(delta):
	lifetime -= delta
	scale += Vector2.ONE * delta * 4
	modulate.a = lifetime / 0.3
	
	if lifetime <= 0:
		queue_free()
