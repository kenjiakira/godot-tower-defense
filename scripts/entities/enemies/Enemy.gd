extends PathFollow2D

const EnemyHPBar = preload("res://scripts/ui/components/EnemyHPBar.gd")

@export var speed := 100.0
@export var max_hp := 100
@export var reward := 10
@export var enemy_color := Color.WHITE
@export var enemy_name := "Normal"

@export var floating_text_scene: PackedScene
@export var death_effect_scene: PackedScene
@export var hpbar_scene: PackedScene

var hp := 100
var has_reached_base := false
var is_dead := false
var hpbar = null

var original_speed := 100.0
var is_slowed := false
var slow_timer := 0.0
var slow_amount := 1.0

signal reached_base
signal died(reward, pos)


func _ready():
	rotates = false
	rotation = 0

	progress = 0
	hp = max_hp
	original_speed = speed

	if has_node("Body"):
		$Body.rotation = 0
		$Body.modulate = enemy_color

	setup_hpbar()


func setup_hpbar():
	if hpbar_scene == null:
		print(enemy_name, " chua gan hpbar_scene")
		return

	hpbar = EnemyHPBar.new()
	add_child(hpbar)

	hpbar.position = Vector2(0, 0)
	hpbar.rotation = 0
	hpbar.z_index = 100
	hpbar.initialize(max_hp)


func _process(delta):
	if has_reached_base or is_dead:
		return

	if is_slowed:
		slow_timer -= delta
		if slow_timer <= 0:
			is_slowed = false
			speed = original_speed
			if has_node("Body"):
				$Body.modulate = enemy_color

	progress += speed * delta

	if progress_ratio >= 0.99:
		has_reached_base = true
		base_hit_effect()
		reached_base.emit()
		queue_free()


func base_hit_effect():
	var shake_strength := 6.0
	if enemy_name == "Boss":
		shake_strength = 15.0
	elif enemy_name == "Tank":
		shake_strength = 10.0

	var effects_manager = get_tree().get_first_node_in_group("effects_manager")
	if effects_manager and effects_manager.has_method("play_camera_shake"):
		effects_manager.play_camera_shake(shake_strength)
		return

	var cam = get_tree().get_first_node_in_group("main_camera")
	if cam and cam.has_method("shake"):
		cam.shake(shake_strength)


func take_damage(damage):
	if is_dead or has_reached_base:
		return

	hp -= damage

	if hpbar != null and hpbar.has_method("set_hp"):
		hpbar.set_hp(max(hp, 0))

	spawn_floating_text(damage)

	if hp <= 0:
		die()
	else:
		hit_flash()


func die():
	if is_dead:
		return

	is_dead = true

	spawn_death_effect()
	died.emit(reward, global_position)
	queue_free()


func spawn_floating_text(damage):
	var effects_manager = get_tree().get_first_node_in_group("effects_manager")
	if effects_manager and effects_manager.has_method("show_damage_text"):
		effects_manager.show_damage_text(global_position, damage, Color.WHITE)
		return

	if floating_text_scene == null:
		return

	var text = floating_text_scene.instantiate()
	get_tree().current_scene.add_child(text)
	text.global_position = global_position + Vector2(-10, -35)
	text.setup_text("-" + str(damage), Color.WHITE)


func spawn_death_effect():
	var effects_manager = get_tree().get_first_node_in_group("effects_manager")
	if effects_manager and effects_manager.has_method("show_death_effect"):
		effects_manager.show_death_effect(global_position, enemy_color, enemy_name)
		return

	if death_effect_scene == null:
		return

	var effect = death_effect_scene.instantiate()
	get_tree().current_scene.add_child(effect)
	effect.global_position = global_position

	if effect.has_method("set_color"):
		effect.set_color(enemy_color)

	if effect.has_method("set_enemy_type"):
		effect.set_enemy_type(enemy_name)


func hit_flash():
	if not has_node("Body"):
		return

	$Body.modulate = Color.WHITE
	await get_tree().create_timer(0.08).timeout

	if is_instance_valid(self) and not is_dead and has_node("Body"):
		$Body.modulate = enemy_color


func apply_slow(amount: float, duration: float):
	if is_dead or has_reached_base:
		return

	if is_slowed:
		slow_timer = duration
		return

	is_slowed = true
	slow_timer = duration
	speed = original_speed * amount
	slow_amount = amount

	if has_node("Body"):
		$Body.modulate = Color.CYAN


func get_hp() -> int:
	return hp


func get_speed() -> float:
	return original_speed
