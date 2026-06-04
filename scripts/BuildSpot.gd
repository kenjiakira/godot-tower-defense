extends Area2D

var occupied := false
var tower = null


func set_occupied(new_tower):
	occupied = true
	tower = new_tower

	visible = false
	$CollisionShape2D.disabled = true


func clear_occupied():
	occupied = false
	tower = null

	visible = true
	$CollisionShape2D.disabled = false
