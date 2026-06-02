extends PathFollow2D

@export var speed := 100.0
@export var max_hp := 100
@export var reward := 10
@export var enemy_color := Color.RED
@export var enemy_name := "Normal"

var hp := 100

signal reached_base
signal died(reward)

func _ready():
	progress = 0
	hp = max_hp
	
	if has_node("Body"):
		$Body.color = enemy_color

func _process(delta):
	progress += speed * delta
	
	if progress_ratio >= 1.0:
		reached_base.emit()
		queue_free()

func take_damage(damage):
	hp -= damage
	print(enemy_name, " HP:", hp)
	
	if hp <= 0:
		died.emit(reward)
		queue_free()
