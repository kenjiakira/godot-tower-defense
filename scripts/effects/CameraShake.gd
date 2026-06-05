extends Camera2D

var shake_strength := 0.0

func _ready():
	add_to_group("main_camera")

func shake(amount := 8.0):
	shake_strength = amount

func _process(delta):
	if shake_strength > 0:
		offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)

		shake_strength = lerp(shake_strength, 0.0, delta * 12.0)

		if shake_strength < 0.5:
			shake_strength = 0
			offset = Vector2.ZERO
