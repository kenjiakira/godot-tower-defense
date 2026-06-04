extends PathFollow2D

@export var speed := 100.0
@export var max_hp := 100
@export var reward := 10
@export var enemy_color := Color.WHITE
@export var enemy_name := "Normal"

@export var floating_text_scene: PackedScene
@export var death_effect_scene: PackedScene

var hp := 100
var has_reached_base := false

signal reached_base
signal died(reward, pos)

func _ready():
	progress = 0
	hp = max_hp
	
	if has_node("Body"):
		$Body.modulate = enemy_color
		
	if has_node("HPBar"):
		$HPBar.max_value = max_hp
		$HPBar.value = hp

func _process(delta):
	if has_reached_base:
		return

	progress += speed * delta
	
	if progress_ratio >= 0.99:
		has_reached_base = true
		base_hit_effect()
		reached_base.emit()
		queue_free()

func base_hit_effect():
	var cam = get_tree().get_first_node_in_group("main_camera")
	if cam and cam.has_method("shake"):
		if enemy_name == "Boss":
			cam.shake(15)
		elif enemy_name == "Tank":
			cam.shake(10)
		else:
			cam.shake(6)

func take_damage(damage):
	hp -= damage
	
	if has_node("HPBar"):
		$HPBar.value = hp
	
	spawn_floating_text(damage)
	hit_flash()
	
	if hp <= 0:
		spawn_death_effect()
		died.emit(reward, global_position)
		queue_free()

func spawn_floating_text(damage):
	if floating_text_scene == null:
		return
	
	var text = floating_text_scene.instantiate()
	get_tree().current_scene.add_child(text)
	text.global_position = global_position + Vector2(-10, -35)
	text.setup_text("-" + str(damage), Color.WHITE)

func spawn_death_effect():
	if death_effect_scene == null:
		return
	
	var effect = death_effect_scene.instantiate()
	get_tree().current_scene.add_child(effect)
	effect.global_position = global_position

func hit_flash():
	if not has_node("Body"):
		return
	
	$Body.modulate = Color.WHITE
	await get_tree().create_timer(0.08).timeout
	
	if is_instance_valid(self) and has_node("Body"):
		$Body.modulate = enemy_color
