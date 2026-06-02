extends Area2D

var occupied := false

func set_occupied():
	occupied = true
	visible = false
	$CollisionShape2D.disabled = true
